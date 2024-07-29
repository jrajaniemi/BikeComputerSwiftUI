import Combine
import CoreLocation
import CoreMotion
import Foundation
import SwiftUI

// LocationManager to handle GPS updates
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager() // Muutettu `private` -> `internal`
    let motionManager = CMMotionManager()
    let routeManager = RouteManager()
    
    private var lastUpdate: Date = .init()
    private var lastSpeedUpdate: Date = Date()
    private var headingLastUpdate: Date = .init()
    private var lastHeading: Double = -1
    private var cancellables = Set<AnyCancellable>()
    private let updateInterval: TimeInterval = 1 // Päivitys 1 kertaa sekunnissa

    var HF = 3
    var DF = 1
    var currentSpeedClass: SpeedClass = .stationary

    enum SpeedClass {
        case stationary
        case walking
        case running
        case cycling
        case riding
        case flying
    }

    var isTracking: Bool = false

    // Published properties to update UI
    @Published var speed: Double = 0.0              // km/h
    @Published var imperialSpeed: Double = 0.0      // mph
    @Published var heading: Double = 0.0            // degree
    @Published var altitude: Double = 0.0           // meters
    @Published var imperialAltitude: Double = 0.0   // feet
    @Published var accuracyDescription: String = "Unknown"
    @Published var longitude: Double = 0.0
    @Published var latitude: Double = 0.0
    
    @AppStorage("batteryThreshold") private var batteryThreshold: Double = 100.0

    override init() {
        super.init()
        manager.delegate = self
        manager.requestAlwaysAuthorization() // Pyydetään lupaa käyttää sijaintia, kun sovellus on käytössä
        
        // Asetetaan heading-päivityksen kynnysarvoksi 5 astetta (default on 1 astetta)
        manager.headingFilter = CLLocationDegrees(HF)
       
        // Asetetaan distanceFilter esimerkiksi 50 metriin, jotta sijaintia päivitetään vain,
        // kun käyttäjä on liikkunut vähintään 50 metriä
        manager.distanceFilter = CLLocationDistance(DF)
       
        // Asetetaan sijaintipäivityksen tarkkuudeksi karkeampi taso
        manager.desiredAccuracy = kCLLocationAccuracyBest
        #if DEBUG
        print("desiredAccuracy \(manager.desiredAccuracy)")
        #endif
        
        manager.allowsBackgroundLocationUpdates = true
        
        
        stopLocationUpdates()
        
        // Observe battery changes
        BatteryManager.shared.$batteryLevel
            .combineLatest(BatteryManager.shared.$isCharging)
            .sink { [weak self] batteryLevel, isCharging in
                self?.updateFilters(batteryLevel: batteryLevel, isCharging: isCharging)
            }
            .store(in: &cancellables)
        
        // Observe speed changes
        $speed
            .sink { [weak self] newSpeed in
                self?.checkSpeedClassChange(newSpeed)
            }
            .store(in: &cancellables)
    }
    
    /*  Defaults
     *  Walking = 6 km/h = 1,67 m/s = 17 m per 10 sek
     *      DF = 17, HF = 25
     *  Cycling = 15 km/h = 4,17 m/s = 42 m per 10 sek
     *      DF = 42, HF = 10
     *  Riding car = 80 km/h = 22,2 m/s 222 m per 10 sek
     *      DF = 250, HF = 5
     *  Flying = 850 km/h = 236 m/s = 2,4 km per 10 sek
     *      DF, 2500, HF = 1
     */
    
    private func checkSpeedClassChange(_ newSpeed: Double) {
        let newSpeedClass: SpeedClass
        
        switch newSpeed {
        case 0.01..<6:
            newSpeedClass = .walking
        case 6..<14:
            newSpeedClass = .running
        case 14..<40:
            newSpeedClass = .cycling
        case 40..<180:
            newSpeedClass = .riding
        case 180...:
            newSpeedClass = .flying
        default:
            newSpeedClass = .stationary
        }
        
        if newSpeedClass != currentSpeedClass {
            currentSpeedClass = newSpeedClass
            updateFilters(batteryLevel: BatteryManager.shared.batteryLevel, isCharging: BatteryManager.shared.isCharging)
        }
    }
    
    private func updateFilters(batteryLevel: Float, isCharging: Bool) {
#if DEBUG
        print("updateFilters called with batteryLevel: \(batteryLevel), isCharging: \(isCharging), batteryThreshold: \(batteryThreshold)")
#endif
        
        var distanceFilter: CLLocationDistance
        var headingFilter: CLLocationDegrees
        var desiredAccuracy: CLLocationAccuracy
        var pausesLocationUpdatesAutomatically = false
        
        if isCharging || batteryLevel > Float(batteryThreshold / 100) {
            distanceFilter = 3
            headingFilter = 3
            desiredAccuracy = kCLLocationAccuracyBestForNavigation
        } else {
            desiredAccuracy = kCLLocationAccuracyBest
            pausesLocationUpdatesAutomatically = true
            switch currentSpeedClass {
            case .walking:
                distanceFilter = 17
                headingFilter = 25
            case .running:
                distanceFilter = 34
                headingFilter = 15
            case .cycling:
                distanceFilter = 60
                headingFilter = 6
            case .riding:
                distanceFilter = 200
                headingFilter = 4
                desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            case .flying:
                distanceFilter = 2500
                headingFilter = 2
                desiredAccuracy = kCLLocationAccuracyHundredMeters
                pausesLocationUpdatesAutomatically = false
            case .stationary:
                distanceFilter = 10
                headingFilter = 5
            }

            
            if batteryLevel < 0.25 {
                distanceFilter *= 1.5
                headingFilter *= 1.5
                desiredAccuracy = kCLLocationAccuracyHundredMeters
            }
        }
        
        HF = Int(headingFilter)
        DF = Int(distanceFilter)
        
        manager.distanceFilter = distanceFilter
        manager.headingFilter = headingFilter
        manager.desiredAccuracy = desiredAccuracy
        manager.pausesLocationUpdatesAutomatically = pausesLocationUpdatesAutomatically
#if DEBUG
        print("Updated filters based on speed: \(speed) km/h, battery level: \(batteryLevel), isCharging: \(isCharging)")
        print("Distance Filter: \(distanceFilter), Heading Filter: \(headingFilter)")
#endif
    }
    
    // Muut metodit pysyvät ennallaan
    func startLocationUpdates() {
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
        // print("Location and heading updates started")
    }
    
    func stopLocationUpdates() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        // print("Location and heading updates stopped")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
