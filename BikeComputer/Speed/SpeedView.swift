import CoreLocation
import SwiftUI

/// A class containing formatter instances for number and speed formatting.
class Formatters {
    /// Number formatter with decimal style, maximum fraction digits set to 5, and decimal separator as "."
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 5
        formatter.decimalSeparator = "."
        return formatter
    }()

    /// Speed formatter with decimal style, maximum fraction digits set to 1, and decimal separator as "."
    static let speedFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.decimalSeparator = "."
        return formatter
    }()
}

/// A SwiftUI view that displays speed information.
///
/// - Parameters:
///   - speed: The speed in kilometers per hour.
///   - imperialSpeed: The speed in miles per hour.
///   - speedFontSize: The font size for the speed text.
struct SpeedTextView: View {
    var speed: Double
    var imperialSpeed: Double
    var speedFontSize: CGFloat
    
    @AppStorage("unitPreference") private var unitPreference: Int = 0 // 0 for km/h and meters, 1 for mph and miles
    var body: some View {
        if unitPreference == 1 {
            VStack(spacing: 0) {
                Text(imperialSpeed < 10 ? Formatters.speedFormatter.string(from: NSNumber(value: imperialSpeed)) ?? "0.0" : String(format: "%.0f", imperialSpeed))
                    .font(.custom("Barlow-Black", size: speedFontSize))
                    .multilineTextAlignment(.center)
                    
                Text("mph")
                    .font(.custom("Barlow-ExtraLight", size: 32))
            }
                
        } else {
            VStack(spacing: 0) {
                Text(speed < 10 ? Formatters.speedFormatter.string(from: NSNumber(value: speed)) ?? "0.0" : String(format: "%.0f", speed))
                    .font(.custom("Barlow-Black", size: speedFontSize))
                    .multilineTextAlignment(.center)
                    
                Text("km/h")
                    .font(.custom("Barlow-ExtraLight", size: 32))
            }
        }
    }
}

/// A SwiftUI view that displays heading and altitude information.
///
/// - Parameters:
///   - heading: The heading in degrees.
///   - altitude: The altitude in meters.
///   - imperialAltitude: The altitude in feet.
///   - altitudeFontSize: The font size for the altitude text.
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

