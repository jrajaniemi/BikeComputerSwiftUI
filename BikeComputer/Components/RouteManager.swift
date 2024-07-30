import CoreLocation
import Foundation
import Combine

struct RoutePoint: Codable, Identifiable {
    var id = UUID() // Lisää identifioiva ominaisuus
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
    // TotalDistance = meters
    //imperialTotalDistance = feets
    @Published var totalDistance: Double = 0.0 {
        didSet { imperialTotalDistance = totalDistance * 3.2808 }
    }
    @Published var imperialTotalDistance: Double = 0.0
    
    // odometer = meters
    // imperialOdometer = feets
    @Published var odometer: Double = 0.0 {
        didSet { imperialOdometer = odometer * 3.2808 }
    }
    @Published var imperialOdometer: Double = 0.0
    
    @Published var routes: [Route] = []
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
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
        guard let route = currentRoute, !route.points.isEmpty else {
            alertMessage = "No points in current route to end."
            showingAlert = true
            currentRoute = nil
            return
        }
        currentRoute?.endDate = Date()
        saveCurrentRoute()
        lastRoute = currentRoute
        updateOdometer()
        currentRoute = nil
        loadRoutes() // Reload routes after saving
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
            let lastFive = Array(route.points[(count-5) ... (count-1)])
            return lastFive
        } else {
            return route.points
        }
    }

    func loadRoutes() {
        // showAllFilesAndFolders()
        let directory = getDocumentsDirectory()
#if DEBUG
        // print("Loading routes from directory: \(directory)")
#endif
        do {
            let fileUrls = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
#if DEBUG
            // print("Found files: \(fileUrls)")
#endif
            let jsonFiles = fileUrls.filter { $0.pathExtension == "json" }
#if DEBUG
            // print("Filtered JSON files: \(jsonFiles)")
#endif
            var loadedRoutes = [Route]()

            
            for fileUrl in jsonFiles {
                do {
                    let data = try Data(contentsOf: fileUrl)
#if DEBUG
                    // print("Loaded data from \(fileUrl)")
#endif
                    var jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
#if DEBUG
                    // print("Parsed JSON object: \(jsonObject ?? [:])")
#endif
                    // Päivitetään JSON-objekti lisäämällä puuttuva id-kenttä RoutePoint-rakenteeseen
                    if var points = jsonObject?["points"] as? [[String: Any]] {
                        for i in 0 ..< points.count {
                            points[i]["id"] = UUID().uuidString
                        }
                        jsonObject?["points"] = points
                    }
                    
                    // Konvertoidaan päivitetty JSON-objekti takaisin Data-muotoon
                    let updatedData = try JSONSerialization.data(withJSONObject: jsonObject ?? [:], options: .prettyPrinted)
#if DEBUG
                    // print("Updated JSON data: \(String(data: updatedData, encoding: .utf8) ?? "")")
#endif
                    let decoder = JSONDecoder()
                    let route = try decoder.decode(Route.self, from: updatedData)
                    loadedRoutes.append(route)
#if DEBUG
                    // print("Successfully decoded route: \(route.name)")
#endif
                } catch {
#if DEBUG
                    print("Failed to decode route from \(fileUrl): \(error.localizedDescription)")
#endif
                }
            }
            
            DispatchQueue.main.async {
                self.routes = loadedRoutes
#if DEBUG
                // print("Routes successfully loaded: \(self.routes)")
                print(self.routes.count)
#endif
            }
        } catch {
#if DEBUG
            print("Failed to load routes: \(error.localizedDescription)")
#endif
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
#if DEBUG
            print("Failed to delete route: \(error.localizedDescription)")
#endif
        }
    }

    func saveCurrentRoute() {
        guard let route = currentRoute, !route.points.isEmpty else {
            alertMessage = "No points in current route to save."
            showingAlert = true
            return
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(route)
            let url = getDocumentsDirectory().appendingPathComponent("\(route.id).json")
            try data.write(to: url)
#if DEBUG
            print("Route saved to: \(url.path)")
#endif
        } catch {
#if DEBUG
            print("Failed to save route: \(error.localizedDescription)")
#endif
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
        totalDistance = 0
#if DEBUG
        print("Odometer updated: \(odometer) meters")
#endif
    }
    
    func showAllFilesAndFolders() {
        let directory = getDocumentsDirectory()
        do {
            let fileUrls = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
#if DEBUG
            print("Files and folders in directory: \(directory.path)")
#endif
            for fileUrl in fileUrls {
                print(fileUrl.lastPathComponent)
            }
        } catch {
#if DEBUG
            print("Failed to list files and folders: \(error.localizedDescription)")
#endif
        }
    }
}
