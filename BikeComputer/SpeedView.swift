import SwiftUI
import CoreLocation

struct SpeedView: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var isRecording: Bool
    @Binding var routeName: String
    @Binding var routeDescription: String
    @Binding var displayLastFivePoints: Bool
    @Binding var lastFivePoints: [RoutePoint]
    @Binding var showRouteView: Bool

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 5
        formatter.decimalSeparator = "."
        return formatter
    }()
    
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
                    

                    if locationManager.routeManager.totalDistance < 1000 {
                        Text("\(locationManager.routeManager.totalDistance, specifier: "%.0f") m ")
                            .font(.custom("Univers LT 45 Light", size: 32))
                            .multilineTextAlignment(.center)
                            .frame(width: geometry.size.width, height: geometry.size.height * 1 / 10)
                            .background(Color(hex: "#212121"))
                            .foregroundColor(.white)
                    } else {
                        Text("\(locationManager.routeManager.totalDistance / 1000, specifier: "%.2f") km ")
                            .font(.custom("Univers LT 45 Light", size: 24))
                            .multilineTextAlignment(.center)
                            .frame(width: geometry.size.width, height: geometry.size.height * 1.25 / 32)
                            .background(Color(hex: "#212121"))
                            .foregroundColor(.white)
                    }
                    
                    Text("\(locationManager.routeManager.odometer / 1000, specifier: "%.1f") km")
                        .font(.custom("Univers LT 45 Light", size: 18))
                        .multilineTextAlignment(.center)
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.75 / 10)
                        .background(Color(hex: "#212121"))
                        .foregroundColor(.white)
                    /*
                     
                    let latitudeText = numberFormatter.string(from: NSNumber(value: locationManager.latitude)) ?? "0.00000"
                    let longitudeText = numberFormatter.string(from: NSNumber(value: locationManager.longitude)) ?? "0.00000"
                     
                    Text("\(latitudeText), \(longitudeText)")
                        .font(.custom("Univers LT 45 Light", size: 18))
                        .multilineTextAlignment(.center)
                        .frame(width: geometry.size.width, height: geometry.size.height * 1 / 12)
                        .background(Color(hex: "#0033A0"))
                        .foregroundColor(.white)
                    */
                    Button(action: {
                        isRecording.toggle()
                        if isRecording {
                            locationManager.routeManager.startNewRoute(name: routeName, description: routeDescription)
                            locationManager.startLocationUpdates()
                            locationManager.isTracking = true
                        } else {
                            locationManager.routeManager.endCurrentRoute()
                            locationManager.isTracking = false
                        }
                    }) {
                        Text(isRecording ? "Stop" : "Record")
                            .font(.custom("Univers LT 75 Black", size: 24))
                            .frame(width: geometry.size.width, height: geometry.size.height * 1 / 12)
                            .background(isRecording ? Color.red : Color.green)
                            .foregroundColor(.white)
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    routeName = "Default Route"
                    routeDescription = "Description of the route"
                }
            }
            
            Text("km/h")
                .font(.custom("Univers LT 45 Light", size: 24))
                .foregroundColor(.white)
                .position(x: geometry.size.width * 10 / 12, y: geometry.size.height * 4.5 / 12)
        }
    }
}
