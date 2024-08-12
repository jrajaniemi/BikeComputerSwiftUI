//
//  Enums.swift
//  BikeComputer
//
//  Created by Jussi Rajaniemi on 11.8.2024.
//

import Foundation
import HealthKit

enum TrackableWorkoutActivityType: UInt, Codable, CaseIterable {
    case walking = 52
    case running = 37
    case hiking = 24
    case cycling = 13
    case handCycling = 74
    case equestrianSports = 17
    case wheelchairWalkPace = 70
    case wheelchairRunPace = 71
    case swimming = 46
    case paddling = 31
    case rowing = 35
    case crossCountrySkiing = 60
    case sailing = 38
    case surfingSports = 45
    case snowboarding = 67
    case snowSports = 40
    case downhillSkiing = 61
    case golf = 21
    case hunting = 26
    case swimBikeRun = 82
    case other = 3000
    case motorcycling = 5000
    case flying = 5001
    
    var activityName: String {
        switch self {
        case .walking:
            return "Walking"
        case .running:
            return "Running"
        case .hiking:
            return "Hiking"
        case .cycling:
            return "Cycling"
        case .handCycling:
            return "Hand Cycling"
        case .equestrianSports:
            return "Equestrian Sports"
        case .wheelchairWalkPace:
            return "Wheelchair Walk Pace"
        case .wheelchairRunPace:
            return "Wheelchair Run Pace"
        case .swimming:
            return "Swimming"
        case .paddling:
            return "Paddling"
        case .rowing:
            return "Rowing"
        case .crossCountrySkiing:
            return "Cross Country Skiing"
        case .snowboarding:
            return "Snowboarding"
        case .snowSports:
            return "Snow Sports"
        case .sailing:
            return "Sailing"
        case .surfingSports:
            return "Surfing Sports"
        case .swimBikeRun:
            return "Triathlon"
        case .downhillSkiing:
            return "Downhill Skiing"
        case .golf:
            return "Golf"
        case .hunting:
            return "Hunting"
        case .other:
            return "Other"
        case .motorcycling:
            return "Motorcycling"
        case .flying:
            return "Flying"
        }
    }
    
    var hkWorkoutActivityType: HKWorkoutActivityType {
        return HKWorkoutActivityType(rawValue: self.rawValue) ?? .other
    }
}

enum SpeedClass {
    case stationary
    case walking
    case running
    case cycling
    case riding
    case flying
}

enum PowerSavingMode {
    case off
    case normal
    case max
}
