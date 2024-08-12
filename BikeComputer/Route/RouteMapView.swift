import Accelerate
import MapKit
import SwiftUI
import UIKit

struct RouteMapView: View {
    var route: Route
    var mapType: MapStyle = .hybrid(elevation: .flat)

    @Binding var selectedRoute: Route?
    @State private var searchResults: [MKMapItem] = []
    @State private var position: MapCameraPosition = .automatic
    @State private var isSimulating = false
    @State private var simulationIndex = 0
    @State private var timer: Timer? // Add a property to hold the Timer object
    @State private var showDetails = false // State to toggle the view
    @State private var hideMapButtons = false
    @State private var showFlash = false // State for the flash effect

    @Environment(\.colorScheme) var colorScheme
    @AppStorage("unitPreference") private var unitPreference: Int = 0 // 0 for km/h and meters, 1 for mph and miles

    private func takeScreenshot() {
#if DEBUG
        print("takeScreenshot() pressed")
#endif
        hideMapButtons = true
        NotificationCenter.default.post(name: Notification.Name("takeScreenshot"), object: nil)
    }

    private func startSimulation() {
        guard let points = selectedRoute?.points, points.count > 1 else { return }
        isSimulating.toggle()
        if isSimulating {
            simulationIndex = 0
            scheduleNextUpdate()
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    private func scheduleNextUpdate() {
        guard let points = selectedRoute?.points, simulationIndex < points.count else {
            isSimulating = false
            timer?.invalidate()
            timer = nil
            return
        }

        let point = points[simulationIndex]
        position = .camera(.init(centerCoordinate: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude), distance: 2000, heading: point.heading, pitch: 45.0))

        if simulationIndex < points.count - 1 {
            simulationIndex += 1
            let nextPoint = points[simulationIndex]
            let interval = nextPoint.timestamp.timeIntervalSince(point.timestamp)
            timer = Timer.scheduledTimer(withTimeInterval: interval / 4, repeats: false) { [self] _ in
                self.scheduleNextUpdate()
            }
        }
    }

    var body: some View {
        let gradient = Gradient(colors: [.green, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .red])
        let stroke = StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
        ZStack(alignment: .topLeading) {
            Map(position: $position, interactionModes: .all) {
                if let startPoint = CLLocationCoordinate2D.startPoint(from: route) {
                    Annotation("Start", coordinate: startPoint, anchor: .bottom) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(colorScheme == .dark ? Color.black : Color.white)
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 5)
                            Image(systemName: "mappin.and.ellipse")
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

                if isSimulating, simulationIndex < selectedRoute?.points.count ?? 0 {
                    let simulationPoint = selectedRoute!.points[simulationIndex]
                    Annotation("Simulation", coordinate: CLLocationCoordinate2D(latitude: simulationPoint.latitude, longitude: simulationPoint.longitude), anchor: .bottom) {
                        ZStack {
                            Circle()
                                .fill(Color.blue) // Set the circle's fill color
                                .opacity(0.3) // Make the circle semi-transparent
                                .frame(width: simulationPoint.speed < 40 ? 60 : 40, height: simulationPoint.speed < 20 ? 60 : 40) // Set the size of the circle
                            Circle()
                                .fill(Color.blue) // Set the circle's fill color
                                .opacity(0.5) // Make the circle semi-transparent
                                .frame(width: 20, height: 20) // Set the size of the circle
                            Circle()
                                .fill(Color.white) // Set the circle's fill color
                                .opacity(1) // Make the circle semi-transparent
                                .frame(width: 10, height: 10) // Set the size of the circle
                        }
                        /*
                         Image(systemName: "location.north.line.fill")
                             .foregroundColor(.yellow)
                             .font(.title2)
                             .fontWeight(.black)
                         */

                        // .rotationEffect(.degrees(simulationPoint.heading))
                    }
                    .annotationTitles(.hidden)
                }

                if let endPoint = CLLocationCoordinate2D.endPoint(from: route) {
                    Annotation("End", coordinate: endPoint, anchor: .bottom) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(colorScheme == .dark ? Color.black : Color.white)
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 5)
                            Image(systemName: "flag.circle.fill")
                                .padding(5)
                        }
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapStyle(mapType)
            // .ignoresSafeArea(edges: .all)
            .safeAreaInset(edge: .bottom) {
                if !hideMapButtons, let endPoint = CLLocationCoordinate2D.endPoint(from: route) {
                    HStack {
                        Spacer()
                        MapButtons(searchResults: $searchResults, lastPoint: endPoint, selectedRoute: $selectedRoute, position: $position, startSimulation: startSimulation, takeScreenshot: takeScreenshot)
                            .padding(.vertical)
                            .onDisappear {
                                Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { _ in
                                    NotificationCenter.default.post(name: Notification.Name("takeScreenshot"), object: nil)
                                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                        hideMapButtons = false
                                        withAnimation {
                                            showFlash = true
                                        }
                                        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                            withAnimation {
                                                showFlash = false
                                            }
                                        }
                                    }
                                }
                            }
                        Spacer()
                    }
                }
            }

            if isSimulating {
                if let currentSpeed = selectedRoute?.points[simulationIndex].speed {
                    // self.mapStyle(.standard(elevation: .automatic))
                    let speedText = unitPreference == 0 ? "km/h" : "mph"
                    Text("\(unitPreference == 0 ? currentSpeed : currentSpeed / 1.609, specifier: "%.1f") \(speedText)")
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 50)
                        .padding(.leading, 10)
                }
            } else {
                VStack {
                    HStack {
                        if unitPreference == 1 {
                            Label("\(calculateTotalDistance(for: route) / 1609.34, specifier: "%.1f") mi", systemImage: "map")
                            Label("\(calculateAverageSpeed(for: route) / 1.60934, specifier: "%.1f") mph", systemImage: "gauge")
                            Label("\(formattedElapsedTime(for: route))", systemImage: "stopwatch")
                        } else {
                            Label("\(calculateTotalDistance(for: route) / 1000, specifier: "%.1f") km", systemImage: "map")
                            Label("\(calculateAverageSpeed(for: route), specifier: "%.1f") km/h", systemImage: "gauge")
                            Label("\(formattedElapsedTime(for: route))", systemImage: "stopwatch")
                        }
                    }
                    .padding(10)
                    .routeDetails()
                    .background(colorScheme == .dark ? Color.black.opacity(0.6) : Color.white.opacity(0.65))
                    .onTapGesture {
                        showDetails.toggle()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    Spacer()
                    if hideMapButtons {
                        Text("RIDE Computer")
                            .padding(10)
                            .routeDetails()
                            .onTapGesture {
                                showDetails.toggle()
                            }
                    }
                }
                if showFlash {
                    Color.white
                        .edgesIgnoringSafeArea(.all)
                        .opacity(showFlash ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: showFlash)
                }
            }
        }
        .screenshotHelper()
    }
}

struct FullScreenRouteMapView: View {
    var route: Route
    var mapType: MapStyle = .hybrid(elevation: .realistic)

    @Binding var selectedRoute: Route? // Sitova muuttuja karttanäkymän sulkemiseen

    var body: some View {
        NavigationStack {
            RouteMapView(route: route, mapType: mapType, selectedRoute: $selectedRoute)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(true)
        }
    }
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
