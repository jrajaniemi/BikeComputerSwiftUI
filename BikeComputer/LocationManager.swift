import Foundation
import CoreLocation
import CoreMotion

// LocationManager to handle GPS updates
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager() // Muutettu `private` -> `internal`
    let motionManager = CMMotionManager()
    let routeManager = RouteManager()

    let HEADING_FILTER = 10
    let DISTANCE_FILTER = 20
    
    private var lastUpdate: Date?
    private var lastHeading: Double = -1
    var isTracking: Bool = false

    // Published properties to update UI
    @Published var speed: Double = 0.0
    @Published var heading: Double = 0.0
    @Published var altitude: Double = 0.0
    @Published var accuracyDescription: String = "Unknown"
    @Published var longitude: Double = 0.0
    @Published var latitude: Double = 0.0
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestAlwaysAuthorization() // Pyydetään lupaa käyttää sijaintia, kun sovellus on käytössä
        
        // Asetetaan heading-päivityksen kynnysarvoksi 5 astetta (default on 1 astetta)
        manager.headingFilter = CLLocationDegrees(self.HEADING_FILTER)
       
        // Asetetaan sijaintipäivityksen tarkkuudeksi karkeampi taso
        manager.desiredAccuracy = kCLLocationAccuracyBest
       
        // Asetetaan distanceFilter esimerkiksi 50 metriin, jotta sijaintia päivitetään vain,
        // kun käyttäjä on liikkunut vähintään 50 metriä
        manager.distanceFilter = CLLocationDistance(self.DISTANCE_FILTER)
        
        self.stopLocationUpdates()
    }
    
    // Käynnistetään sijainti- ja suunnan päivitykset
    func startLocationUpdates() {
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
        print("Location and heading updates started")
    }
    
    func stopLocationUpdates() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        print("Location and heading updates stopped")
    }
    
    // CLLocationManagerDelegate method to handle authorization status changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            print("Location services are denied or restricted")
        case .notDetermined:
            print("Location services are not determined")
        @unknown default:
            print("Unknown authorization status")
        }
    }
    
    // CLLocationManagerDelegate method to handle location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("No locations available")
            return
        }
        
        let now = Date()
        let timeInterval = lastUpdate?.timeIntervalSince(now) ?? 0
        // print("timeInterval", timeInterval)
        if shouldUpdateLocation(timeInterval: timeInterval, speed: location.speed) {
            lastUpdate = now
            speed = max(location.speed, 0) * 3.6 // Convert speed from m/s to km/h
            altitude = location.altitude
            longitude = location.coordinate.longitude
            latitude = location.coordinate.latitude
            accuracyDescription = getAccuracyDescription(horizontalAccuracy: location.horizontalAccuracy)
            // routeManager.addRoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude)
            addRoutePoint();
        }
    }
    
    // CLLocationManagerDelegate method to handle heading updates
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if abs(newHeading.trueHeading - lastHeading) > 2 {
            heading = newHeading.trueHeading
            lastHeading = newHeading.trueHeading
            lastUpdate = Date()
            print("Heading updated: \(heading)")
            
            // Päivitetään myös sijainti, nopeus ja korkeus
            if let location = manager.location {
                speed = max(location.speed, 0) * 3.6 // Convert speed from m/s to km/h
                altitude = location.altitude
                longitude = location.coordinate.longitude
                latitude = location.coordinate.latitude
                accuracyDescription = getAccuracyDescription(horizontalAccuracy: location.horizontalAccuracy)
                // routeManager.addRoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude)
                addRoutePoint();
            }
        }
    }
    
    func addRoutePoint() {
        print("LocationsUpdate: Speed: \(speed), Altitude: \(altitude), Heading: \(heading), Accuracy: \(accuracyDescription)")

        if isTracking == true && speed > 0 {
            routeManager.addRoutePoint(speed: speed, heading: heading, altitude: altitude, longitude: longitude, latitude: latitude)
        }
        if speed <= 20/3.6 {
            manager.distanceFilter = CLLocationDistance(10)
            manager.headingFilter =  CLLocationDegrees(10)
        } else        if speed > 20/3.6 {
            manager.distanceFilter = CLLocationDistance(25)
            manager.headingFilter =  CLLocationDegrees(15)
        } else if speed > 100/3.6 {
            manager.distanceFilter = CLLocationDistance(500)
            manager.headingFilter =  CLLocationDegrees(20)

        }
    }
    
    // CLLocationManagerDelegate method to handle location update failures
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to update location: \(error.localizedDescription)")
    }
    
    // Determine if we should update the location based on the time interval and speed
    private func shouldUpdateLocation(timeInterval: TimeInterval, speed: CLLocationSpeed) -> Bool {
        if abs(timeInterval) > 30 || (abs(timeInterval) > 10 && speed < 5.56) { // speed < 20 km/h (5.56 m/s)
            return true
        }
        return false
    }
    
    // Get a human-readable description of the location accuracy
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
