import SwiftUI

struct SettingsView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var batteryManager = BatteryManager.shared

    var body: some View {
        NavigationView {
            
            Form {
                Section(header: Text("General")) {
                    Toggle("Option 1", isOn: .constant(true))
                    Toggle("Option 2", isOn: .constant(false))
                }
                
                Section(header: Text("About")) {
                    Text("Version 1.0")
                }
                
                Section(header: Text("Parameters")) {
                    Text("Heading Filter: \(locationManager.HF)")
                    Text("Distance Filter: \(locationManager.DF)")
                    Text("Battery Level: \(batteryManager.batteryLevel * 100, specifier: "%.0f") %")
                    Text("Is charging: \(batteryManager.isCharging ? "Yes" : "No")")
                    Text("Speed class: \(locationManager.currentSpeedClass)")
                    Text("Speed: \(locationManager.speed) km/h")
                }
            }
            .navigationTitle("Settings")
        }
        
    }
}
