//
//  Railway.swift
//  TrainModeling
//
//  Created by Максим on 10.03.17.
//  Copyright © 2017 Максим. All rights reserved.
//

import Foundation
import UIKit

class Railroad {
    
    private var stations: [RailwayStation]
    
    private var trains: [Train]
    
    private var activeTrains: [Train] = [] //поезда, находящиеся на линии в данный момент
    
    private var trackView: UIView?
    
    
    init(stations: [RailwayStation], trains: [Train]) {
        self.stations = stations
        self.trains = trains
    }
    
    //MARK: - Getters
    
    public func getTrains() -> [Train] {
        return self.trains
    }
    
    public func getActiveTrains() -> [Train] {
        return self.activeTrains
    }
    
    public func getStations() -> [RailwayStation] {
        return self.stations
    }
    
    public func getTrackView() -> UIView {
        return self.trackView!
    }
    
    
    //MARK: - Setters
    
    public func setTrains(trains: [Train]) {
        self.trains = trains
    }
    
    public func setActiveTrains(activeTrains: [Train]) {
        self.activeTrains = activeTrains
    }
    
    public func setTrackView(trackView: UIView) {
        self.trackView = trackView
    }
    
    
    //MARK: - Other
    
    public func sortTrainsByStartTime() {
        trains = trains.sorted { (t1, t2) -> Bool in
            return t1.getStartAbsoluteTime() < t2.getStartAbsoluteTime()
        }
    }
    
    public func insertActiveTrain(train: Train) {
        if self.activeTrains.count == 0 {
            activeTrains.append(train)
            return
        }
        for i in 0..<self.activeTrains.count {
            if i == self.activeTrains.count - 1 {
                self.activeTrains.insert(train, at: i + 1)
            }
            else if self.activeTrains[i].getLocation() < train.getLocation() &&
                train.getLocation() < self.activeTrains[i + 1].getLocation() {

                self.activeTrains.insert(train, at: i + 1)
                break
            }
        }
    }
    
}
