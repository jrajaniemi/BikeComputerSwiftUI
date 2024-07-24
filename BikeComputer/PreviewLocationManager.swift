import CoreLocation

class PreviewLocationManager: LocationManager {
    override init() {
        super.init()
        self.speed = 6.9
        self.heading = 145.0
        self.altitude = 12000.0
        self.latitude = 60.1699
        self.longitude = 24.9384
        self.accuracyDescription = "High"
    }
}
