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
    @Environment(\.colorScheme) var colorScheme

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
                
                MyPosition(locationManager: locationManager)
                    .tabItem {
                        Image(systemName: "paperplane.fill")
                        Text("Position")
                    }


                SettingsView(locationManager: locationManager)
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
            }
            .background(colorScheme == .dark ? Color.black: Color.white)
            .accentColor(colorScheme == .dark ? Color.white: Color.black)
            .onAppear {
                UITabBar.appearance().unselectedItemTintColor = UIColor.gray
            }
            .toolbarBackground(colorScheme == .dark ? Color.black: Color.white)


            if let route = selectedRoute {
                NavigationView {
                    FullScreenRouteMapView(route: route, mapType: .imagery(elevation: .realistic),  selectedRoute: $selectedRoute)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarHidden(true)
                        .ignoresSafeArea(edges: .all)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .transition(.move(edge: .bottom))
                .background(colorScheme == .dark ? Color.black: Color.white)
                .foregroundColor(colorScheme == .dark ? Color.white: Color.black)
                .zIndex(1)
            }
        }
    }
}

#Preview {
    ContentView(locationManager: PreviewLocationManager())
}
