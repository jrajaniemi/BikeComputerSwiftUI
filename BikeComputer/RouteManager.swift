//
//  RouteManager.swift
//  BikeComputer
//
//  Created by Jussi Rajaniemi on 22.7.2024.
//
import Foundation
import CoreLocation


struct RoutePoint: Codable {
    let speed: Double
    let heading: Double
    let altitude: Double
    let longitude: Double
    let latitude: Double
    let timestamp: Date
}

struct Route: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    let startDate: Date
    var endDate: Date?
    var points: [RoutePoint]
    
    init(name: String, description: String, startDate: Date, endDate: Date?, points: [RoutePoint]) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.points = points
    }
}

class RouteManager: ObservableObject {
    @Published var currentRoute: Route?
    @Published var routeLength: Int = 0
    @Published var lastFive: [RoutePoint] = []
    @Published var totalDistance: Double = 0.0

    private var lastRoute: Route?

    private let fileManager = FileManager.default
    
    func formattedDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH.mm"
        return formatter.string(from: date)
    }
    
    func startNewRoute(name: String, description: String) {
        var newName = ""
        if name == "Default Route" {
            newName = "Route " + formattedDateString(from: Date())
        } else {
            newName = name
        }
        let newRoute = Route(name: newName, description: description, startDate: Date(), endDate: nil, points: [])
        currentRoute = newRoute
    }
    
    func endCurrentRoute() {
        currentRoute?.endDate = Date()
        saveCurrentRoute()
        lastRoute = currentRoute
        currentRoute = nil
    }
    
    func addRoutePoint(speed: Double, heading: Double, altitude: Double, longitude: Double, latitude: Double) {
        guard var route = currentRoute else { return }
        let newPoint = RoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude, timestamp: Date())
        // print(newPoint)
        
        // Calculate distance from the last point to the new point
        if let lastPoint = route.points.last {
            let distance = calculateDistance(from: lastPoint, to: newPoint)
            totalDistance += distance
        }
        
        
        route.points.append(newPoint)
        currentRoute = route
        routeLength = currentRoute?.points.count ?? 0
    }
    
    func getLastFivePoints() -> [RoutePoint] {
        guard let route = lastRoute else { return [] }
        let count = route.points.count
        if count >= 5 {
            let lastFive = Array(route.points[(count-5)...(count-1)])
            print("Last five points: \(lastFive)")
            return lastFive
        } else {
            print("All points: \(route.points)")
            return route.points
        }
    }

    private func saveCurrentRoute() {
        guard let route = currentRoute else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(route)
            let url = getDocumentsDirectory().appendingPathComponent("\(route.id).json")
            try data.write(to: url)
            print("Route saved to: \(url.path)")

        } catch {
            print("Failed to save route: \(error.localizedDescription)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func calculateDistance(from start: RoutePoint, to end: RoutePoint) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation) // Distance in meters
    }
}
