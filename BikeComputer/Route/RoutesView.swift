import SwiftUI
import CoreLocation
import MapKit

struct RoutesView: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var selectedRoute: Route? // Sitova muuttuja valitulle reitille
    @State private var selectedMapType: MapStyle = .hybrid(elevation: .flat)
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("unitPreference") private var unitPreference: Int = 0 // 0 for km/h and meters, 1 for mph and miles

    #if DEBUG
    private func printRoute() {
        print(locationManager.routeManager.routes)
    }
    #endif
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(locationManager.routeManager.routes.sorted(by: { $0.startDate > $1.startDate })) { route in
                        Button(action: {
                            selectedRoute = route
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(route.name)
                                        .font(.body)
                                    HStack {
                                        if unitPreference == 1 {
                                            Image(systemName: "map")
                                            Text("\(calculateTotalDistance(for: route) / 1609.34, specifier: "%.2f") mi")
                                            Image(systemName: "gauge")
                                            Text("\(calculateAverageSpeed(for: route) / 1.60934, specifier: "%.1f") mph")
                                            Image(systemName: "stopwatch")
                                            Text("\(formattedElapsedTime(for: route))")
                                        } else {
                                            Image(systemName: "map")
                                            Text("\(calculateTotalDistance(for: route) / 1000, specifier: "%.2f") km")
                                            Image(systemName: "gauge")
                                            Text("\(calculateAverageSpeed(for: route), specifier: "%.1f") km/h")
                                            Image(systemName: "stopwatch")
                                            Text("\(formattedElapsedTime(for: route))")
                                        }
                                            
                                    }.font(.caption2)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete(perform: deleteRoute)
                }
                .refreshable {
                    locationManager.routeManager.loadRoutes()
                    #if DEBUG
                    // printRoute()
                    #endif
                }
                .listStyle(GroupedListStyle())
                
            }
            .navigationTitle("Routes Information")
            .toolbarBackground(colorScheme == .dark ? Color.black : Color.white)
        }
    }
    
    func deleteRoute(offsets: IndexSet) {
        for index in offsets {
            let sortedRoutes = locationManager.routeManager.routes.sorted(by: { $0.startDate > $1.startDate })
            let route = sortedRoutes[index]
            locationManager.routeManager.deleteRoute(route: route)
        }
    }
}

#Preview {
    RoutesView(locationManager: PreviewLocationManager(), selectedRoute: .constant(nil))
}
