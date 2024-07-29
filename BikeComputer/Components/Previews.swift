import CoreLocation

class PreviewLocationManager: LocationManager {
    override init() {
        super.init()
        self.speed = 126.9
        self.heading = 145.0
        self.altitude = 16
        self.latitude = 60.1699
        self.longitude = 24.9384
        self.accuracyDescription = "High"
    }
}
