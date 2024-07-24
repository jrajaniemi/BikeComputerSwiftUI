import Foundation
import CoreLocation

struct RoutePoint: Codable {
    let speed: Double
    let heading: Double
    let altitude: Double
    let longitude: Double
    let latitude: Double
    let timestamp: Date
    
    init(speed: Double, heading: Double, altitude: Double, longitude: Double, latitude: Double, timestamp: Date) {
        self.speed = Double(round(10 * speed) / 10) // Pyöristetään 1 desimaaliin
        self.heading = Double(round(100 * heading) / 100) // Pyöristetään 2 desimaaliin
        self.altitude = Double(round(10 * altitude) / 10) // Pyöristetään 1 desimaaliin
        self.longitude = Double(round(100000 * longitude) / 100000) // Pyöristetään 5 desimaaliin
        self.latitude = Double(round(100000 * latitude) / 100000) // Pyöristetään 5 desimaaliin
        self.timestamp = timestamp
    }
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
    @Published var odometer: Double
    @Published var routes: [Route] = []

    private var lastRoute: Route?
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard
    private let odometerKey = "odometer"
    
    init() {
        self.odometer = userDefaults.double(forKey: odometerKey)
        loadRoutes()
    }
    
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
        updateOdometer()
        currentRoute = nil
        loadRoutes()  // Reload routes after saving
    }
    
    func addRoutePoint(speed: Double, heading: Double, altitude: Double, longitude: Double, latitude: Double) {
        guard var route = currentRoute else { return }
        let newPoint = RoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude, timestamp: Date())
        
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
            return lastFive
        } else {
            return route.points
        }
    }

    func loadRoutes() {
        let directory = getDocumentsDirectory()
        do {
            let fileUrls = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            let jsonFiles = fileUrls.filter { $0.pathExtension == "json" }
            var loadedRoutes = [Route]()
            
            for fileUrl in jsonFiles {
                let data = try Data(contentsOf: fileUrl)
                let decoder = JSONDecoder()
                let route = try decoder.decode(Route.self, from: data)
                loadedRoutes.append(route)
            }
            
            DispatchQueue.main.async {
                self.routes = loadedRoutes
            }
        } catch {
            print("Failed to load routes: \(error.localizedDescription)")
        }
    }

    func deleteRoute(route: Route) {
        let url = getDocumentsDirectory().appendingPathComponent("\(route.id).json")
        do {
            try fileManager.removeItem(at: url)
            DispatchQueue.main.async {
                self.routes.removeAll { $0.id == route.id }
            }
        } catch {
            print("Failed to delete route: \(error.localizedDescription)")
        }
    }

    func saveCurrentRoute() {
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
    
    private func updateOdometer() {
        odometer += totalDistance
        userDefaults.set(odometer, forKey: odometerKey)
        totalDistance = 0;
        print("Odometer updated: \(odometer) meters")
    }
}
