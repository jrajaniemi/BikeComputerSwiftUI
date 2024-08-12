import Combine
import CoreLocation
import Foundation
import HealthKit

class RouteManager: ObservableObject {
    @Published var currentRoute: Route?
    @Published var routeLength: Int = 0
    @Published var lastFive: [RoutePoint] = []
    // TotalDistance = meters
    // imperialTotalDistance = feets
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
        migrateOldRoutes()
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
        route.distance = totalDistance
        route.points.append(newPoint)
        currentRoute = route
        routeLength = currentRoute?.points.count ?? 0
        debugPring(msg: "distance now: \(String(describing: currentRoute?.distance)) m")
    }
    
    func getLastFivePoints() -> [RoutePoint] {
        guard let route = lastRoute else { return [] }
        let count = route.points.count
        if count >= 5 {
            let lastFive = Array(route.points[(count - 5) ... (count - 1)])
            return lastFive
        } else {
            return route.points
        }
    }

    func loadRoutes() {
        // showAllFilesAndFolders()

        let directory = getDocumentsDirectory()

        // debugPring(msg: "Loading routes from directory: \(directory)")

        do {
            let fileUrls = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            // debugPring(msg: "Found files: \(fileUrls)")
            
            let jsonFiles = fileUrls.filter { $0.pathExtension == "json" }
            // debugPring(msg: "Filtered JSON files: \(jsonFiles)")
            
            var loadedRoutes = [Route]()

            for fileUrl in jsonFiles {
                do {
                    let data = try Data(contentsOf: fileUrl)
                    // debugPring(msg: "Loaded data from \(fileUrl)")

                    var jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
    
                    // debugPring(msg: "Parsed JSON object: \(jsonObject ?? [:])")
                   
                    // Päivitetään JSON-objekti lisäämällä puuttuva id-kenttä RoutePoint-rakenteeseen
                    if var points = jsonObject?["points"] as? [[String: Any]] {
                        for i in 0 ..< points.count {
                            if points[i]["id"] == nil {
                                points[i]["id"] = UUID().uuidString
                            }
                        }
                        jsonObject?["points"] = points
                    }
                    
                    // Konvertoidaan päivitetty JSON-objekti takaisin Data-muotoon
                    let updatedData = try JSONSerialization.data(withJSONObject: jsonObject ?? [:], options: .prettyPrinted)
                    try updatedData.write(to: fileUrl)

#if DEBUG
                    // Tulostetaan tiedoston sisältö
                    if let jsonString = String(data: updatedData, encoding: .utf8) {
                        print("Updated file content for \(fileUrl.lastPathComponent):")
                        // print("\(String(jsonString))")
                        if let jsonData = jsonString.data(using: .utf8) {
                            do {
                                // Muutetaan Data-tyyppinen jsonObjectiksi (Dictionary)
                                if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                                    // Käytä jsonObject-muuttujaa täällä
                                    print("Distance: \(String(describing: jsonObject["distance"]))")
                                }
                            } catch {
                                print("Failed to convert JSON string to object: \(error.localizedDescription)")
                            }
                        }
                    }
#endif
                    let decoder = JSONDecoder()
                    let route = try decoder.decode(Route.self, from: updatedData)
                    loadedRoutes.append(route)
                    
                    // debugPring(msg: "Successfully decoded route: \(route.name)")
                } catch {
                    // debugPring(header: "Failed to decode route from \(fileUrl):", msg: error.localizedDescription)
                }
            }
            
            DispatchQueue.main.async {
                self.routes = loadedRoutes
                
                // print("Routes successfully loaded: \(self.routes)")
                // debugPring(msg: String(self.routes.count))
            }
        } catch {
            // debugPring(header: "Failed to load routes: ", msg: error.localizedDescription)
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
            debugPring(header: "Failed to delete route: ", msg: error.localizedDescription)
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
            debugPring(header: "Route saved to: ", msg: url.path)
        } catch {
            debugPring(header: "Failed to save route: ", msg: error.localizedDescription)
        }
    }
    
    // Uusi updateRoute-funktio
    func updateRoute(_ updatedRoute: Route) {
        if let index = routes.firstIndex(where: { $0.id == updatedRoute.id }) {
            routes[index] = updatedRoute
            saveRouteToFile(routes[index])
        }
    }

    private func saveRouteToFile(_ route: Route) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(route)
            let url = getDocumentsDirectory().appendingPathComponent("\(route.id).json")
            try data.write(to: url)
            debugPring(msg: "Route saved to: \(url.path)")
        } catch {
            debugPring(msg: "Failed to save route: \(error.localizedDescription)")
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
        
        debugPring(msg: "Odometer updated: \(odometer) meters")
    }
    
    func showAllFilesAndFolders() {
        let directory = getDocumentsDirectory()
        do {
            let fileUrls = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            debugPring(msg: "Files and folders in directory: \(directory.path)")
            for fileUrl in fileUrls {
                debugPring(msg: fileUrl.lastPathComponent)
            }
        } catch {
            debugPring(msg: "Failed to list files and folders: \(error.localizedDescription)")
        }
    }
    
    func migrateOldRoutes() {
        let directory = getDocumentsDirectory()
        
        do {
            let fileUrls = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            let jsonFiles = fileUrls.filter { $0.pathExtension == "json" }
            
            for fileUrl in jsonFiles {
                do {
                    let data = try Data(contentsOf: fileUrl)
                    if var jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        // Tarkistetaan activityType ja alustetaan se tarvittaessa ActivityType-oliolla
                        if let activityTypeValue = jsonObject["activityType"] as? Int {
                            jsonObject["activityType"] = [
                                "id": UUID().uuidString,
                                "activity": TrackableWorkoutActivityType(rawValue: UInt(activityTypeValue))?.rawValue ?? TrackableWorkoutActivityType.other.rawValue
                            ]
                        } else if let activityTypeValue = jsonObject["activityType"] as? Double, activityTypeValue == 0.0 {
                            jsonObject["activityType"] = [
                                "id": UUID().uuidString,
                                "activity": TrackableWorkoutActivityType.other.rawValue
                            ]
                        } else if let activityTypeValue = jsonObject["activityType"] as? String, activityTypeValue.isEmpty {
                            jsonObject["activityType"] = [
                                "id": UUID().uuidString,
                                "activity": TrackableWorkoutActivityType.other.rawValue
                            ]
                        }
                        
                        // Konvertoidaan päivitetty JSON-objekti takaisin Data-muotoon
                        let updatedData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                        try updatedData.write(to: fileUrl)
                        
                        debugPring(msg:"Migrated file: \(fileUrl.lastPathComponent)")
                    }
                } catch {
                    debugPring(msg:"Failed to migrate file \(fileUrl.lastPathComponent): \(error.localizedDescription)")
                }
            }
        } catch {
            debugPring(msg:"Failed to read directory contents: \(error.localizedDescription)")
        }
    }
}
