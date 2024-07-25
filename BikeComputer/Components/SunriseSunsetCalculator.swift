import Foundation
import CoreLocation
import Combine

struct SunriseSunsetTimes {
    let sunrise: Date
    let sunset: Date
}

class SunriseSunsetCalculator: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var sunriseSunsetTimes: SunriseSunsetTimes?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            fetchSunriseSunset(for: location.coordinate)
            locationManager.stopUpdatingLocation()
        }
    }
    
    func fetchSunriseSunset(for coordinate: CLLocationCoordinate2D) {
        let urlString = "https://api.sunrise-sunset.org/json?lat=\(coordinate.latitude)&lng=\(coordinate.longitude)&formatted=0"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            do {
                let response = try JSONDecoder().decode(SunriseSunsetResponse.self, from: data)
                let formatter = ISO8601DateFormatter()
                if let sunrise = formatter.date(from: response.results.sunrise),
                   let sunset = formatter.date(from: response.results.sunset) {
                    DispatchQueue.main.async {
                        self.sunriseSunsetTimes = SunriseSunsetTimes(sunrise: sunrise, sunset: sunset)
                        ThemeManager.shared.updateTheme(sunriseSunsetTimes: self.sunriseSunsetTimes!)
                    }
                }
            } catch {
                print("Failed to decode JSON: \(error)")
            }
        }.resume()
    }
}

struct SunriseSunsetResponse: Codable {
    struct Results: Codable {
        let sunrise: String
        let sunset: String
    }
    let results: Results
}
