import Combine
import CoreLocation
import CoreMotion
import Foundation
import SwiftUI

// LocationManager to handle GPS updates
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    let motionManager = CMMotionManager()
    let routeManager = RouteManager()
    
    private var lastUpdate: Date = .init()
    private var lastSpeedUpdate: Date = Date()
    private var headingLastUpdate: Date = .init()
    private var lastHeading: Double = -1
    private var cancellables = Set<AnyCancellable>()
    private let updateInterval: TimeInterval = 10 // Päivitys 1 kertaa sekunnissa
    private let zeroSpeed = 0.1111      // 0.1111 m/s = 0.4 km/h
    
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
    
    enum PowerSavingMode {
        case off
        case normal
        case max
    }

    var isTracking: Bool = false

    // Published properties to update UI
    @Published var speed: Double = 0.0 {
        didSet { imperialSpeed = speed / 1.6093 }
    }
    @Published var imperialSpeed: Double = 0.0
    @Published var heading: Double = 0.0
    @Published var altitude: Double = 0.0 {
        didSet { imperialAltitude = altitude * 3.2808 }
    }
    @Published var imperialAltitude: Double = 0.0
        
    @Published var accuracyDescription: String = "Unknown"
    @Published var longitude: Double = 0.0
    @Published var latitude: Double = 0.0
    @Published var powerSavingMode: PowerSavingMode = .off
    
    @AppStorage("batteryThreshold") private var batteryThreshold: Double = 100.0

    private var speedUpdateTimer: Timer?

    override init() {
        super.init()
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        
        manager.headingFilter = CLLocationDegrees(HF)
        manager.distanceFilter = CLLocationDistance(DF)
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        manager.allowsBackgroundLocationUpdates = true
        
        BatteryManager.shared.$batteryLevel
            .combineLatest(BatteryManager.shared.$isCharging)
            .sink { [weak self] batteryLevel, isCharging in
                self?.updateFilters(batteryLevel: batteryLevel, isCharging: isCharging)
            }
            .store(in: &cancellables)
        
        $speed
            .sink { [weak self] newSpeed in
                self?.checkSpeedClassChange(newSpeed)
            }
            .store(in: &cancellables)
        
        startSpeedUpdateTimer()
    }

    deinit {
        speedUpdateTimer?.invalidate()
    }
    
    private func startSpeedUpdateTimer() {
        speedUpdateTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true) { [weak self] _ in
            self?.updateSpeed()
        }
    }
    
    private func updateSpeed() {
        guard let location = manager.location else { return }
        speed = (speed < zeroSpeed) ? 0 : speed * 3.6   // 0.111 * 3.6 = 0.4 km/h
        altitude = location.altitude
#if DEBUG
        print("\(Date()) Timer update: \(speed) : \(altitude)")
#endif
    }

    private func checkSpeedClassChange(_ newSpeed: Double) {
        let newSpeedClass: SpeedClass
        
        switch newSpeed {
        case 1..<6:
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
            distanceFilter = 0
            headingFilter = 3
            desiredAccuracy = kCLLocationAccuracyBestForNavigation
            powerSavingMode = .off
        } else {
            powerSavingMode = .normal
            desiredAccuracy = kCLLocationAccuracyBest
            switch currentSpeedClass {
            case .walking:
                distanceFilter = 0
                headingFilter = 10
            case .running:
                distanceFilter = 1
                headingFilter = 8
            case .cycling:
                distanceFilter = 10
                headingFilter = 6
            case .riding:
                distanceFilter = 30
                headingFilter = 4
                desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            case .flying:
                distanceFilter = 2500
                headingFilter = 2
                desiredAccuracy = kCLLocationAccuracyHundredMeters
            case .stationary:
                distanceFilter = 0
                headingFilter = 5
            }

            if batteryLevel < 0.25 {
                powerSavingMode = .max
                distanceFilter *= 1.5
                headingFilter *= 1.5
                desiredAccuracy = kCLLocationAccuracyHundredMeters
                if(speed < 400) {
                    pausesLocationUpdatesAutomatically = true
                }
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
    
    func startLocationUpdates() {
        DispatchQueue.global().async { [weak self] in
            self?.manager.startUpdatingLocation()
            self?.manager.startUpdatingHeading()
        }
    }
    
    func stopLocationUpdates() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
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
        
        speed = (speed < zeroSpeed) ? 0 : speed * 3.6   // 0.111 * 3.6 = 0.4 km/h
        
        if shouldUpdateLocation(timeInterval: timeInterval, speed: location.speed) {
            lastUpdate = now
            speed = (speed < zeroSpeed) ? 0 : speed * 3.6   // 0.111 * 3.6 = 0.4 km/h
            altitude = location.altitude
            longitude = location.coordinate.longitude
            latitude = location.coordinate.latitude
            accuracyDescription = getAccuracyDescription(horizontalAccuracy: location.horizontalAccuracy)
            routeManager.addRoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude)
            addRoutePoint()
#if DEBUG
            print("\(Date()) Location updated: \(speed):\(currentSpeedClass) -  \(latitude), \(longitude) = \(altitude)")
#endif
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let currentTime = Date()
        let timeSince = abs(currentTime.timeIntervalSince(headingLastUpdate))
        
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
            print("\(Date()) Heading updated: \(heading) \(roundedNewHeading) - \(roundedLastHeading) = \(headingChange)")
#endif
            
            if let location = manager.location {
                speed = (speed < zeroSpeed) ? 0 : speed * 3.6   // 0.111 * 3.6 = 0.4 km/h

                altitude = location.altitude
                longitude = location.coordinate.longitude
                latitude = location.coordinate.latitude
                accuracyDescription = getAccuracyDescription(horizontalAccuracy: location.horizontalAccuracy)
                addRoutePoint()
            }
        }
    }
    
    func addRoutePoint() {
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
        if abs(timeInterval) > 30 || (abs(timeInterval) > 10 && speed < 30 / 3.6) {
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
        case 20...100:
            return "Low"
        default:
            return "Very Low"
        }
    }
}
