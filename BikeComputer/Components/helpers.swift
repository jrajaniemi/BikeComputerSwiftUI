//
//  helpers.swift
//  BikeComputer
//
//  Created by Jussi Rajaniemi on 2.8.2024.
//
import CoreLocation
import Foundation

func calculateTotalDistance(for route: Route) -> Double {
    var totalDistance = 0.0
    if route.points.count > 1 {
        for i in 1 ..< route.points.count {
            let previousPoint = route.points[i - 1]
            let currentPoint = route.points[i]
            totalDistance += calculateDistance(from: previousPoint, to: currentPoint)
        }
    }
    return totalDistance
}

func searchMaxSpeed(for route: Route) -> Double {
    var maxSpeed = 0.0
    if route.points.count > 1 {
        for i in 1 ..< route.points.count {
            if route.points[i].speed > maxSpeed {
                maxSpeed = route.points[i].speed
            }
        }
    }
    return maxSpeed 
}

func calculateDistance(from start: RoutePoint, to end: RoutePoint) -> Double {
    let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
    let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
    return startLocation.distance(from: endLocation)
}

func calculateAverageSpeed(for route: Route) -> Double {
    guard let endDate = route.endDate else { return 0.0 }
    let totalTime = endDate.timeIntervalSince(route.startDate)
    let totalDistance = calculateTotalDistance(for: route)
    return totalDistance / totalTime * 3.6 // Convert to km/h
}

func formattedElapsedTime(for route: Route) -> String {
    guard let endDate = route.endDate else { return "N/A" }
    let totalTime = endDate.timeIntervalSince(route.startDate)
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.string(from: totalTime) ?? "N/A"
}

func getSpeedClass(route: Route) -> TrackableWorkoutActivityType {
    let averageSpeed:Double = calculateAverageSpeed(for: route)
    let maxSpeed:Double = searchMaxSpeed(for: route)
    let speedTuple = (averageSpeed, maxSpeed)
    let newSpeedClass: TrackableWorkoutActivityType
    
    
    debugPrint(header: "getSpeedClass - ", msg: "avg: \(averageSpeed) max: \(maxSpeed)")
    
    switch speedTuple {
    case (1..<6, 1..<14):
        newSpeedClass = .walking
    case (6..<14, 6..<20):
        newSpeedClass = .running
    case (14..<40, 14..<40):
        newSpeedClass = .cycling
    case (1..<180, 40..<180):
        newSpeedClass = .motorcycling
    case (180..., _):
        newSpeedClass = .flying
    default:
        newSpeedClass = .other
    }
    return newSpeedClass
}


func debugPrint(msg: String) {
    #if DEBUG
        print(msg)
    #endif
}

func debugPrint(header: String, msg: String) {
    #if DEBUG
        print("\(header): \(msg)")
    #endif
}
