import SwiftUI

/// A view for managing and presenting settings within the app.
///
/// This view provides user-configurable settings for color schemes, battery thresholds, unit preferences, and displays additional information about the app version. It integrates with the system's color scheme to provide a consistent user experience.
struct SettingsView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var batteryManager = BatteryManager.shared
    @AppStorage("selectedColorScheme") private var selectedColorScheme: Int = 0
    @AppStorage("batteryThreshold") private var batteryThreshold: Double = 100.0
    @AppStorage("unitPreference") private var unitPreference: Int = 0 // 0 for km/h, 1 for mph
    @AppStorage("autoRecord") private var autoRecord: Int = 0   // 0 = off, 1 = auto start when, BAC Start
    @Environment(\.colorScheme) var colorScheme

    /// Retrieves the application version and build number from Info.plist.
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
        return "Version \(version) Build (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                ColorSchemeView()

                BatteryThresholdView()

                UnitPreferenceView()

                AutoRecordView()

                ParametersView(locationManager: locationManager, batteryManager: batteryManager)

                Section(header: Text("About")) {
                    Text(appVersion)
                }
#if DEBUG
                DebugParametersView(locationManager: locationManager, batteryManager: batteryManager)
#endif
            }
            .navigationTitle("Settings")
            .background(colorScheme == .dark ? Color.black : Color.white)
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
        .toolbarBackground(colorScheme == .dark ? Color.black : Color.white)
    }
}

#Preview {
    let locationManager = LocationManager()
    locationManager.HF = 10
    locationManager.DF = 5
    locationManager.currentSpeedClass = .cycling
    locationManager.speed = 25.0

    return SettingsView(locationManager: locationManager)
}

/// Provides a user interface for selecting the preferred color scheme.
///
/// This view uses `@AppStorage` to persist the selected color scheme across app launches.
struct ColorSchemeView: View {
    @AppStorage("selectedColorScheme") private var selectedColorScheme: Int = 0

    var body: some View {
        Section(header: Text("Color Scheme")) {
            Picker("Appearance", selection: $selectedColorScheme) {
                Text("System").tag(0)
                Text("Light").tag(1)
                Text("Dark").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

/// Allows users to set a battery threshold for notifications.
///
/// `@AppStorage` is used to persist the threshold value. Slider provides real-time adjustment of the threshold.
struct BatteryThresholdView: View {
    @AppStorage("batteryThreshold") private var batteryThreshold: Double = 100.0
    var body: some View {
        Section(header: Text("Battery Threshold")) {
            Text("Battery Threshold: \(Int(batteryThreshold))%")
            Slider(value: $batteryThreshold, in: 40 ... 100, step: 1) {
                Text("Battery Threshold")
            }
            .accessibilityValue(Text("\(Int(batteryThreshold))%"))
        }
    }
}

/// Provides a picker to choose between kilometers per hour and miles per hour.
///
/// Uses `@AppStorage` to save the user's unit preference.
struct UnitPreferenceView: View {
    @AppStorage("unitPreference") private var unitPreference: Int = 0 // 0 for km/h, 1 for mph

    var body: some View {
        Section(header: Text("Unit Preference")) {
            Picker("Units", selection: $unitPreference) {
                Text("km/h").tag(0)
                Text("mph").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

/// Provides a user interface for enabling or disabling auto record.
///
/// This view uses `@AppStorage` to persist the auto record setting across app launches.
struct AutoRecordView: View {
    @AppStorage("autoRecord") private var autoRecord: Int = 0

    var body: some View {
        Section(header: Text("Auto Record (Beta)")) {
            Picker("Auto Record", selection: $autoRecord) {
                Text("Off").tag(0)
                Text("On").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

/// Displays various parameters related to the device's location and battery settings.
///
/// This view dynamically updates to show the current power saving mode, charging status, and location accuracy.
struct ParametersView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var batteryManager = BatteryManager.shared
    var body: some View {
        Section(header: Text("Parameters")) {
            if(locationManager.powerSavingMode == .off) {
                Text("Power saving mode: Off")
            } else if(locationManager.powerSavingMode == .normal) {
                Text("Power saving mode: Normal")
            } else if(locationManager.powerSavingMode == .max) {
                Text("Power saving mode: Maximum")
            } else {
                Text("Power saving mode: Unknown")
            }
            
            if(batteryManager.isCharging) {
                Text("Is charging: yes")
            } else {
                Text("Is charging: no")
            }
            Text("Desired Accuracy: \(locationManager.accuracyDescription)")
        }
    }
}

/// Provides debugging information that is only available in debug builds.
///
/// Displays settings that are typically only of interest during development, such as internal state and configurations.
struct DebugParametersView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var batteryManager = BatteryManager.shared
    var body: some View {
        #if DEBUG
        Section(header: Text("Debug parameters")) {
            Text("Heading Filter: \(locationManager.HF)")
            Text("Distance Filter: \(locationManager.DF)")
            Text("Battery Level: \(batteryManager.batteryLevel * 100, specifier: "%.0f") %")
            Text("Is Idle Timer Disabled: \(batteryManager.isIdleTimerDisabled) ")
            Text("Speed class: \(locationManager.currentSpeedClass)")
            Text("Speed: \(locationManager.speed, specifier: "%.3f") km/h")
            Text("Allows Background Location Updates: \(locationManager.manager.allowsBackgroundLocationUpdates ? String(localized:"Yes") : String(localized:"No"))")
            Text("Lat, Lon: \(locationManager.latitude, specifier: "%.4f") \(locationManager.longitude, specifier: "%.4f")")
        }
        #endif
    }
}
