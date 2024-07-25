import CoreLocation
import MapKit
import SwiftUI

struct RouteMapView: View {
    
    var route: Route
    var mapType: MapStyle = .imagery(elevation: .realistic)

    @Binding var selectedRoute: Route?
    @State private var searchResults: [MKMapItem] = []
    @State private var position: MapCameraPosition = .automatic

    @StateObject private var calculator = SunriseSunsetCalculator()
    @StateObject private var themeManager = ThemeManager.shared

    

    var body: some View {
        
        Map(position: $position, interactionModes: .all) {
            if let startPoint = CLLocationCoordinate2D.startPoint(from: route) {
                Annotation("Start point", coordinate: startPoint, anchor: .bottom) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.themeBackground)
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.themeForeground, lineWidth: 5)
                        Image(systemName: "bicycle.circle")
                            .padding(5)
                    }
                }
                .annotationTitles(.hidden)
            }
            if let endPoint = CLLocationCoordinate2D.endPoint(from: route) {
                Annotation("End point", coordinate: endPoint, anchor: .bottom) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.themeBackground)
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.themeForeground, lineWidth: 5)
                        Image(systemName: "bicycle.circle.fill")
                            .padding(5)
                    }
                }
                .annotationTitles(.hidden)

                ForEach(searchResults, id: \.self) { result in
                    Marker(item: result)
                }

                if let selectedRoute = selectedRoute {
                    MapPolyline(selectedRoute.polyline)
                        .stroke(Color.themeBackground, lineWidth: 5)
                }
            }
        }
        .mapStyle(mapType)
        .mapControls {
            VStack {
                Spacer()
                MapUserLocationButton()
                Spacer()
                MapCompass()
                Spacer()
                MapScaleView()
            }
        }
        .ignoresSafeArea(edges: .all)
        .safeAreaInset(edge: .bottom) {
            if let endPoint = CLLocationCoordinate2D.endPoint(from: route) {
                HStack {
                    Spacer()
                    MapButtons(searchResults: $searchResults, lastPoint: endPoint, selectedRoute: $selectedRoute, position: $position)
                        .padding(.vertical)
                    Spacer()
                }
            }
        }
        .onChange(of: searchResults) {
            position = .automatic
        }
    }
}

struct FullScreenRouteMapView: View {
    var route: Route
    var mapType: MapStyle = .imagery(elevation: .realistic)

    @Binding var selectedRoute: Route? // Sitova muuttuja karttanäkymän sulkemiseen

    var body: some View {
        NavigationView {
            RouteMapView(route: route, mapType: mapType, selectedRoute: $selectedRoute)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(false)
                .ignoresSafeArea(edges: .all)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .ignoresSafeArea(edges: .all)
    }
}

// Esimerkki RouteMapView:n käytöstä
struct RouteMapView_Previews: PreviewProvider {
    static var previews: some View {
        RouteMapView(
            route: Route(
                name: "NYC Cycling Route",
                description: "A 30-minute cycling route in New York City.",
                startDate: Date(),
                endDate: nil,
                points: [
                    RoutePoint(speed: 15, heading: 90, altitude: 10, longitude: -73.985428, latitude: 40.748817, timestamp: Date()), // Start at Empire State Building
                    RoutePoint(speed: 15, heading: 100, altitude: 12, longitude: -73.980742, latitude: 40.753182, timestamp: Date().addingTimeInterval(300)), // Towards Bryant Park
                    RoutePoint(speed: 15, heading: 110, altitude: 15, longitude: -73.974187, latitude: 40.759011, timestamp: Date().addingTimeInterval(600)), // Times Square
                    RoutePoint(speed: 15, heading: 120, altitude: 18, longitude: -73.967708, latitude: 40.764462, timestamp: Date().addingTimeInterval(900)), // Central Park South
                    RoutePoint(speed: 15, heading: 130, altitude: 20, longitude: -73.961704, latitude: 40.768094, timestamp: Date().addingTimeInterval(1200)), // East 72nd Street Entrance to Central Park
                    RoutePoint(speed: 15, heading: 140, altitude: 22, longitude: -73.956608, latitude: 40.771133, timestamp: Date().addingTimeInterval(1500)), // Central Park East Side
                    RoutePoint(speed: 15, heading: 150, altitude: 25, longitude: -73.949874, latitude: 40.774726, timestamp: Date().addingTimeInterval(1800)) // End at The Metropolitan Museum of Art
                ]
            ),
            selectedRoute: .constant(nil)
        )
    }
}
