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
    private var lastSpeedUpdate: Date = .init()
    private var headingLastUpdate: Date = .init()
    private var lastHeading: Double = -1
    private var cancellables = Set<AnyCancellable>()
    private let updateInterval: TimeInterval = 1 // Päivitys n kertaa sekunnissa
    private var updateSpeedTime: Double = 4.0 // Päivitys n sekunnin välein
    private var updateSpeedoMeterTime: Double = 4.0 // Päivitys n sekunnin välein
    
    var HF = 3
    var DF = 1
    var currentSpeedClass: SpeedClass = .stationary

    var isTracking: Bool = false

    // Published properties to update UI
    @Published var speed: Double = 0.0 {
        didSet {
            imperialSpeed = speed / 1.6093
        }
    }

    @Published var imperialSpeed: Double = 0.0
    @Published var heading: Double = 0.0
    @Published var altitude: Double = 0.0 {
        didSet { imperialAltitude = altitude * 3.2808 }
    }

    @Published var imperialAltitude: Double = 0.0
    @Published var accuracyDescription: String = .init(localized: "Unknown", comment: "When accuracy is unkown")
    @Published var longitude: Double = 0.0
    @Published var latitude: Double = 0.0
    @Published var powerSavingMode: PowerSavingMode = .off
    @Published var currentUserLocation: CLLocationCoordinate2D?
    @Published var totalAcceleration: Double = 0.0
    
    @AppStorage("batteryThreshold") private var batteryThreshold: Double = 100.0

    private var speedUpdateTimer: Timer?
    private var previousAcceleration: Double = 0.0
    private var previousTimestamp: Date?
    private var accelerationHistory: [Double] = []

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
        speedUpdateTimer = Timer.scheduledTimer(withTimeInterval: updateSpeedoMeterTime, repeats: true) { [weak self] _ in
            self?.updateSpeed()
        }
    }
    
    private func updateSpeed() {
        guard let location = manager.location else { return }
        // speed = (speed < zeroSpeed) ? 0 : speed * 3.6   // 0.111 * 3.6 = 0.4 km/h
        speed = max(location.speed, 0) * 3.6
        altitude = location.altitude
        debugPrint(msg: "\(Date()) Timer update: \(speed) : \(altitude)")
    }

    private func startMotionManager() {
        if motionManager.isAccelerometerAvailable, motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.5
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { [weak self] data, _ in
                guard let weakSelf = self else { return }
                if let motion = data {
                    // Lasketaan liike-kiihtyvyys käyttämällä userAcceleration, joka on jo painovoimasta puhdistettu
                    let userAcceleration = motion.userAcceleration
                    let currentAcceleration = sqrt(userAcceleration.x * userAcceleration.x + userAcceleration.y * userAcceleration.y + userAcceleration.z * userAcceleration.z)
                    
                    weakSelf.accelerationHistory.append(currentAcceleration)
                    if weakSelf.accelerationHistory.count > 2 {
                        weakSelf.accelerationHistory.removeFirst()
                    }

                    let averageAcceleration = weakSelf.accelerationHistory.reduce(0, +) / Double(weakSelf.accelerationHistory.count)

                    weakSelf.totalAcceleration = averageAcceleration

                    if abs(averageAcceleration) > 2.0 {
                        weakSelf.updateSpeedoMeterTime = 0.4
                        debugPrint("Updated updateSpeedoMeterTime to: \(weakSelf.updateSpeedoMeterTime), \(self?.totalAcceleration ?? 0)")
                    } else if abs(averageAcceleration) > 1.5 {
                        weakSelf.updateSpeedoMeterTime = 0.8
                        debugPrint("Updated updateSpeedoMeterTime to: \(weakSelf.updateSpeedoMeterTime), \(self?.totalAcceleration ?? 0)")
                    } else if abs(averageAcceleration) > 1.0 {
                        weakSelf.updateSpeedoMeterTime = 1.0
                        debugPrint("Updated updateSpeedoMeterTime to: \(weakSelf.updateSpeedoMeterTime), \(self?.totalAcceleration ?? 0)")
                    } else if abs(averageAcceleration) > 0.5 {
                        weakSelf.updateSpeedoMeterTime = 1.2
                        debugPrint("Updated updateSpeedoMeterTime to: \(weakSelf.updateSpeedoMeterTime), \(self?.totalAcceleration ?? 0)")
                    } else {
                        weakSelf.updateSpeedoMeterTime = 4.0
                    }
                }
            }
        }
    }
    
    func stopMotionManager() {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
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
        debugPrint(msg: "updateFilters called with batteryLevel: \(batteryLevel), isCharging: \(isCharging), batteryThreshold: \(batteryThreshold)")
        
        var distanceFilter: CLLocationDistance
        var headingFilter: CLLocationDegrees
        var desiredAccuracy: CLLocationAccuracy
        var pausesLocationUpdatesAutomatically = false
        
        if isCharging || batteryLevel > Float(batteryThreshold / 100) {
            updateSpeedTime = 5.0
            distanceFilter = 0
            headingFilter = 3
            desiredAccuracy = kCLLocationAccuracyBestForNavigation
            powerSavingMode = .off
            startMotionManager()
        } else {
            stopMotionManager()
            totalAcceleration = 0.0
            powerSavingMode = .normal
            desiredAccuracy = kCLLocationAccuracyBest
            updateSpeedTime = 7.5
            switch currentSpeedClass {
            case .walking:
                distanceFilter = 0
                headingFilter = 20
            case .running:
                distanceFilter = 1
                headingFilter = 15
            case .cycling:
                distanceFilter = 10
                headingFilter = 10
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
                updateSpeedTime = 10
                powerSavingMode = .max
                distanceFilter *= 1.5
                headingFilter *= 1.5
                desiredAccuracy = kCLLocationAccuracyHundredMeters
                if speed < 400 {
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
        
        debugPrint(msg: "Updated filters based on speed: \(speed) km/h, battery level: \(batteryLevel), isCharging: \(isCharging)")
        debugPrint(msg: "Distance Filter: \(distanceFilter), Heading Filter: \(headingFilter)")
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
            debugPrint(msg: "Location services are enabled")
        case .denied, .restricted:
            debugPrint(msg: "Location services are denied or restricted")
        case .notDetermined:
            debugPrint(msg: "Location services are not determined")
            if CLLocationManager.locationServicesEnabled() {
                manager.requestAlwaysAuthorization()
            } else {
                debugPrint("Location services are not enabled on this device.")
            }
        @unknown default:
            debugPrint(msg: "Unknown authorization status")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            debugPrint(msg: "No locations available")
            return
        }
        
        currentUserLocation = location.coordinate
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastUpdate)
        
        // speed = (speed < zeroSpeed) ? 0 : speed * 3.6   // 0.111 * 3.6 = 0.4 km/h
        speed = max(location.speed, 0) * 3.6
        if shouldUpdateLocation(timeInterval: timeInterval, speed: location.speed) {
            lastUpdate = now
            // speed = (speed < zeroSpeed) ? 0 : speed * 3.6   // 0.111 * 3.6 = 0.4 km/h
            speed = max(location.speed, 0) * 3.6
            altitude = location.altitude
            longitude = location.coordinate.longitude
            latitude = location.coordinate.latitude
            accuracyDescription = getAccuracyDescription(horizontalAccuracy: location.horizontalAccuracy)
            // routeManager.addRoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude)
            addRoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude)
            debugPrint(msg: "\(Date()) Location updated: \(speed):\(currentSpeedClass) -  \(latitude), \(longitude) = \(altitude)")
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

            if let location = manager.location {
                // speed = (speed < zeroSpeed) ? 0 : speed * 3.6   // 0.111 * 3.6 = 0.4 km/h
                speed = max(location.speed, 0) * 3.6
                altitude = location.altitude
                longitude = location.coordinate.longitude
                latitude = location.coordinate.latitude
                accuracyDescription = getAccuracyDescription(horizontalAccuracy: location.horizontalAccuracy)
                addRoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude)
                debugPrint(msg: "\(Date()) Heading updated: \(heading) \(roundedNewHeading) - \(roundedLastHeading) = \(headingChange), \(HF)")
            }
        }
    }

    /*
     func addRoutePoint() {
         if isTracking == true && speed > 0.25 {
             debugPrint(msg: "Route point added: Speed: \(speed), Altitude: \(altitude), Heading: \(heading), Accuracy: \(accuracyDescription)")
             routeManager.addRoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude)
         }
     }
     */
    
    func addRoutePoint(speed: Double, heading: Double, altitude: Double, longitude: Double, latitude: Double) {
        guard isTracking, speed > 0.1, accuracyDescription != "Invalid", let route = routeManager.currentRoute else { return }
        debugPrint(msg: "addRoutePoint()")
        let newPoint = RoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude, timestamp: Date())
        debugPrint(msg: "addRoutePoint() / newPoint: \(newPoint)")
        if let lastPoint = route.points.last {
            debugPrint(msg: "addRoutePoint() / lastPoint found")
            let distance = calculateDistance(from: lastPoint, to: newPoint)
            debugPrint(msg: "addRoutePoint() / distance: \(distance)")
            
            var radius = 3.0
            if accuracyDescription == "High" {
                radius = 7.5
            } else if accuracyDescription == "Medium" {
                radius = 15
            } else if accuracyDescription == "Low" {
                radius = 70
            } else if accuracyDescription == "Very Low" {
                radius = 100
            }
            
            if distance > radius {
                routeManager.addRoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude)
            } else {
                return
            }
        } else {
            // Jos ei ole viimeistä pistettä, lisää uusi piste
            routeManager.addRoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude)
        }

        // debugPrint(msg: "addRoutePoint() / distance now: \(String(describing: ))")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
