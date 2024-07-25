import CoreLocation
import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager: LocationManager
    @State private var isRecording: Bool = false
    @State private var routeName: String = ""
    @State private var routeDescription: String = ""
    @State private var displayLastFivePoints: Bool = false
    @State private var lastFivePoints: [RoutePoint] = []
    @State private var showRouteView: Bool = false
    @State private var selectedRoute: Route? // Uusi muuttuja valitulle reitille
    @StateObject private var calculator = SunriseSunsetCalculator()
    @StateObject private var themeManager = ThemeManager.shared
    
    init(locationManager: LocationManager = LocationManager()) {
        _locationManager = StateObject(wrappedValue: locationManager)
    }
    
    var body: some View {
        ZStack {
            TabView {
                SpeedView(locationManager: locationManager, isRecording: $isRecording, routeName: $routeName, routeDescription: $routeDescription, displayLastFivePoints: $displayLastFivePoints, lastFivePoints: $lastFivePoints, showRouteView: $showRouteView)
                    .tabItem {
                        Image(systemName: "speedometer")
                        Text("Computer")
                    }
                
                RoutesView(locationManager: locationManager, selectedRoute: $selectedRoute)
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
            .background(Color.themeBackground)
            .accentColor(Color.themeForeground)
            .onAppear {
                UITabBar.appearance().unselectedItemTintColor = UIColor.gray
            }

            if let route = selectedRoute {
                NavigationView {
                    FullScreenRouteMapView(route: route, mapType: .imagery(elevation: .realistic), selectedRoute: $selectedRoute)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarHidden(true)
                        .ignoresSafeArea(edges: .all)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .transition(.move(edge: .bottom))
                .background(Color.themeBackground)
                .foregroundColor(Color.themeForeground)
                .zIndex(1)
            }
        }
    }
}

#Preview {
    ContentView(locationManager: PreviewLocationManager())
}
