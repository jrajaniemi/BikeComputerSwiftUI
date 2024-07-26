import CoreLocation
import MapKit
import SwiftUI

struct RouteMapView: View {
    var route: Route
    var mapType: MapStyle = .imagery(elevation: .realistic)

    @Binding var selectedRoute: Route?
    @State private var searchResults: [MKMapItem] = []
    @State private var position: MapCameraPosition = .automatic

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Map(position: $position, interactionModes: .all) {
            if let startPoint = CLLocationCoordinate2D.startPoint(from: route) {
                Annotation("Start point", coordinate: startPoint, anchor: .bottom) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(colorScheme == .dark ? Color.black : Color.white)
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 5)
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
                            .fill(colorScheme == .dark ? Color.black : Color.white)
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 5)
                        Image(systemName: "bicycle.circle.fill")
                            .padding(5)
                    }
                }
                .annotationTitles(.hidden)

                ForEach(searchResults, id: \.self) { result in
                    Marker(item: result)
                }

                if let selectedRoute = selectedRoute {
                    let smoothedPoints = CLLocationCoordinate2D.smoothPath(points: selectedRoute.points.coordinates())

                    MapPolyline(coordinates: smoothedPoints)
                        .stroke(colorScheme == .dark ? Color(hex: "#ff9d1e") : Color(hex: "#ffc375"), lineWidth: 6)
                }
            }
        }
        .mapStyle(mapType)
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
                .navigationBarHidden(true)
                .ignoresSafeArea(edges: .all)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .ignoresSafeArea(edges: .all)
    }
}

