import CoreLocation
import SwiftUI

// Formatter-luokka
class Formatters {
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 5
        formatter.decimalSeparator = "."
        return formatter
    }()
    
    static let speedFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.decimalSeparator = "."
        return formatter
    }()
}

// SpeedTextView
struct SpeedTextView: View {
    var speed: Double
    var imperialSpeed: Double
    var speedFontSize: CGFloat
    
    @AppStorage("unitPreference") private var unitPreference: Int = 0 // 0 for km/h and meters, 1 for mph and miles
    var body: some View {
        if unitPreference == 1 {
            VStack(spacing: 0) {
                Text(imperialSpeed < 40 ? Formatters.speedFormatter.string(from: NSNumber(value: imperialSpeed)) ?? "0.0" : String(format: "%.0f", imperialSpeed))
                    .font(.custom("Barlow-Black", size: speedFontSize))
                    .multilineTextAlignment(.center)
                
                Text("mph")
                    .font(.custom("Barlow-ExtraLight", size: 32))
            }
        } else {
            VStack(spacing: 0) {
                Text(speed < 50 ? Formatters.speedFormatter.string(from: NSNumber(value: speed)) ?? "0.0" : String(format: "%.0f", speed))
                    .font(.custom("Barlow-Black", size: speedFontSize))
                    .multilineTextAlignment(.center)
                
                Text("km/h")
                    .font(.custom("Barlow-ExtraLight", size: 32))
            }
        }
    }
}

// HeadingAndAltitudeView
struct HeadingAndAltitudeView: View {
    var heading: Double
    var altitude: Double
    var imperialAltitude: Double
    var altitudeFontSize: CGFloat
    @AppStorage("unitPreference") private var unitPreference: Int = 0 // 0 for km/h and meters, 1 for mph and miles

    var body: some View {
        if unitPreference == 1 {
            HStack(spacing: 0) {
                Text("\(heading, specifier: "%.0f")°")
                    .font(.custom("Barlow-Bold", size: 48))
                    .frame(maxWidth: .infinity)
                
                Text("\(imperialAltitude, specifier: "%.0f") ft")
                    .font(.custom("Barlow-Light", size: altitudeFontSize))
                    .frame(maxWidth: .infinity)
            }
        } else {
            HStack(spacing: 0) {
                Text("\(heading, specifier: "%.0f")°")
                    .font(.custom("Barlow-Bold", size: 48))
                    .frame(maxWidth: .infinity)
                
                Text("\(altitude, specifier: "%.0f") m")
                    .font(.custom("Barlow-Light", size: altitudeFontSize))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// DistanceView
struct DistanceView: View {
    var totalDistance: Double
    var odometer: Double
    var imperialTotalDistance: Double
    var imperialOdometer: Double
    
    @AppStorage("unitPreference") private var unitPreference: Int = 0 // 0 for km/h and meters, 1 for mph and miles

    var body: some View {
        VStack(spacing: 0) {
            if unitPreference == 1 {
                if imperialTotalDistance < 5280 {
                    Text("\(imperialTotalDistance, specifier: "%.0f") ft")
                        .font(.custom("Barlow-SemiBold", size: 36))
                        .multilineTextAlignment(.center)
                } else {
                    Text("\(imperialTotalDistance / 5280, specifier: "%.2f") mi")
                        .font(.custom("Barlow-SemiBold", size: 36))
                        .multilineTextAlignment(.center)
                }
                Text("\(imperialOdometer / 5280, specifier: "%.1f") mi")
                    .font(.custom("Barlow-Thin", size: 12))
                    .multilineTextAlignment(.center)
            } else {
                if totalDistance < 1000 {
                    Text("\(totalDistance, specifier: "%.0f") m")
                        .font(.custom("Barlow-SemiBold", size: 36))
                        .multilineTextAlignment(.center)
                } else {
                    Text("\(totalDistance / 1000, specifier: "%.2f") km")
                        .font(.custom("Barlow-SemiBold", size: 36))
                        .multilineTextAlignment(.center)
                }
                Text("\(odometer / 1000, specifier: "%.1f") km")
                    .font(.custom("Barlow-Thin", size: 14))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// RecordButtonView
struct RecordButtonView: View {
    @Binding var isRecording: Bool
    @ObservedObject var locationManager: LocationManager
    var routeName: String
    var routeDescription: String
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    
    var body: some View {
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
                .font(.custom("Barlow-Black", size: 24))
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Route Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// Pääasiallinen SpeedView
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
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                SpeedTextView(
                    speed: locationManager.speed,
                    imperialSpeed: locationManager.imperialSpeed,
                    speedFontSize: locationManager.speed < 100 ? 136 : 120
                )
                .frame(width: geometry.size.width, height: geometry.size.height * 6 / 12)
                .background(colorScheme == .dark ? Color.black : Color.white)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                
                HeadingAndAltitudeView(
                    heading: locationManager.heading,
                    altitude: locationManager.altitude,
                    imperialAltitude: locationManager.imperialAltitude,
                    altitudeFontSize: locationManager.altitude < 10000 ? 48 : 40
                )
                .frame(height: geometry.size.height * 2 / 12)
                .background(colorScheme == .dark ? Color.black : Color.white)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                
                DistanceView(
                    totalDistance: locationManager.routeManager.totalDistance,
                    odometer: locationManager.routeManager.odometer,
                    imperialTotalDistance: locationManager.routeManager.imperialTotalDistance,
                    imperialOdometer: locationManager.routeManager.imperialOdometer
                )
                .frame(height: geometry.size.height * 3 / 12)
                .background(colorScheme == .dark ? Color.black : Color.white)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                
                RecordButtonView(
                    isRecording: $isRecording,
                    locationManager: locationManager,
                    routeName: routeName,
                    routeDescription: routeDescription,
                    showingAlert: $showingAlert,
                    alertMessage: $alertMessage
                )
                .frame(width: geometry.size.width / 2, height: geometry.size.height * 0.8 / 12)
                .background(colorScheme == .dark ? Color.black : Color.white)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                .border(Color.gray, width: 3)
            }
            .onAppear {
                routeName = "Default Route"
                routeDescription = "Description of the route"
                listAllFonts()
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
    }
    
    func listAllFonts() {
        for family in UIFont.familyNames.sorted() {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  Font: \(name)")
            }
        }
    }
}
