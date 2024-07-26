import SwiftUI
import CoreLocation
import MapKit

struct RoutesView: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var selectedRoute: Route? // Sitova muuttuja valitulle reitille
    @State private var selectedMapType: MapStyle = .imagery(elevation: .realistic)
    @Environment(\.colorScheme) var colorScheme

    private func printRoute() {
        print(locationManager.routeManager.routes)
    }

    private func calculateTotalDistance(for route: Route) -> Double {
        var totalDistance = 0.0
        if route.points.count > 1 {
            for i in 1..<route.points.count {
                let previousPoint = route.points[i - 1]
                let currentPoint = route.points[i]
                totalDistance += calculateDistance(from: previousPoint, to: currentPoint)
            }
        }
        return totalDistance
    }
    
    private func calculateDistance(from start: RoutePoint, to end: RoutePoint) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation)
    }
    
    private func calculateAverageSpeed(for route: Route) -> Double {
        guard let endDate = route.endDate else { return 0.0 }
        let totalTime = endDate.timeIntervalSince(route.startDate)
        let totalDistance = calculateTotalDistance(for: route)
        return totalDistance / totalTime * 3.6 // Convert to km/h
    }
    
    private func formattedDateString(from date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(locationManager.routeManager.routes.sorted(by: { $0.startDate > $1.startDate })) { route in
                        Button(action: {
                            selectedRoute = route
                        }) {
                            HStack(spacing: 0) {
                                VStack(alignment: .leading) {
                                    Text(route.name)
                                        .font(.headline)
                                    Text("Distance: \(calculateTotalDistance(for: route) / 1000, specifier: "%.2f") km")
                                        .font(.subheadline)
                                    Text("Average Speed: \(calculateAverageSpeed(for: route), specifier: "%.2f") km/h")
                                        .font(.subheadline)
                                    Text("End Time: \(formattedDateString(from: route.endDate))")
                                        .font(.subheadline)
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
                    printRoute()
                }
                
            }
            .navigationTitle("Routes Information")
            .toolbarBackground(colorScheme == .dark ? Color.black: Color.white)
        }
    }
    
    func deleteRoute(offsets: IndexSet) {
        for index in offsets {
            let route = locationManager.routeManager.routes[index]
            locationManager.routeManager.deleteRoute(route: route)
        }
    }
}

#Preview {
    RoutesView(locationManager: PreviewLocationManager(), selectedRoute: .constant(nil))
}
