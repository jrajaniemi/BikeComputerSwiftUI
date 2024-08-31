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
    var totalDistance: Double
    var imperialTotalDistance: Double
    
    @AppStorage("unitPreference") private var unitPreference: Int = 0 // 0 for km/h and meters, 1 for mph and miles
    
    @Binding var isZoomed: Bool // Binding muuttuja, joka seuraa, onko zoomaus päällä
    
    var body: some View {
        ZStack {
            if isZoomed {
                // Zoomattu näkymä, joka näyttää vain nopeuden suurella fontilla
                VStack {
                    if unitPreference == 1 {
                        Text(imperialSpeed < 10 ? Formatters.speedFormatter.string(from: NSNumber(value: imperialSpeed)) ?? "0.0" : String(format: "%.0f", imperialSpeed))
                            .font(.custom("Barlow-Black", size: 200))
                            .multilineTextAlignment(.center)
                            .onTapGesture {
                                isZoomed.toggle() // Palataan alkuperäiseen näkymään
                            }
                    } else {
                        Text(speed < 10 ? Formatters.speedFormatter.string(from: NSNumber(value: speed)) ?? "0.0" : String(format: "%.0f", speed))
                            .font(.custom("Barlow-Black", size: 200))
                            .multilineTextAlignment(.center)
                            .onTapGesture {
                                isZoomed.toggle() // Palataan alkuperäiseen näkymään
                            }
                    }
                    
                    Text(unitPreference == 1 ? "mph" : "km/h")
                        .font(.custom("Barlow-ExtraLight", size: 32))
                        .onTapGesture {
                            isZoomed.toggle() // Palataan alkuperäiseen näkymään
                        }
                    
                    Spacer()
                    
                    Spacer()

                    if unitPreference == 1 {
                        if imperialTotalDistance < 5280 {
                            Text("\(imperialTotalDistance, specifier: "%.0f") ft")
                                .font(.custom("Barlow-SemiBold", size: 50))
                                .multilineTextAlignment(.center)
                                .onTapGesture {
                                    isZoomed.toggle() // Palataan alkuperäiseen näkymään
                                }
                        } else {
                            Text("\(imperialTotalDistance / 5280, specifier: "%.2f") mi")
                                .font(.custom("Barlow-SemiBold", size: 50))
                                .multilineTextAlignment(.center)
                                .onTapGesture {
                                    isZoomed.toggle() // Palataan alkuperäiseen näkymään
                                }
                        }
                    } else {
                        if totalDistance < 1000 {
                            Text("\(totalDistance, specifier: "%.0f") m")
                                .font(.custom("Barlow-SemiBold", size: 50))
                                .multilineTextAlignment(.center)
                                .onTapGesture {
                                    isZoomed.toggle() // Palataan alkuperäiseen näkymään
                                }
                        } else {
                            Text("\(totalDistance / 1000, specifier: "%.2f") km")
                                .font(.custom("Barlow-SemiBold", size: 50))
                                .multilineTextAlignment(.center)
                                .onTapGesture {
                                    isZoomed.toggle() // Palataan alkuperäiseen näkymään
                                }
                        }
                    }
                }
            } else {
                // Alkuperäinen näkymä
                VStack(spacing: 0) {
                    Text(unitPreference == 1 ? (imperialSpeed < 10 ? Formatters.speedFormatter.string(from: NSNumber(value: imperialSpeed)) ?? "0.0" : String(format: "%.0f", imperialSpeed)) : (speed < 10 ? Formatters.speedFormatter.string(from: NSNumber(value: speed)) ?? "0.0" : String(format: "%.0f", speed)))
                        .font(.custom("Barlow-Black", size: speedFontSize))
                        .multilineTextAlignment(.center)
                        .onTapGesture {
                            isZoomed.toggle() // Näytetään suurennettu näkymä
                        }
                        
                    Text(unitPreference == 1 ? "mph" : "km/h")
                        .font(.custom("Barlow-ExtraLight", size: 32))
                }
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
/// - G: totalAcceleration in G
struct HeadingAndAltitudeView: View {
    var heading: Double
    var altitude: Double
    var imperialAltitude: Double
    var altitudeFontSize: CGFloat
    var G: Double
    var elapsedTime: TimeInterval
    var elapsedTimeTimer: Timer?
    
    @AppStorage("unitPreference") private var unitPreference: Int = 0 // 0 for km/h and meters, 1 for mph and miles
    @AppStorage("rowTwoLeftView") private var rowTwoLeftView: Int = 2
    @AppStorage("rowTwoRightView") private var rowTwoRightView: Int = 0
    
    @State private var showGValue: Bool = false // Togglaa G-arvon ja suunnan välillä
    @State private var showTimeValue: Bool = false // Togglaa kellonajan ja muiden tietojen välillä
    
    var body: some View {
        HStack(spacing: 0) {
            // Näytetään joko suunta, G-voima tai kellonaika riippuen togglesta
            if rowTwoLeftView == 0 {
                Text(Date(), style: .time)
                    .font(.custom("Barlow-Bold", size: 46))
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        rowTwoLeftView += 1 // Vaihda takaisin suunnan ja G-arvon välillä
                    }
            } else if rowTwoLeftView == 1 {
                Text("\(G, specifier: "%.2f") G")
                    .font(.custom("Barlow-Bold", size: 46))
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        rowTwoLeftView += 1
                    }
            } else {
                Text("\(heading, specifier: "%.0f")°")
                    .font(.custom("Barlow-Bold", size: 46))
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        rowTwoLeftView = 0
                    }
            }
            if rowTwoRightView == 0 {
                if unitPreference == 1 {
                    Text("\(imperialAltitude, specifier: "%.0f") ft")
                        .font(.custom("Barlow-Light", size: altitudeFontSize))
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            rowTwoRightView = 1 // Vaihda takaisin suunnan ja G-arvon välillä
                        }
                } else {
                    Text("\(altitude, specifier: "%.0f") m")
                        .font(.custom("Barlow-Light", size: altitudeFontSize))
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            rowTwoRightView = 1 // Vaihda takaisin suunnan ja G-arvon välillä
                        }
                }
            } else {
                if elapsedTimeTimer == nil {
                    Text("0:00")
                        .font(.custom("Barlow-Light", size: altitudeFontSize))
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            rowTwoRightView = 0
                        }
                } else {
                    (Text("+") + Text(Date(timeIntervalSinceNow: -elapsedTime), style: .timer))
                        .font(.custom("Barlow-Light", size: altitudeFontSize))
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            rowTwoRightView = 0
                        }
                }
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
    @Binding var autoRecordCount: Int
    @ObservedObject var locationManager: LocationManager
    var routeName: String
    var routeDescription: String
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String

    var startRecording: () -> Void // Lisää funktio
    var stopRecording: () -> Void // Lisää funktio
    
    var body: some View {
        Button(action: {
            isRecording.toggle()
            if isRecording {
                startRecording() // Käytä välitettyä funktiota
            } else {
                stopRecording() // Käytä välitettyä funktiota
                autoRecordCount += 1
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
    @State private var isZoomed = false // Seuraa, onko nopeusnäyttö zoomattu
    
    @State private var elapsedTime: TimeInterval = 0 // Kulunut aika
    @State private var elapsedTimeTimer: Timer? // Ajastin

    func startRecording() {
        isRecording = true
        locationManager.routeManager.startNewRoute(name: routeName, description: routeDescription)
        locationManager.startLocationUpdates()
        locationManager.isTracking = true

        debugPrint(msg: "startRecording()")
        startElapsedTimeTimer()
    }

    func stopRecording() {
        stopElapsedTimeTimer()

        if locationManager.routeManager.currentRoute?.points.isEmpty ?? true {
            alertMessage = "No points in current route to save."
            showingAlert = true
            isRecording = false
            locationManager.routeManager.totalDistance = 0
            locationManager.isTracking = false
        } else {
            locationManager.routeManager.endCurrentRoute()
            locationManager.isTracking = false
        }
        autoRecordCount += 1

        debugPrint(msg: "stopRecording()")
    }
   
    func startElapsedTimeTimer() {
        if elapsedTimeTimer != nil {
            elapsedTimeTimer?.invalidate() // Varmista, että vanha ajastin on pysäytetty
        }
        elapsedTime = 0 // Nollaa aika vain tallennuksen alkaessa
        elapsedTimeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
        }
        debugPrint(msg: "startElapsedTimeTimer()")
        debugPrint(msg: String(elapsedTime))
        debugPrint(msg: String(elapsedTimeTimer.debugDescription))
    }

    func stopElapsedTimeTimer() {
        elapsedTimeTimer?.invalidate()
        elapsedTimeTimer = nil
        elapsedTime = 0
        debugPrint(msg: "stopElapsedTimeTimer()")
        debugPrint(msg: String(elapsedTime))
        debugPrint(msg: String(elapsedTimeTimer.debugDescription))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    SpeedTextView(
                        speed: locationManager.speed,
                        imperialSpeed: locationManager.imperialSpeed,
                        speedFontSize: locationManager.speed < 100 ? 140 : 130,
                        totalDistance: locationManager.routeManager.totalDistance,
                        imperialTotalDistance: locationManager.routeManager.imperialTotalDistance,
                        isZoomed: $isZoomed // Binding tilan hallintaan
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height * 6 / 12)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    
                    if !isZoomed { // Näytetään muut näkymät vain, jos zoomaus ei ole päällä
                        HeadingAndAltitudeView(
                            heading: locationManager.heading,
                            altitude: locationManager.altitude,
                            imperialAltitude: locationManager.imperialAltitude,
                            altitudeFontSize: locationManager.altitude < 10000 ? 48 : 40,
                            G: locationManager.totalAcceleration,
                            elapsedTime: elapsedTime,
                            elapsedTimeTimer: elapsedTimeTimer
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
                }
                .onAppear {
                    routeName = "Default Route"
                    routeDescription = "Description of the route"
                    
                    autoRecord = storedAutoRecord
                    
                    // debugPring(msg: "onAppear - autoRecord: \(autoRecord),  \(autoRecordCount)")
                    if autoRecord == 1 && autoRecordCount == 0 {
                        startAutoRecordTimer()
                    }
                }
                .onChange(of: storedAutoRecord) {
                    autoRecord = storedAutoRecord
                    // debugPring(msg: "onChange - autoRecord updated: \(autoRecord)")
                }
                .background(colorScheme == .dark ? Color.black : Color.white)
                
                Text("RIDE Computer")
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    .position(x: 60, y: 30)
                    .font(.custom("Barlow-SemiBold", size: 11))
                if !isZoomed {
                    RecordButtonView(
                        isRecording: $isRecording,
                        autoRecordCount: $autoRecordCount,
                        locationManager: locationManager,
                        routeName: routeName,
                        routeDescription: routeDescription,
                        showingAlert: $showingAlert,
                        alertMessage: $alertMessage,
                        startRecording: startRecording, // Välitä funktio
                        stopRecording: stopRecording // Välitä funktio
                    )
                    .frame(width: geometry.size.width / 2, height: geometry.size.height * 1 / 12)
                    .background(colorScheme == .dark ? Color(hex: "#333333") : Color(hex: "#eeeeee"))
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    .cornerRadius(geometry.size.height * 1 / 24)
                }
                    
                if isRecording == true {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Image(systemName: "record.circle")
                                .symbolEffect(.bounce.wholeSymbol, value: animationCount)
                                .foregroundColor(.red)
                                .font(.title)
                                .frame(width: 55, height: 55, alignment: .center)
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
            // debugPring(msg: "startAutoRecordTimer / AutoRecord: \(autoRecord) AutoRecordCount: \(autoRecordCount)")
            self.shouldStartRecording()
        }
    }
    
    /// Determines if recording should start based on the current speed.
    ///
    /// If the current Speedclass is not stationary and autoRecord is enabled, recording starts
    /// after a n-second delay. The timer is then invalidated.
    private func shouldStartRecording() {
        // debugPring(msg: "shouldStartRecording - AutoRecord: \(autoRecord) AutoRecordCount: \(autoRecordCount)")
        if locationManager.currentSpeedClass != .stationary && locationManager.speed > 0.5 && autoRecord == 1 && autoRecordCount == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                autoRecordTimer?.invalidate()
                autoRecordTimer = nil
                autoRecordCount += 1
                startRecording()
                // debugPring(msg: "shouldStartRecording / AutoRecord: \(autoRecord) AutoRecordCount: \(autoRecordCount)")
            }
        }
    }

    /// Lists all available fonts in the console.
    func listAllFonts() {
        /*
         for family in UIFont.familyNames.sorted() {
         debugPring(msg:"Family: \(family)")
             for name in UIFont.fontNames(forFamilyName: family) {
                debugPring(msg:"  Font: \(name)")
             }
         }
          */
    }
}
