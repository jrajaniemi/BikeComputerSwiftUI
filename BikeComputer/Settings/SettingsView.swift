import SwiftUI

struct SettingsView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var batteryManager = BatteryManager.shared
    @AppStorage("selectedColorScheme") private var selectedColorScheme: Int = 0
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
                        Text("System Default").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
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
