//
//  helpers.swift
//  BikeComputer
//
//  Created by Jussi Rajaniemi on 2.8.2024.
//
import Foundation
import CoreLocation

func calculateTotalDistance(for route: Route) -> Double {
    var totalDistance = 0.0
    if route.points.count > 1 {
        for i in 1..<route.points.count {
            let previousPoint = route.points[i - 1]
            let currentPoint = route.points[i]
            totalDistance += calculateDistance(from: previousPoint, to: currentPoint)
        }
    }
    return totalDistance
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