struct RouteMapView_Previews: PreviewProvider {
    static var previews: some View {
        RouteMapView(
            route: Route(
                name: "Central Park Running",
                description: "Central Park Running Map Main Loop 6.1 Miles",
                startDate: Date(),
                endDate: nil,
                points: [
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97992, latitude: 40.76921, timestamp: Date().addingTimeInterval(5400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97824, latitude: 40.7675, timestamp: Date().addingTimeInterval(11400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97633, latitude: 40.76743, timestamp: Date().addingTimeInterval(17400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97505, latitude: 40.76936, timestamp: Date().addingTimeInterval(23400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97366, latitude: 40.76983, timestamp: Date().addingTimeInterval(29400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97135, latitude: 40.77, timestamp: Date().addingTimeInterval(35400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97043, latitude: 40.77116, timestamp: Date().addingTimeInterval(41400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96896, latitude: 40.77242, timestamp: Date().addingTimeInterval(47400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96912, latitude: 40.77362, timestamp: Date().addingTimeInterval(53400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96851, latitude: 40.77486, timestamp: Date().addingTimeInterval(59400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96726, latitude: 40.77569, timestamp: Date().addingTimeInterval(65400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96644, latitude: 40.77826, timestamp: Date().addingTimeInterval(71400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96478, latitude: 40.78002, timestamp: Date().addingTimeInterval(77400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96256, latitude: 40.78162, timestamp: Date().addingTimeInterval(83400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96071, latitude: 40.78177, timestamp: Date().addingTimeInterval(89400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95705, latitude: 40.78683, timestamp: Date().addingTimeInterval(95400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95706, latitude: 40.7876, timestamp: Date().addingTimeInterval(101400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95692, latitude: 40.78814, timestamp: Date().addingTimeInterval(107400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95705, latitude: 40.78895, timestamp: Date().addingTimeInterval(113400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95627, latitude: 40.79117, timestamp: Date().addingTimeInterval(119400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95505, latitude: 40.79286, timestamp: Date().addingTimeInterval(125400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95453, latitude: 40.79467, timestamp: Date().addingTimeInterval(131400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95333, latitude: 40.79551, timestamp: Date().addingTimeInterval(137400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95368, latitude: 40.79597, timestamp: Date().addingTimeInterval(143400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95501, latitude: 40.79557, timestamp: Date().addingTimeInterval(149400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95571, latitude: 40.79588, timestamp: Date().addingTimeInterval(155400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95499, latitude: 40.79677, timestamp: Date().addingTimeInterval(161400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.9543, latitude: 40.79815, timestamp: Date().addingTimeInterval(167400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95629, latitude: 40.79935, timestamp: Date().addingTimeInterval(173400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95824, latitude: 40.79937, timestamp: Date().addingTimeInterval(179400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95843, latitude: 40.79852, timestamp: Date().addingTimeInterval(185400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95729, latitude: 40.7981, timestamp: Date().addingTimeInterval(191400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95703, latitude: 40.79756, timestamp: Date().addingTimeInterval(197400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95686, latitude: 40.79686, timestamp: Date().addingTimeInterval(203400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95704, latitude: 40.79602, timestamp: Date().addingTimeInterval(209400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.9586, latitude: 40.79529, timestamp: Date().addingTimeInterval(215400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95972, latitude: 40.79412, timestamp: Date().addingTimeInterval(221400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96287, latitude: 40.79129, timestamp: Date().addingTimeInterval(227400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96422, latitude: 40.79014, timestamp: Date().addingTimeInterval(233400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.9644, latitude: 40.78901, timestamp: Date().addingTimeInterval(239400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96592, latitude: 40.78842, timestamp: Date().addingTimeInterval(245400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96722, latitude: 40.78734, timestamp: Date().addingTimeInterval(251400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96754, latitude: 40.78624, timestamp: Date().addingTimeInterval(257400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96716, latitude: 40.78459, timestamp: Date().addingTimeInterval(263400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96884, latitude: 40.78307, timestamp: Date().addingTimeInterval(269400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96943, latitude: 40.78209, timestamp: Date().addingTimeInterval(275400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96953, latitude: 40.78108, timestamp: Date().addingTimeInterval(281400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97167, latitude: 40.77938, timestamp: Date().addingTimeInterval(287400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97402, latitude: 40.77755, timestamp: Date().addingTimeInterval(293400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97402, latitude: 40.77542, timestamp: Date().addingTimeInterval(299400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97453, latitude: 40.77479, timestamp: Date().addingTimeInterval(305400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.9763, latitude: 40.7734, timestamp: Date().addingTimeInterval(311400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97709, latitude: 40.77159, timestamp: Date().addingTimeInterval(317400.0)),

                ]
            ),
            
            selectedRoute: .constant(Route(
                name: "Central Park Running",
                description: "Central Park Running Map Main Loop 6.1 Miles",
                startDate: Date(),
                endDate: nil,
                points: [
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97992, latitude: 40.76921, timestamp: Date().addingTimeInterval(5400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97824, latitude: 40.7675, timestamp: Date().addingTimeInterval(11400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97633, latitude: 40.76743, timestamp: Date().addingTimeInterval(17400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97505, latitude: 40.76936, timestamp: Date().addingTimeInterval(23400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97366, latitude: 40.76983, timestamp: Date().addingTimeInterval(29400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97135, latitude: 40.77, timestamp: Date().addingTimeInterval(35400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97043, latitude: 40.77116, timestamp: Date().addingTimeInterval(41400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96896, latitude: 40.77242, timestamp: Date().addingTimeInterval(47400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96912, latitude: 40.77362, timestamp: Date().addingTimeInterval(53400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96851, latitude: 40.77486, timestamp: Date().addingTimeInterval(59400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96726, latitude: 40.77569, timestamp: Date().addingTimeInterval(65400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96644, latitude: 40.77826, timestamp: Date().addingTimeInterval(71400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96478, latitude: 40.78002, timestamp: Date().addingTimeInterval(77400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96256, latitude: 40.78162, timestamp: Date().addingTimeInterval(83400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96071, latitude: 40.78177, timestamp: Date().addingTimeInterval(89400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95705, latitude: 40.78683, timestamp: Date().addingTimeInterval(95400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95706, latitude: 40.7876, timestamp: Date().addingTimeInterval(101400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95692, latitude: 40.78814, timestamp: Date().addingTimeInterval(107400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95705, latitude: 40.78895, timestamp: Date().addingTimeInterval(113400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95627, latitude: 40.79117, timestamp: Date().addingTimeInterval(119400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95505, latitude: 40.79286, timestamp: Date().addingTimeInterval(125400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95453, latitude: 40.79467, timestamp: Date().addingTimeInterval(131400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95333, latitude: 40.79551, timestamp: Date().addingTimeInterval(137400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95368, latitude: 40.79597, timestamp: Date().addingTimeInterval(143400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95501, latitude: 40.79557, timestamp: Date().addingTimeInterval(149400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95571, latitude: 40.79588, timestamp: Date().addingTimeInterval(155400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95499, latitude: 40.79677, timestamp: Date().addingTimeInterval(161400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.9543, latitude: 40.79815, timestamp: Date().addingTimeInterval(167400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95629, latitude: 40.79935, timestamp: Date().addingTimeInterval(173400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95824, latitude: 40.79937, timestamp: Date().addingTimeInterval(179400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95843, latitude: 40.79852, timestamp: Date().addingTimeInterval(185400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95729, latitude: 40.7981, timestamp: Date().addingTimeInterval(191400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95703, latitude: 40.79756, timestamp: Date().addingTimeInterval(197400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95686, latitude: 40.79686, timestamp: Date().addingTimeInterval(203400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95704, latitude: 40.79602, timestamp: Date().addingTimeInterval(209400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.9586, latitude: 40.79529, timestamp: Date().addingTimeInterval(215400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.95972, latitude: 40.79412, timestamp: Date().addingTimeInterval(221400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96287, latitude: 40.79129, timestamp: Date().addingTimeInterval(227400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96422, latitude: 40.79014, timestamp: Date().addingTimeInterval(233400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.9644, latitude: 40.78901, timestamp: Date().addingTimeInterval(239400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96592, latitude: 40.78842, timestamp: Date().addingTimeInterval(245400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96722, latitude: 40.78734, timestamp: Date().addingTimeInterval(251400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96754, latitude: 40.78624, timestamp: Date().addingTimeInterval(257400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96716, latitude: 40.78459, timestamp: Date().addingTimeInterval(263400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96884, latitude: 40.78307, timestamp: Date().addingTimeInterval(269400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96943, latitude: 40.78209, timestamp: Date().addingTimeInterval(275400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.96953, latitude: 40.78108, timestamp: Date().addingTimeInterval(281400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97167, latitude: 40.77938, timestamp: Date().addingTimeInterval(287400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97402, latitude: 40.77755, timestamp: Date().addingTimeInterval(293400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97402, latitude: 40.77542, timestamp: Date().addingTimeInterval(299400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97453, latitude: 40.77479, timestamp: Date().addingTimeInterval(305400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.9763, latitude: 40.7734, timestamp: Date().addingTimeInterval(311400.0)),
                    RoutePoint(speed: 5, heading: 0, altitude: 0.0, longitude: -73.97709, latitude: 40.77159, timestamp: Date().addingTimeInterval(317400.0)),

                ]
            ))

        )
    }
}
