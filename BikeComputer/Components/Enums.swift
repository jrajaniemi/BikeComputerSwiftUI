//
//  Enums.swift
//  BikeComputer
//
//  Created by Jussi Rajaniemi on 11.8.2024.
//

import Foundation
import HealthKit

public enum TrackableWorkoutActivityType: UInt, Codable, CaseIterable, Identifiable {
    public var id: Self { self }
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
    case driving = 5001
    case flying = 5002
    case stationary = 10000

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
        case . driving:
            return "Driving"
        case .flying:
            return "Flying"
        case .stationary:
            return "Stationary"
        }
    }

    var hkWorkoutActivityType: HKWorkoutActivityType {
        return HKWorkoutActivityType(rawValue: self.rawValue) ?? HKWorkoutActivityType.other
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
