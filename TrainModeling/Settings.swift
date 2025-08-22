//
//  Settings.swift
//  TrainModeling
//
//  Created by Максим on 06.04.17.
//  Copyright © 2017 Максим. All rights reserved.
//

import Foundation

var routes_data: [[[String]]] =
    [
        [["Москва", "--", "10:00"],
         ["Зеленоград", "11:00", "--"]],
        
        [["Зеленоград", "--", "14:00"],
         ["Тверь", "17:00", "17:10"],
         ["Великий Новгород", "21:10", "--"]],
        
        [["Москва", "--", "11:00"],
         ["Тверь", "15:00", "15:10"],
         ["Санкт-Петербург", "20:10", "--"]],
        
        [["Москва", "--", "10:30"],
         ["Зеленоград", "11:30", "11:40"],
         ["Тверь", "14:40", "14:50"],
         ["Великий Новгород", "18:50", "19:00"],
         ["Санкт-Петербург", "20:00", "--"]]
    ]


//словарь - название станции : расстояние от начала линии
var stations_data: [String: Float] =
    [
        "Москва": 0,
        "Зеленоград": 70,
        "Тверь": 280,
        "Великий Новгород": 560,
        "Санкт-Петербург": 630
    ]

class Settings {
    
    private var routes: [[[String]]]
    private var stationsDict: [String: Float]
    private var stations: [[String]]?
    
    init() {
        self.routes = routes_data
        self.stationsDict = stations_data
    }
    
    public func getRoutes() -> [[[String]]] {
        return self.routes
    }
    
    public func getStations() -> [(String, Float)] {
        return sortList(dictToArray(self.stationsDict))
    }
    
    public func getStationsDict() -> [String: Float] {
        return self.stationsDict
    }
    
    //M
    public func getRoutesNumber() -> Int {
        return self.routes.count
    }
    
    //N
    public func getStationsNumber() -> Int {
        return self.stations!.count
    }
    
    private func dictToArray(_ dict: [String: Float]) -> [(String, Float)] {
        var arr: [(String, Float)] = []
        for t in dict {
            arr.append((t.key, t.value))
        }
        return arr
    }
    
    private func sortList(_ list: [(String, Float)]) -> [(String, Float)] {
        return list.sorted { (a, b) -> Bool in
            return a.1 < b.1
        }
    }

    
}

