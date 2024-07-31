import SwiftUI
import MapKit
import Accelerate

struct RouteMapView: View {
    var route: Route
    var mapType: MapStyle = .imagery(elevation: .realistic)

    @Binding var selectedRoute: Route?
    @State private var searchResults: [MKMapItem] = []
    @State private var position: MapCameraPosition = .automatic

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let gradient = Gradient(colors: [.green, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .red])
        let stroke = StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
        
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
                .annotationTitles(.automatic)
            }
            
            if let selectedRoute = selectedRoute {
                let coordinates = selectedRoute.polyline.coordinates

                MapPolyline(coordinates: coordinates, contourStyle: MapPolyline.ContourStyle.geodesic)
                    .stroke(gradient, style: stroke)
                    
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

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}




