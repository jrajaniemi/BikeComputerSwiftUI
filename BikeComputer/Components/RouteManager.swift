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
        #if DEBUG
        // copyJsonToDocumentsAndRename()
        #endif
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
        
        currentRoute?.endDate = Date() // Ensure endDate is set

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
        debugPrint(msg: "RouteManager / distance now: \(String(describing: currentRoute?.distance)) m")
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
        showAllFilesAndFolders()

        let directory = getDocumentsDirectory()

        // debugPrint(msg: "Loading routes from directory: \(directory)")

        do {
            let fileUrls = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            // debugPrint(msg: "Found files: \(fileUrls)")
            
            let jsonFiles = fileUrls.filter { $0.pathExtension == "json" }
            // debugPrint(msg: "Filtered JSON files: \(jsonFiles)")
            
            var loadedRoutes = [Route]()

            for fileUrl in jsonFiles {
                do {
                    let data = try Data(contentsOf: fileUrl)
                    // debugPrint(msg: "Loaded data from \(fileUrl)")

                    var jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
    
                    // debugPrint(msg: "Parsed JSON object: \(jsonObject ?? [:])")
                   
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
                        // debugPrint(msg: "Updated file content for \(fileUrl.lastPathComponent):")
                        // print("\(String(jsonString))")
                        if let jsonData = jsonString.data(using: .utf8) {
                            do {
                                // Muutetaan Data-tyyppinen jsonObjectiksi (Dictionary)
                                if try JSONSerialization.jsonObject(with: jsonData, options: []) is [String: Any] {
                                    // Käytä jsonObject-muuttujaa täällä
                                    // debugPrint(msg: "Distance: \(String(describing: jsonObject["distance"]))")
                                }
                            } catch {
                                debugPrint(msg: "Failed to convert JSON string to object: \(error.localizedDescription)")
                            }
                        }
                    }
                    #endif
                    let decoder = JSONDecoder()
                    let route = try decoder.decode(Route.self, from: updatedData)
                    loadedRoutes.append(route)
                    
                    // debugPrint(msg: "Successfully decoded route: \(route.name)")
                } catch {
                    debugPrint(header: "Failed to decode route from \(fileUrl):", msg: error.localizedDescription)
                }
            }
            
            DispatchQueue.main.async {
                self.routes = loadedRoutes
                
                // debugPrint(msg:"Routes successfully loaded: \(self.routes)")
                // debugPrint(msg: String(self.routes.count))
            }
        } catch {
            debugPrint(header: "Failed to load routes: ", msg: error.localizedDescription)
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
            debugPrint(header: "Failed to delete route: ", msg: error.localizedDescription)
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
            // debugPrint(header: "Route saved to: ", msg: url.path)
        } catch {
            debugPrint(header: "Failed to save route: ", msg: error.localizedDescription)
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
            debugPrint(msg: "Route saved to: \(url.path)")
            debugPrint(msg: "ActivityType: \(route)")
        } catch {
            debugPrint(msg: "Failed to save route: \(error.localizedDescription)")
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
        
        // debugPrint(msg: "Odometer updated: \(odometer) meters")
    }
    
    func showAllFilesAndFolders() {
        let directory = getDocumentsDirectory()
        do {
            let fileUrls = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            debugPrint(msg: "Files and folders in directory: \(directory.path)")
            for fileUrl in fileUrls {
                debugPrint(msg: fileUrl.lastPathComponent)
            }
        } catch {
            debugPrint(msg: "Failed to list files and folders: \(error.localizedDescription)")
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
                        if let activityTypeValue = jsonObject["activityType"] as? Int, activityTypeValue == 0 {
                            jsonObject["activityType"] = TrackableWorkoutActivityType.other.rawValue
                        } else if let activityTypeValue = jsonObject["activityType"] as? Double, activityTypeValue == 0.0 {
                            jsonObject["activityType"] = TrackableWorkoutActivityType.other.rawValue
                        } else if let activityTypeValue = jsonObject["activityType"] as? String, activityTypeValue.isEmpty {
                            jsonObject["activityType"] = TrackableWorkoutActivityType.other.rawValue
                        }
                        
                        // Uusi migraatio: Poista ActivityType-kääre ja päivitä suoraan TrackableWorkoutActivityType-tyyppiin
                        if let activityTypeDict = jsonObject["activityType"] as? [String: Any],
                           let activityRawValue = activityTypeDict["activity"] as? UInt
                        {
                            jsonObject["activityType"] = activityRawValue
                        }
                        
                        // Konvertoidaan päivitetty JSON-objekti takaisin Data-muotoon
                        let updatedData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                        try updatedData.write(to: fileUrl)
                        
                        // debugPrint(msg: "Migrated file: \(fileUrl.lastPathComponent)")
                    }
                } catch {
                    debugPrint(msg: "Failed to migrate file \(fileUrl.lastPathComponent): \(error.localizedDescription)")
                }
            }
        } catch {
            debugPrint(msg: "Failed to read directory contents: \(error.localizedDescription)")
        }
    }
    
    func copyJsonToDocumentsAndRename() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Tarkistetaan ensin, onko tiedosto jo siirretty ja uudelleennimetty
        guard let bundleURL = Bundle.main.url(forResource: "route", withExtension: "json"),
              let data = try? Data(contentsOf: bundleURL),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = jsonObject["id"] as? String
        else {
            print("Failed to load route.json from bundle or parse its contents.")
            return
        }
        
        let newFilename = "\(UUID(uuidString: id)).json"
        let newDestinationURL = documentsDirectory.appendingPathComponent(newFilename)
        
        // Jos tiedosto on jo olemassa, ei tehdä mitään
        if fileManager.fileExists(atPath: newDestinationURL.path) {
            print("File already exists: \(newFilename). No action taken.")
            return
        }
        
        // Kopiointi ja uudelleennimeäminen
        let originalDestinationURL = documentsDirectory.appendingPathComponent("route.json")
        do {
            try fileManager.copyItem(at: bundleURL, to: originalDestinationURL)
            try fileManager.moveItem(at: originalDestinationURL, to: newDestinationURL)
            print("File successfully copied and renamed to \(newFilename)")
        } catch {
            print("Error during file operations: \(error)")
        }
    }
    
    func convertGPXToJSON(gpxFileUrl: URL, outputFileName: String) {
        // Ladataan GPX-tiedoston data
        guard let gpxData = try? Data(contentsOf: gpxFileUrl),
              let gpxString = String(data: gpxData, encoding: .utf8)
        else {
            debugPrint(msg: "Failed to read GPX file.")
            return
        }

        // Parsitaan GPX-tiedoston sisältö
        let parser = GPXParser(gpxString: gpxString)
        guard let routePoints = parser.parseGPX() else {
            debugPrint(msg: "Failed to parse GPX file.")
            return
        }

        // Luodaan uusi Route-objekti
        let newRoute = Route(
            name: outputFileName,
            description: "Converted from GPX",
            startDate: Date(),
            endDate: nil,
            points: routePoints
        )

        // Tallennetaan Route JSON-tiedostoon
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(newRoute)
            let outputUrl = getDocumentsDirectory().appendingPathComponent("\(outputFileName).json")
            try jsonData.write(to: outputUrl)
            debugPrint(msg: "GPX converted to JSON and saved to \(outputUrl.path)")
        } catch {
            debugPrint(msg: "Failed to save JSON file: \(error.localizedDescription)")
        }
    }
}


class GPXParser: NSObject, XMLParserDelegate {
    var gpxString: String
    var currentElement: String = ""
    var currentPoint: RoutePoint?
    var routePoints: [RoutePoint] = []
    
    init(gpxString: String) {
        self.gpxString = gpxString
    }
    
    func parseGPX() -> [RoutePoint]? {
        guard let data = gpxString.data(using: .utf8) else { return nil }
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        if parser.parse() {
            return routePoints
        } else {
            return nil
        }
    }
    
    // XMLParserDelegate-metodit
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        currentElement = elementName
        
        if currentElement == "trkpt" {
            if let latString = attributeDict["lat"], let lonString = attributeDict["lon"],
               let latitude = Double(latString), let longitude = Double(lonString) {
                currentPoint = RoutePoint(speed: 0.0, heading: 0.0, altitude: 0.0, longitude: longitude, latitude: latitude, timestamp: Date())
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "trkpt", let point = currentPoint {
            routePoints.append(point)
        }
    }
}
