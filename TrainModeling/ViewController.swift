//
//  ViewController.swift
//  TrainModeling
//
//  Created by Максим on 24.02.17.
//  Copyright © 2017 Максим. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
                        UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var pickerRoutesView: UIPickerView!
    @IBOutlet weak var tableGeneralSchedule: UITableView!
    @IBOutlet weak var worldScrollView: UIScrollView!
    @IBOutlet weak var detailStationView: UIView!
    
    @IBOutlet weak var tableEvents: UITableView!
    @IBOutlet weak var tableDetailStation: UITableView!
    
    @IBOutlet weak var intervalLabel: UILabel!
    @IBOutlet weak var scaleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var restartButton: UIButton!
    
    
    @IBOutlet weak var scaleStepper: UIStepper!
    @IBOutlet weak var hoursStepper: UIStepper!
    @IBOutlet weak var minuetesStepper: UIStepper!
    @IBOutlet weak var intervalStepper: UIStepper!
    
    
    var worldView: UIView!
    var manager: Manager?
    var railroad: Railroad?
    var timer = Timer()
    let fps: Int = 100
    var k: Int = 0
    let offset: CGFloat = 120.0
    var koeff: CGFloat = 2
    var interval = 600


    //при каждом нажатии на play/pause состояние будет сохраняться в manager
    
    func pause() {
        manager?.setOnPause() //ставим на паузу
        playPauseButton.backgroundColor = UIColor.green
        playPauseButton.setTitle("Старт", for: .normal)
    }
    
    func play() {
        manager?.setOnPlay() //запускаем
        playPauseButton.backgroundColor = UIColor.red
        playPauseButton.setTitle("Пауза", for: .normal)
    }
    
    @IBAction func tapPlayPauseButton(_ sender: UIButton) {
        
        if (manager?.isOnPause())! { //если на паузе
            play()
            
        } else { //если в процессе
            pause()
        }
    }
    
    @IBAction func tapRestartButton(_ sender: UIButton) {
        
        pause()
        k = 0
        
        //удалим с линии активные поезда
        let activeTrains: [Train] = (manager?.getActiveTrains())!
        for train in activeTrains {
            train.removeTrainView()
        }
        
        let settings: Settings = Settings()
        manager = Manager(settings: settings)
        manager?.sortTrainsByStartTime()
        
        timeLabel.text = "Время: "  + (manager?.getWorldTime())!
        hoursStepper.value = 0
        minuetesStepper.value = 10
        updateStepLabel()
        
        tableGeneralSchedule.reloadData()
        tableEvents.reloadData()
    }
    
    
    //при каждом изменении шага моделирования будет отображаться новое значение в labelStep
    //и будет сохраняться это новое значение в manager
    func updateStepLabel() {
        let hours: Int = Int(hoursStepper.value)
        let minuetes: Int = Int(minuetesStepper.value)
        
        let timeAbs: Int = hours * 3600 + minuetes * 60
        let time24: String = Manager.convertTo24Time(time: timeAbs)
        
        manager?.setStepTime(time: timeAbs)
        stepLabel.text = "Шаг: " +  time24
    }
    
    func updateScaleLabel() {
        let currentKoeff: CGFloat = CGFloat(scaleStepper.value)
        scaleLabel.text = "Масштаб: " + String(describing: currentKoeff)
        koeff = currentKoeff
        
        let views = worldView.subviews
        for view in views {
            view.removeFromSuperview()
        }
        
        //перерисовываем все в новом масштабе
        drawTracks((manager?.getStations())!)
        drawStations((manager?.getStations())!)
        
        for train in (manager?.getActiveTrains())! {
            drawTrain(train)
        }
    }
    
    
    @IBAction func tapIntervalStepper(_ sender: UIStepper, forEvent event: UIEvent) {
        interval = Int(intervalStepper.value)
        intervalLabel.text = "Величина интервала поломки: " + Manager.convertTo24Time(time: interval)
    }
    
    @IBAction func tapHoursStepper(_ sender: UIStepper, forEvent event: UIEvent) {
        updateStepLabel()
    }
    
    @IBAction func tapMinuetesStepper(_ sender: UIStepper, forEvent event: UIEvent) {
        updateStepLabel()
    }
    
    @IBAction func tapScaleStepper(_ sender: UIStepper, forEvent event: UIEvent) {
        updateScaleLabel()
    }
    
    func drawTracks(_ stations: [RailwayStation]) {
        let startPos: CGFloat = CGFloat(stations[0].getLocation())
        let finalPos: CGFloat = CGFloat(stations[stations.count - 1].getLocation())
        let trackWidth: CGFloat = CGFloat(2) * koeff
        let yAxePosition = worldView.bounds.height / 2
        
        let trackView: UIView = UIView(frame: CGRect(x: startPos + offset,
                                                     y: yAxePosition - CGFloat(trackWidth / 2),
                                                     width: (finalPos - startPos) * koeff,
                                                     height: trackWidth))
        manager?.setTrackView(trackView: trackView)
        trackView.backgroundColor = UIColor.black
        worldView.addSubview(trackView)
    }
    
    //отрисовываем все активные и не стоящие на станциях поезда из массива активных поездов
    func drawTrain(_ train: Train) {
        
        let trainWidth: CGFloat = CGFloat(10) * koeff
        let trainHeight: CGFloat = CGFloat(5) * koeff
        let yAxePosition: CGFloat = worldView.bounds.height / CGFloat(2.0)
        
        let trainView: UIView = UIView(frame:
            CGRect(x: CGFloat(train.getLocation()) * koeff + offset - trainWidth / 2.0,
                   y: yAxePosition - trainHeight / 2.0,
                   width: trainWidth,
                   height: trainHeight))
        
        
        trainView.backgroundColor = UIColor.green
        
        let singleTap =
            UITapGestureRecognizer(target: self, action: #selector(self.handleTapTrain))
        trainView.addGestureRecognizer(singleTap)
        
        //навешиваем двойной тап для поломки поезда
        let doubleTap =
            UITapGestureRecognizer(target: self, action: #selector(self.handleTrainCrash))
        doubleTap.numberOfTapsRequired = 2
        trainView.addGestureRecognizer(doubleTap)
        
        
        singleTap.require(toFail: doubleTap)
        singleTap.delaysTouchesBegan = true
        doubleTap.delaysTouchesBegan = true

        
        //добавляем в параметры поезда его View чтобы можно было пото удалить с Superview
        train.setTrainView(trainView: trainView)
        
        worldView.addSubview(trainView)
    }
    
    
    func drawStations(_ stations: [RailwayStation]) {
        
        let stationRadius: CGFloat = CGFloat(10) * koeff
        
        for i in 0..<stations.count {
            
            let stationRect = CGRect(x: CGFloat(stations[i].getLocation()) * koeff + offset - stationRadius,
                                     y: worldView.bounds.height / 2 - stationRadius,
                                     width: stationRadius * 2,
                                     height: stationRadius * 2)
            
            let stationView = UIView(frame: stationRect)
            
            let circlePath = UIBezierPath(arcCenter:
                CGPoint(x: Int(stationRect.width / 2),
                        y: Int(stationRect.height) / 2),
                                          radius: stationRadius,
                                          startAngle: CGFloat(0),
                                          endAngle: CGFloat(M_PI * 2),
                                          clockwise: true)
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = circlePath.cgPath
            shapeLayer.fillColor = UIColor.blue.cgColor
            shapeLayer.strokeColor = UIColor.black.cgColor
            shapeLayer.lineWidth = CGFloat(2) * koeff
            
            stationView.layer.addSublayer(shapeLayer)
            stationView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTapStation)))
            
            stations[i].setStationView(stationView: stationView)
            worldView.addSubview(stationView)
            
            let label = UILabel(frame:
                CGRect(x: CGFloat(stations[i].getLocation()) * koeff + offset - stationRadius * 3,
                       y: worldView.bounds.height / 2 + stationRadius,
                       width: stationRadius * 6,
                       height: stationRadius * 2))
            
            label.font = UIFont(name: "System", size: koeff * 5)
            label.text = stations[i].getName()
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            worldView.addSubview(label)
        }
        
    }
    
    func updateTrains() {
        
        var trains: [Train] = (manager?.getTrains())!
        
        //смотрим на поезда в trains и если его время выезжать по маршруту то добавляем его в activeTrains, смотрим для поездов в activeTrains, не приехали ли они уже по назначению и если да, то удаляем из ассива, затем двигаем все поезда active trains
        
        let time: Int = (manager?.getTime())!
        //кол-во секунд проходящих за один фрейм
        let deltaTime : Int = (manager?.getStepTime())! / fps
        
        var indices: [Int] = []
        for (i, train) in trains.enumerated() {
            
            
            
            if train.getStartAbsoluteTime() <= time +  deltaTime {
                //print("Start train number = \(train.getId()) at time = \(Manager.convertTo24Time(time: time))")
                train.startMoving()
                manager?.insertActiveTrain(train: train)
                indices.append(i)
            }
        }
        
        // удаляем поезда которые добавили в массив activeTrains
        for index in indices.sorted(by: >) {
            trains.remove(at: index)
        }
        
        indices.removeAll()
        
        var activeTrains: [Train] = (manager?.getActiveTrains())!
        
        for (i, train) in activeTrains.enumerated() {
            if train.getEndLocation() <= train.getLocation() {
                indices.append(i)
                //print("Reached destination point \(train.getEndLocation()) at time = \(Manager.convertTo24Time(time: time)), train number = \(train.getId())")
                train.removeTrainView() //удаляем поезд с линии
            }
        }
        
        //удаляем поезда, которые достигли пунктов назначения
        for index in indices.sorted(by: >) {
            activeTrains.remove(at: index)
        }
        
        for train in activeTrains {
            //определеяем, подъезжает ли поезд к станции
            if let station = train.checkStation(stepTime: (manager?.getStepTime())!, fps: fps) {
                //print("Train \(train.getId()) is near station \(station.getName())")
                //останавливаем поезд
                train.stopMoving(stayingInterval: train.getStationTime(stationId: station.getId()))
            }
            
            //если поезд находится в движении а не стоит то перерисовываем не удаляя (сдвигаем)
            else if train.isTrainMoving() {
                //train.removeTrainView()
                train.move(stepTime: (manager?.getStepTime())!, fps: fps)

                if let view = train.getTrainView() {
                    view.center.x = CGFloat(train.getLocation()) * koeff + offset
                    train.setTrainView(trainView: view)
                } else {
                    drawTrain(train)
                }
            } else {
                train.staying(deltaTime: deltaTime)
            }
        }
        
        //обновляем массивы trains и activeTrains в railRoad через manager
        manager?.setActiveTrains(activeTrains: activeTrains)
        manager?.setTrains(trains: trains)
        
        //отрисовываем обновленные положения активных поездов
        //drawTrains(activeTrains)
    }
    
    //каждую секунду будем обновлять всё на шаг равный шагу моделирования
    func updateView() {
        if !(manager?.isOnPause())! {
            //каждую секунду будем обновлять время на Шаг
            if k % fps == 0 {
                timeLabel.text = "Время: "  + (manager?.getWorldTime())!
                //увеличиваем аболютное время на Шаг если не стоит Пауза
                //manager?.updateAbsoluteTimeOnStepTime()
                k = 0
            }
            k += 1
            //print("Current time = \(manager?.getTime())")

            manager?.updateAbsoluteTimeOnStepTime(withFps: fps)
            //двигаем все активные поезда, не стоящие на станциях
            updateTrains()

        }
    }
    
    func handleTrainCrash(recognizer: UITapGestureRecognizer) {
        if recognizer.view != nil {
            recognizer.view!.backgroundColor =
                recognizer.view!.backgroundColor == UIColor.green ? UIColor.yellow : UIColor.green
            
            
            for train in (manager?.getActiveTrains())! {
                if abs((CGFloat(train.getLocation()) * koeff + offset) - recognizer.view!.center.x) < 10.0 {
                    train.stopMoving(stayingInterval: interval)
                    train.updateRoute(on: interval)
                    manager?.updateGeneralShedule(with: train.getRoute(), trainId: train.getId())
                    manager?.setCurrentRouteNumber(number: train.getId())
                    
                    manager?.addHappendEvent(newEvent:
                        Event(trainId: train.getId(),
                              occuranceTime: (manager?.getTime())!,
                              interval: interval))
                    
                    tableEvents.reloadData()
                    tableGeneralSchedule.reloadData()
                }
            }
        } else {
            return
        }

    }
    
    
    func handleTapTrain(recognizer: UITapGestureRecognizer) {

        //print("train detail")
        if !(manager?.isTrainSelected())! {
            manager?.setOnTrainSelected()
            pause()
        } else {
            manager?.setOffTrainSelected()
            play()
        }
        if recognizer.view != nil {
            recognizer.view!.backgroundColor =
                recognizer.view!.backgroundColor == UIColor.green ? UIColor.red : UIColor.green
        } else {
            return
        }
    }

    
    func handleTapStation(recognizer: UITapGestureRecognizer) {
        if recognizer.view != nil {
            //print(recognizer.view!.center)
            let stations = (manager?.getStations())!
            var id = 0
            for station in stations {
                if Int(CGFloat(station.getLocation()) * koeff + offset) == Int(recognizer.view!.center.x) {
                    id = station.getId()
                }
            }
        } else {
            return
        }

        
        /*if detailStationView.isHidden == true {
            detailStationView.isHidden = false
        } else {
            detailStationView.isHidden = true
        }*/
        
    }
    
    func addBlurEffect(_ view: UIView, style: UIBlurEffectStyle) {
        
        view.backgroundColor = UIColor.clear
        
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        view.insertSubview(blurEffectView, at: 0)
    }
    
    
    func makeInitialSettings() {
        let settings: Settings = Settings()
        manager = Manager(settings: settings)
        manager?.sortTrainsByStartTime()
        for s in (manager?.getStations())! {
            s.printStation()
        }
        
        for t in (manager?.getTrains())! {
            t.printTrain()
        }
        
        timeLabel.text = "Время: "  + (manager?.getWorldTime())!
        
        intervalLabel.text = "Величина интервала поломки: " + Manager.convertTo24Time(time: interval)

        
        tableEvents.delegate = self
        tableEvents.dataSource = self
        tableEvents.tableFooterView = UIView()
        
        
        tableGeneralSchedule.delegate = self
        tableGeneralSchedule.dataSource = self
        tableGeneralSchedule.tableFooterView = UIView()
        
        //tableDetailStation.delegate = self
        //tableDetailStation.dataSource = self
        //tableDetailStation.tableFooterView = UIView()
        
        pickerRoutesView.delegate = self
        pickerRoutesView.dataSource = self
        
        playPauseButton.setTitle("Старт", for: .normal)
        restartButton.setTitle("Рестарт", for: .normal)
        restartButton.backgroundColor = UIColor.purple
        
        hoursStepper.minimumValue = 0
        hoursStepper.maximumValue = 6
        hoursStepper.stepValue = 1         //шаг один час
        hoursStepper.value = 0
        
        minuetesStepper.minimumValue = 0
        minuetesStepper.maximumValue = 60
        minuetesStepper.stepValue = 10    //шаг 10 минут
        minuetesStepper.value = 10
        
        scaleStepper.minimumValue = 1
        scaleStepper.maximumValue = 4
        scaleStepper.stepValue = 0.1
        scaleStepper.value = 2
        
        intervalStepper.minimumValue = 600
        intervalStepper.maximumValue = 6000
        intervalStepper.stepValue = 100
        intervalStepper.value = 600
        
        
        let _ = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(ViewController.updateView), userInfo: nil, repeats: true)
        
        let M: Int = 2
        let N: Int = 10
        
        worldView = UIView()
        worldView.frame = CGRect(x: CGFloat(0),
                                 y: CGFloat(0),
                                 width: CGFloat((N / 2)) * worldScrollView.bounds.width,
                                 height: worldScrollView.bounds.height)
        
        //worldView.addSubview(UIImageView(image: UIImage(named: "bg")))
        worldScrollView.addSubview(worldView)
        
        worldScrollView.contentSize = CGSize(width: worldView.bounds.width,
                                             height: worldView.bounds.height)
        
        worldScrollView.isPagingEnabled = false
        worldScrollView.contentOffset = CGPoint(x: 0, y: 0)
        
        //addBlurEffect(detailStationView, style: .light)
        //detailStationView.isHidden = true
        //detailStationView.backgroundColor = UIColor.white
        
        //отрисовываем начальные элементы
        drawTracks((manager?.getStations())!)
        drawStations((manager?.getStations())!)
        updateStepLabel()
        updateScaleLabel()
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeInitialSettings()
    }
    
    //MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableGeneralSchedule {
            return (manager?.getCurrentRoute().count)!
        } else if tableView == self.tableEvents {
            return (manager?.getHappendEvents().count)!
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.tableGeneralSchedule {
            let cell = tableGeneralSchedule.dequeueReusableCell(withIdentifier: "TableGeneralScheduleCell")!
                as! TableGeneralScheduleCell
            //print(indexPath.row)  //номер текущей строчки
            let item: [String] = (manager?.getCurrentRoute()[indexPath.row])!
            
            cell.stationName.text = item[0]
            
            cell.arrivalTime.text = item[1]
            cell.departureTime.text = item[2]
            if item[1] != "--" && item[2] != "--" {
                //подсчитываем время стоянки
                cell.stationTime.text = Manager.sub24Time(time1: item[2], time2: item[1])
            } else {
                //cell.stationTime.text = "--"
            }
            return cell

        }
        
        let cell = tableEvents.dequeueReusableCell(withIdentifier: "TableEventsCell")!
            as! TableEventsCell
        
        let item: Event = (manager?.getHappendEvents()[indexPath.row])!
        
        cell.trainId.text = "Train " + String(item.getTrainId())
        cell.occuranceTime.text = String(Manager.convertTo24Time(time: item.getOccuranceTime()))
        cell.interval.text = String(Manager.convertTo24Time(time: item.getInterval()))
        
        return cell
    }

    
    //MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //отображаем ту таблицу, которая выбрана в списке
        manager?.setCurrentRouteNumber(number: row)
        tableGeneralSchedule.reloadData()
    }
    
    
    //MARK: - UIPickerViewDataSource

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    ///количество строчек в каждом разделе
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return (manager?.getRoutesNumber())!
    }
    
    ///заголовок заданной строчки
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)-> String? {
        let route: [[String]] = (manager?.getRoutes()[row])!
        let routeTitle: String = route[0][0] + " - " + route[route.count - 1][0]
        return routeTitle
    }


}

