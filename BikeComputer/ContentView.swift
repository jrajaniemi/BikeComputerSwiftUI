import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager: LocationManager
    @State private var isRecording: Bool = false
    @State private var routeName: String = ""
    @State private var routeDescription: String = ""
    @State private var displayLastFivePoints: Bool = false
    @State private var lastFivePoints: [RoutePoint] = []
    @State private var showRouteView: Bool = false
    
    init(locationManager: LocationManager = LocationManager()) {
        _locationManager = StateObject(wrappedValue: locationManager)
    }
    
    var body: some View {
        TabView {
            SpeedView(locationManager: locationManager, isRecording: $isRecording, routeName: $routeName, routeDescription: $routeDescription, displayLastFivePoints: $displayLastFivePoints, lastFivePoints: $lastFivePoints, showRouteView: $showRouteView)
                .tabItem {
                    Image(systemName: "speedometer")
                    Text("Computer")
                }
            
            RoutesView(locationManager: locationManager)
                .tabItem {
                    Image(systemName: "map")
                    Text("Routes")
                }
            
            SettingsView(locationManager: locationManager)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .background(.white)
    }
}

#Preview {
    ContentView(locationManager: PreviewLocationManager())
}