#if DEBUG
            print("Location services are denied or restricted")
#endif
        case .notDetermined:
#if DEBUG
            print("Location services are not determined")
#endif
        @unknown default:
#if DEBUG
            print("Unknown authorization status")
#endif
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
#if DEBUG
            print("No locations available")
#endif
            return
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastUpdate)
        let speedTimeInterval = now.timeIntervalSince(lastSpeedUpdate)
        
        if speedTimeInterval > 1 {
            speed = max(location.speed, 0) * 3.6 // Convert speed from m/s to km/h
            if(speed < 0.3) { speed = 0 }
            imperialSpeed = speed/1.6093
        }
        
        // print("timeInterval", timeInterval)
        if shouldUpdateLocation(timeInterval: timeInterval, speed: location.speed) {
            lastUpdate = now

            altitude = location.altitude
            longitude = location.coordinate.longitude
            latitude = location.coordinate.latitude
            accuracyDescription = getAccuracyDescription(horizontalAccuracy: location.horizontalAccuracy)
            routeManager.addRoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude)
            addRoutePoint()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let currentTime = Date()
        let timeSince = abs(currentTime.timeIntervalSince(headingLastUpdate))
        // print("timeSince \(timeSince)")
        if timeSince < updateInterval {
            return
        }
        
        let roundedNewHeading = round(newHeading.trueHeading * 100000) / 100000
        let roundedLastHeading = round(lastHeading * 100000) / 100000
        let headingChange = roundedNewHeading - roundedLastHeading

        if abs(headingChange) > Double(HF) {
            heading = roundedNewHeading
            lastHeading = roundedNewHeading
            headingLastUpdate = Date()
#if DEBUG
            print("Heading updated: \(heading) \(roundedNewHeading) - \(roundedLastHeading) = \(headingChange)")
#endif
            // Päivitetään myös sijainti, nopeus ja korkeus
            if let location = manager.location {
                speed = max(location.speed, 0) * 3.6 // Convert speed from m/s to km/h
                imperialSpeed = speed/1.6093
                altitude = location.altitude
                imperialAltitude = altitude * 3.2808
                longitude = location.coordinate.longitude
                latitude = location.coordinate.latitude
                accuracyDescription = getAccuracyDescription(horizontalAccuracy: location.horizontalAccuracy)
                addRoutePoint()
            }
        }
    }
    
    func addRoutePoint() {
        // print("LocationsUpdate: Speed: \(speed), Altitude: \(altitude), Heading: \(heading), Accuracy: \(accuracyDescription)")

        if isTracking == true && speed > 0 {
#if DEBUG
            print("Route point added: Speed: \(speed), Altitude: \(altitude), Heading: \(heading), Accuracy: \(accuracyDescription)")
#endif
            routeManager.addRoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
#if DEBUG
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Location services denied by the user")
            case .locationUnknown:
                print("Location unknown")
            case .network:
                print("Network error")
            default:
                print("Location error: \(clError.code.rawValue)")
            }
        } else {
            print("Location error: \(error.localizedDescription)")
        }
#endif
    }

    private func shouldUpdateLocation(timeInterval: TimeInterval, speed: CLLocationSpeed) -> Bool {
        if abs(timeInterval) > 15 || (abs(timeInterval) > 10 && speed < 20 / 3.6) { // speed < 20 km/h (5.56 m/s)
            return true
        }
        return false
    }
    
    private func getAccuracyDescription(horizontalAccuracy: CLLocationAccuracy) -> String {
        switch horizontalAccuracy {
        case _ where horizontalAccuracy < 0:
            return "Invalid"
        case 0...5:
            return "Very High"
        case 5...10:
            return "High"
        case 10...20:
            return "Medium"
        case 20...50:
            return "Low"
        default:
            return "Very Low"
        }
    }
}
