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
                Section(header: Text("Color Scheme")) {
                    Picker("Appearance", selection: $selectedColorScheme) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Battery Threshold")) {
                    Text("Battery Threshold: \(Int(batteryThreshold))%")
                    Slider(value: $batteryThreshold, in: 40 ... 100, step: 1) {
                        Text("Battery Threshold")
                    }
                    .accessibilityValue(Text("\(Int(batteryThreshold))%"))
                }

                Section(header: Text("Unit Preference")) {
                    Picker("Units", selection: $unitPreference) {
                        Text("km/h").tag(0)
                        Text("mph").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("About")) {
                    Text(appVersion)
                }

#if DEBUG
Section(header: Text("Parameters")) {
    Text("Heading Filter: \(locationManager.HF)")
    Text("Distance Filter: \(locationManager.DF)")
    Text("Battery Level: \(batteryManager.batteryLevel * 100, specifier: "%.0f") %")
    Text("Is charging: \(batteryManager.isCharging ? "Yes" : "No")")
    Text("Speed class: \(locationManager.currentSpeedClass)")
    Text("Speed: \(locationManager.speed, specifier: "%.3f") km/h")
    Text("Desired Accuracy: \(locationManager.manager.desiredAccuracy)")
    Text("Allows Background Location Updates: \(locationManager.manager.allowsBackgroundLocationUpdates ? "Yes" : "No")")
}
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