/// A SwiftUI view that displays distance information.
///
/// - Parameters:
///   - totalDistance: The total distance in meters.
///   - odometer: The odometer reading in meters.
///   - imperialTotalDistance: The total distance in feet.
///   - imperialOdometer: The odometer reading in feet.
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
                        .font(.custom("Barlow-SemiBold", size: 40))
                        .multilineTextAlignment(.center)
                } else {
                    Text("\(imperialTotalDistance / 5280, specifier: "%.2f") mi")
                        .font(.custom("Barlow-SemiBold", size: 40))
                        .multilineTextAlignment(.center)
                }
                Text("\(imperialOdometer / 5280, specifier: "%.1f") mi")
                    .font(.custom("Barlow-Thin", size: 12))
                    .multilineTextAlignment(.center)
            } else {
                if totalDistance < 1000 {
                    Text("\(totalDistance, specifier: "%.0f") m")
                        .font(.custom("Barlow-SemiBold", size: 40))
                        .multilineTextAlignment(.center)
                } else {
                    Text("\(totalDistance / 1000, specifier: "%.2f") km")
                        .font(.custom("Barlow-SemiBold", size: 40))
                        .multilineTextAlignment(.center)
                }
                Text("\(odometer / 1000, specifier: "%.1f") km")
                    .font(.custom("Barlow-Thin", size: 14))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

/// A SwiftUI view that displays a button to start or stop recording a route.
///
/// - Parameters:
///   - isRecording: A binding to a Boolean value indicating whether recording is in progress.
///   - locationManager: The location manager responsible for tracking the route.
///   - routeName: The name of the route.
///   - routeDescription: The description of the route.
///   - showingAlert: A binding to a Boolean value indicating whether an alert should be shown.
///   - alertMessage: A binding to a string that contains the alert message.
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
                    locationManager.routeManager.totalDistance = 0
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

/// The main view that displays speed, heading, altitude, and distance information, and allows starting and stopping route recording.
///
/// - Parameters:
///   - locationManager: The location manager responsible for tracking the route.
///   - isRecording: A binding to a Boolean value indicating whether recording is in progress.
///   - routeName: A binding to a string containing the name of the route.
///   - routeDescription: A binding to a string containing the description of the route.
///   - displayLastFivePoints: A binding to a Boolean value indicating whether to display the last five points of the route.
///   - lastFivePoints: A binding to an array of the last five points of the route.
///   - showRouteView: A binding to a Boolean value indicating whether to show the route view.
struct SpeedView: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var isRecording: Bool
    @Binding var routeName: String
    @Binding var routeDescription: String
    @Binding var displayLastFivePoints: Bool
    @Binding var lastFivePoints: [RoutePoint]
    @Binding var showRouteView: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("autoRecord") private var storedAutoRecord: Int = 0 // 0 for manual, 1 for auto
    @AppStorage("unitPreference") private var unitPreference: Int = 0 // 0 for km/h and meters, 1 for mph and miles

    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var animationCount = 0
    @State private var autoRecordCount: Int = 0 // Autorecord not never started
    @State private var autoRecordTimer: Timer?
    @State private var autoRecord: Int = 0


    private func startRecording() {
        if !isRecording {
            isRecording = true
            locationManager.routeManager.startNewRoute(name: routeName, description: routeDescription)
            locationManager.startLocationUpdates()
            locationManager.isTracking = true
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    SpeedTextView(
                        speed: locationManager.speed,
                        imperialSpeed: locationManager.imperialSpeed,
                        speedFontSize: locationManager.speed < 100 ? 140 : 130
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
                    .frame(height: geometry.size.height * 3 / 12)
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
                }
                .onAppear {
                    routeName = "Default Route"
                    routeDescription = "Description of the route"
                    
                    autoRecord = storedAutoRecord
                    
                    print("onAppear - autoRecord: \(autoRecord),  \(autoRecordCount)")
                    if autoRecord == 1 && autoRecordCount == 0 {
                        startAutoRecordTimer()
                    }
                }
                .onChange(of: storedAutoRecord) {
                    autoRecord = storedAutoRecord
                    print("onChange - autoRecord updated: \(autoRecord)")
                }
                .background(colorScheme == .dark ? Color.black : Color.white)
                
                Text("BIKE App Computer")
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    .position(x: 80, y: 25)
                    .font(.custom("Barlow-SemiBold", size: 10))
                
                RecordButtonView(
                    isRecording: $isRecording,
                    locationManager: locationManager,
                    routeName: routeName,
                    routeDescription: routeDescription,
                    showingAlert: $showingAlert,
                    alertMessage: $alertMessage
                )
                .frame(width: geometry.size.width / 2, height: geometry.size.height * 1 / 12)
                .background(colorScheme == .dark ? Color(hex: "#333333") : Color(hex: "#eeeeee"))
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                .cornerRadius(geometry.size.height * 1 / 24)
                
                if isRecording == true {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Image(systemName: "record.circle")
                                .symbolEffect(.bounce.wholeSymbol, value: animationCount)
                                .foregroundColor(.red)
                                .font(.title)
                                .frame(width: 55, height: 55, alignment: .center)
                            
                            // .breathe
                        }
                             
                        Spacer()
                    }
                }
            }
        }
    }
    
    /// Starts the auto-record timer.
    ///
    /// The timer checks every 10 seconds if the speed exceeds a threshold
    /// and starts recording automatically if conditions are met.
    private func startAutoRecordTimer() {
        autoRecordTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
#if DEBUG
                print("startAutoRecordTimer / AutoRecord: \(autoRecord) AutoRecordCount: \(autoRecordCount)")
#endif
            self.shouldStartRecording()
        }
    }
    
    /// Determines if recording should start based on the current speed.
    ///
    /// If the current Speedclass is not stationary and autoRecord is enabled, recording starts
    /// after a n-second delay. The timer is then invalidated.
    private func shouldStartRecording() {
#if DEBUG
                print("shouldStartRecording - AutoRecord: \(autoRecord) AutoRecordCount: \(autoRecordCount)")
#endif
        if locationManager.currentSpeedClass != .stationary && autoRecord == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                autoRecordTimer?.invalidate()
                autoRecordTimer = nil
                autoRecordCount += 1
                startRecording()
#if DEBUG
                print("shouldStartRecording / AutoRecord: \(autoRecord) AutoRecordCount: \(autoRecordCount)")
#endif
                
            }
        }
    }

    /// Lists all available fonts in the console.
    func listAllFonts() {
        /*
         for family in UIFont.familyNames.sorted() {
             print("Family: \(family)")
             for name in UIFont.fontNames(forFamilyName: family) {
                 print("  Font: \(name)")
             }
         }
          */
    }
}
