import SwiftUI

struct SettingsView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var batteryManager = BatteryManager.shared
    @AppStorage("selectedColorScheme") private var selectedColorScheme: Int = 0
    @AppStorage("batteryThreshold") private var batteryThreshold: Double = 100.0
    @AppStorage("unitPreference") private var unitPreference: Int = 0 // 0 for km/h, 1 for mph

    @Environment(\.colorScheme) var colorScheme

    // Hae versionumero Info.plist-tiedostosta
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
        return "Version \(version) Build (\(build))"
    }

    var body: some View {
        NavigationView {
            Form {
                ColorSchemeView()

                BatteryThresholdView()

                UnitPreferenceView()
                
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

struct ParametersView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var batteryManager = BatteryManager.shared
    var body: some View {
        Section(header: Text("Parameters")) {
            if(locationManager.powerSavingMode == .off) {
                Text("Power saving mode: Off")
            } else if(locationManager.powerSavingMode == .normal) {
                Text("Power saving mode: Normal")
            } else {
                Text("Power saving mode: Maximum")
            }
            Text("Is charging: \(batteryManager.isCharging ? "Yes" : "No")")
            Text("Desired Accuracy: \(locationManager.accuracyDescription)")
            
        }
    }
}

struct DebugParametersView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var batteryManager = BatteryManager.shared
    var body: some View {
        Section(header: Text("Debug parameters")) {
            Text("Heading Filter: \(locationManager.HF)")
            Text("Distance Filter: \(locationManager.DF)")
            Text("Battery Level: \(batteryManager.batteryLevel * 100, specifier: "%.0f") %")
            Text("Is Idle Timer Disabled: \(batteryManager.isIdleTimerDisabled) ")
            Text("Speed class: \(locationManager.currentSpeedClass)")
            Text("Speed: \(locationManager.speed, specifier: "%.3f") km/h")
            Text("Allows Background Location Updates: \(locationManager.manager.allowsBackgroundLocationUpdates ? "Yes" : "No")")
            Text("Lat, Lon: \(locationManager.latitude, specifier: "%.4f") \(locationManager.longitude, specifier: "%.4f")")
        }
    }
}
