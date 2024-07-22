import SwiftUI
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

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue & 0xff0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00ff00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000ff) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

struct ContentView: View {
    @StateObject private var locationManager: LocationManager
    @State private var isRecording: Bool = false
    @State private var routeName: String = ""
    @State private var routeDescription: String = ""
    @State private var displayLastFivePoints: Bool = false
    @State private var lastFivePoints: [RoutePoint] = []
    
    init(locationManager: LocationManager = LocationManager()) {
        _locationManager = StateObject(wrappedValue: locationManager)
    }
    
    // Määritetään desimaalipisteen muotoilija
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 5
        formatter.decimalSeparator = "."
        return formatter
    }()
    
    // Määritetään desimaalipisteen muotoilija
    private let speedFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.decimalSeparator = "."
        return formatter
    }()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // Tarkistetaan nopeus ja asetetaan eri specifier
                    let speedText = locationManager.speed < 100 ?
                    speedFormatter.string(from: NSNumber(value: locationManager.speed)) ?? "0.0" :
                    String(format: "%.0f", locationManager.speed)
                    
                    let speedFontSize: Int = locationManager.speed < 100 ? 132 : 116
                    
                    Text(speedText)
                        .font(.custom("Univers LT 75 Black", size: CGFloat(speedFontSize)))
                        .multilineTextAlignment(.center)
                        .frame(width: geometry.size.width, height: geometry.size.height * 6 / 12)
                        .background(Color(hex: "#EA3A2D"))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 0) {
                        Text("\(locationManager.heading, specifier: "%.0f")°")
                            .font(.custom("Univers LT 75 Black", size: 48))
                            .frame(width: geometry.size.width / 2, height: geometry.size.height * 3 / 12)
                            .background(Color(hex: "#FFD700"))
                            .foregroundColor(.black)
                        
                        let altitudeFontSize: Int = locationManager.altitude < 10000 ? 48 : 40
                        
                        Text("\(locationManager.altitude, specifier: "%.0f") m")
                            .font(.custom("Univers LT 45 Light", size: CGFloat(altitudeFontSize)))
                            .frame(width: geometry.size.width / 2, height: geometry.size.height * 3 / 12)
                            .background(Color.green)
                            .foregroundColor(.white)
                    }
                    /*
                    if displayLastFivePoints {
                        VStack {
                            ForEach(lastFivePoints, id: \.timestamp) { point in
                                Text("Lat: \(point.latitude), Long: \(point.longitude), Speed: \(point.speed) km/h")
                                    .font(.custom("Univers LT 45 Light", size: 12))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Route points: \(locationManager.routeManager.routeLength)")
                                .font(.custom("Univers LT 45 Light", size: 12))
                                .foregroundColor(.white)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height * 3 / 12)
                        .background(Color(hex: "#212121"))
                    } else {
                        let latitudeText = numberFormatter.string(from: NSNumber(value: locationManager.latitude)) ?? "0.00000"
                        let longitudeText = numberFormatter.string(from: NSNumber(value: locationManager.longitude)) ?? "0.00000"
                        
                        Text("\(latitudeText), \(longitudeText)")
                            .font(.custom("Univers LT 45 Light", size: 24))
                            .multilineTextAlignment(.center)
                            .frame(width: geometry.size.width, height: geometry.size.height * 3 / 12)
                            .background(Color(hex: "#212121"))
                            .foregroundColor(.white)
                    }
                     */
                    let latitudeText = numberFormatter.string(from: NSNumber(value: locationManager.latitude)) ?? "0.00000"
                    let longitudeText = numberFormatter.string(from: NSNumber(value: locationManager.longitude)) ?? "0.00000"
                    if locationManager.routeManager.totalDistance < 1000 {
                        Text("\(locationManager.routeManager.totalDistance, specifier: "%.0f") m ")
                            .font(.custom("Univers LT 45 Light", size: 32))
                            .multilineTextAlignment(.center)
                            .frame(width: geometry.size.width, height: geometry.size.height * 2 / 12)
                            .background(Color(hex: "#212121"))
                            .foregroundColor(.white)
                    } else {
                        Text("\(locationManager.routeManager.totalDistance/1000, specifier: "%.2f") km ")
                            .font(.custom("Univers LT 45 Light", size: 24))
                            .multilineTextAlignment(.center)
                            .frame(width: geometry.size.width, height: geometry.size.height * 2 / 32)
                            .background(Color(hex: "#212121"))
                            .foregroundColor(.white)
                    }
                    
                    Text("\(latitudeText), \(longitudeText)")
                        .font(.custom("Univers LT 45 Light", size: 18))
                        .multilineTextAlignment(.center)
                        .frame(width: geometry.size.width, height: geometry.size.height * 1 / 12)
                        .background(Color(hex: "#212121"))
                        .foregroundColor(.white)
                    
                    Button(action: {
                        isRecording.toggle()
                        if isRecording {
                            locationManager.routeManager.startNewRoute(name: routeName, description: routeDescription)
                            locationManager.startLocationUpdates()
                            locationManager.isTracking = true
                            displayLastFivePoints = false
                        } else {
                            locationManager.routeManager.endCurrentRoute()
                            lastFivePoints = locationManager.routeManager.getLastFivePoints()
                            locationManager.isTracking = false
                            displayLastFivePoints = true
                        }
                    }) {
                        Text(isRecording ? "Stop" : "Record")
                            .font(.custom("Univers LT 75 Black", size: 24))
                            .frame(width: geometry.size.width, height: 50)
                            .background(isRecording ? Color.red : Color.green)
                            .foregroundColor(.white)
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    routeName = "Default Route"
                    routeDescription = "Description of the route"
                }
                
                Text("km/h")
                    .font(.custom("Univers LT 45 Light", size: 24))
                    .foregroundColor(.white)
                    .position(x: geometry.size.width * 10 / 12, y: geometry.size.height * 4.5 / 12)
            }
        }
    }
}

#Preview {
    ContentView(locationManager: PreviewLocationManager())
}