#if DEBUG
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                debugPrint(msg: "Location services denied by the user")
            case .locationUnknown:
                debugPrint(msg: "Location unknown")
            case .network:
                debugPrint(msg: "Network error")
            default:
                debugPrint(msg: "Location error: \(clError.code.rawValue)")
            }
        } else {
            debugPrint(msg: "Location error: \(error.localizedDescription)")
        }
#endif
    }

    private func shouldUpdateLocation(timeInterval: TimeInterval, speed: CLLocationSpeed) -> Bool {
        if abs(timeInterval) > (updateSpeedTime * 3) || (abs(timeInterval) > (updateSpeedTime * 2) && speed < 30 / 3.6) {
            return true
        }
        return false
    }
    
    private func getAccuracyDescription(horizontalAccuracy: CLLocationAccuracy) -> String {
        switch horizontalAccuracy {
        case _ where horizontalAccuracy < 0:
            return String(localized: "Invalid", comment: "Accuracy is invalid")
        case 0...5:
            return String(localized: "Very High", comment: "Accuracy is very high")
        case 5...10:
            return String(localized: "High", comment: "Accuracy is high")
        case 10...20:
            return String(localized: "Medium", comment: "Accuracy is medium")
        case 20...100:
            return String(localized: "Low", comment: "Accuracy is low")
        default:
            return String(localized: "Very Low", comment: "Accuracy is very low")
        }
    }
}
