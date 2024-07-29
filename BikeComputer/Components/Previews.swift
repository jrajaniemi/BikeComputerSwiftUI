import CoreLocation

class PreviewLocationManager: LocationManager {
    override init() {
        super.init()
        self.speed = 26.9
        self.heading = 145.0
        self.altitude = 64
        self.latitude = 60.1699
        self.longitude = 24.9384
        self.accuracyDescription = "High"
        self.imperialSpeed = 10.21
        self.imperialAltitude = 91
        
    }
}
