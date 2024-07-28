import CoreLocation
import SwiftUI

struct SpeedView: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var isRecording: Bool
    @Binding var routeName: String
    @Binding var routeDescription: String
    @Binding var displayLastFivePoints: Bool
    @Binding var lastFivePoints: [RoutePoint]
    @Binding var showRouteView: Bool
    
    @State private var showingAlert = false
    @State private var alertMessage = ""

    @Environment(\.colorScheme) var colorScheme
    @AppStorage("unitPreference") private var unitPreference: Int = 0 // 0 for km/h and meters, 1 for mph and miles

    
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
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    let speedText = locationManager.speed < 50 ? speedFormatter.string(from: NSNumber(value: locationManager.speed)) ?? "0.0" : String(format: "%.0f", locationManager.speed)
                        
                    let speedFontSize: Int = locationManager.speed < 100 ? 130 : 116
                        
                    Text(speedText)
                        .font(.custom("Univers LT 75 Black", size: CGFloat(speedFontSize)))
                        .multilineTextAlignment(.center)

                    Text("km/h")
                        .font(.custom("Univers LT 45 Light", size: 32))
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 6 / 12)
                .background(colorScheme == .dark ? Color.black: Color.white)
                .foregroundColor(colorScheme == .dark ? Color.white: Color.black)
                    
                HStack(spacing: 0) {
                    Text("\(locationManager.heading, specifier: "%.0f")°")
                        .font(.custom("Univers LT 75 Black", size: 48))
                        .frame(width: geometry.size.width / 2, height: geometry.size.height * 3 / 12)
                        .background(colorScheme == .dark ? Color.black: Color.white)
                        .foregroundColor(colorScheme == .dark ? Color.white: Color.black)
                        
                    let altitudeFontSize: Int = locationManager.altitude < 10000 ? 48 : 40
                        
                    Text("\(locationManager.altitude, specifier: "%.0f") m")
                        .font(.custom("Univers LT 45 Light", size: CGFloat(altitudeFontSize)))
                        .frame(width: geometry.size.width / 2, height: geometry.size.height * 3 / 12)
                        .background(colorScheme == .dark ? Color.black: Color.white)
                        .foregroundColor(colorScheme == .dark ? Color.white: Color.black)
                }

                VStack(spacing: 0) {
                    if locationManager.routeManager.totalDistance < 1000 {
                        Text("\(locationManager.routeManager.totalDistance, specifier: "%.0f") m ")
                            .font(.custom("Univers LT 45 Light", size: 24))
                            .multilineTextAlignment(.center)

                    } else {
                        Text("\(locationManager.routeManager.totalDistance / 1000, specifier: "%.2f") km ")
                            .font(.custom("Univers LT 45 Light", size: 24))
                            .multilineTextAlignment(.center)
                    }
                    Text("\(locationManager.routeManager.odometer / 1000, specifier: "%.1f") km")
                        .font(.custom("Univers LT 45 Light", size: 12))
                        .multilineTextAlignment(.center)
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 2 / 12)
                .background(colorScheme == .dark ? Color.black: Color.white)
                .foregroundColor(colorScheme == .dark ? Color.white: Color.black)
                    
                Button(action: {
                    isRecording.toggle()
                    if isRecording {
                        locationManager.routeManager.startNewRoute(name: routeName, description: routeDescription)
                        locationManager.startLocationUpdates()
                        locationManager.isTracking = true
                    } else {
                        if locationManager.routeManager.currentRoute?.points.isEmpty ?? true {
                            alertMessage = "No points in current route to save."
                            showingAlert = true
                            isRecording = false
                        } else {
                            locationManager.routeManager.endCurrentRoute()
                            locationManager.isTracking = false
                        }
                    }
                }) {
                    Text(isRecording ? "STOP" : "RECORD")
                        .font(.custom("Univers LT 75 Black", size: 24))
                }
                .frame(width: geometry.size.width / 2, height: geometry.size.height * 0.8 / 12)
                .background(colorScheme == .dark ? Color.black: Color.white)
                .foregroundColor(colorScheme == .dark ? Color.white: Color.black)
                .border(Color.gray , width: 3)
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("Route Error"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .onAppear {
                routeName = "Default Route"
                routeDescription = "Description of the route"
            }
            .background(colorScheme == .dark ? Color.black: Color.white)
        }
        .background(colorScheme == .dark ? Color.black: Color.white)
    }
}
