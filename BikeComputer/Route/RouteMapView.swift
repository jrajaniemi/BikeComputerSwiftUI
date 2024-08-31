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
    @State private var timer: Timer?
    @State private var showDetails = false
    @State private var hideMapButtons = false
    @State private var showFlash = false
    @State private var backgroundImage: UIImage? = nil
    @State private var showImagePicker = false

    @Environment(\.colorScheme) var colorScheme
    @AppStorage("unitPreference") private var unitPreference: Int = 0

    private func takeScreenshot() {
        debugPrint("takeScreenshot() pressed")
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

    private func convertCoordinatesToCanvas(points: [CLLocationCoordinate2D], size: CGSize, minLat: CLLocationDegrees, maxLat: CLLocationDegrees, minLon: CLLocationDegrees, maxLon: CLLocationDegrees, margin: CGFloat = 0.1) -> [CGPoint] {
        guard maxLat != minLat, maxLon != minLon else {
            debugPrint("Min/Max values are not valid, returning empty.")
            return []
        }

        // Laske marginaalin vaikutus Canvaksen kokoon
        let xMargin = size.width * margin
        let yMargin = size.height * margin
        let adjustedWidth = size.width - 2 * xMargin
        let adjustedHeight = size.height - 2 * yMargin

        return points.map { coordinate in
            let x = ((coordinate.longitude - minLon) / (maxLon - minLon)) * adjustedWidth + xMargin
            let y = (1 - (coordinate.latitude - minLat) / (maxLat - minLat)) * adjustedHeight + yMargin
            return CGPoint(x: x, y: y)
        }
    }

    private func createSmoothPath(points: [CGPoint]) -> Path {
        var path = Path()

        guard points.count > 1 else { return path }

        path.move(to: points[0])

        for i in 0 ..< points.count - 1 {
            let currentPoint = points[i]
            let nextPoint = points[i + 1]

            let midPoint = CGPoint(
                x: (currentPoint.x + nextPoint.x) / 2,
                y: (currentPoint.y + nextPoint.y) / 2
            )

            path.addQuadCurve(to: midPoint, control: currentPoint)
        }

        if let lastPoint = points.last {
            path.addLine(to: lastPoint)
        }

        return path
    }

    private func drawCustomIcon(in context: GraphicsContext, at point: CGPoint, size: CGSize, colorScheme: ColorScheme) {
        // Laske suorakulmio, johon kuvio piirretään
        let rect = CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height)

        // Piirrä kuvion kerrokset
        context.drawLayer { layerContext in
            // Piirrä täytetty suorakulmio
            let fillColor = colorScheme == .dark ? UIColor.black : UIColor.white
            layerContext.fill(Path(roundedRect: rect, cornerRadius: 5), with: .color(Color(fillColor)))

            // Piirrä ääriviivasuorakulmio
            let strokeColor = colorScheme == .dark ? UIColor.white : UIColor.black
            layerContext.stroke(Path(roundedRect: rect, cornerRadius: 5), with: .color(Color(strokeColor)), lineWidth: 5)

            // Piirrä kuva keskelle suorakulmiota
            if let uiImage = UIImage(systemName: "flag.circle.fill") {
                let image = Image(uiImage: uiImage)
                let imageSize = CGSize(width: size.width * 0.6, height: size.height * 0.6) // Kuva on hieman pienempi kuin suorakulmio
                let imageRect = CGRect(x: point.x - imageSize.width / 2, y: point.y - imageSize.height / 2, width: imageSize.width, height: imageSize.height)
                var resolvedImage = layerContext.resolve(image)
                resolvedImage.shading = colorScheme == .dark ? .color(.white) : .color(.black)
                layerContext.draw(resolvedImage, in: imageRect)
            }
        }
    }

    var body: some View {
        let gradient = Gradient(colors: [.green, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .red])
        let stroke = StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)

        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                if let backgroundImage = backgroundImage {
                    ZStack {
                        Image(uiImage: backgroundImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .ignoresSafeArea()

                        Canvas { context, size in
                            debugPrint(msg: "Width: \(UIScreen.main.bounds.width), height: \(UIScreen.main.bounds.height)")
                            debugPrint(msg: "Width: \(UIScreen.main.bounds.width * 0.8), height: \(UIScreen.main.bounds.height * 0.7)")
                            debugPrint(msg: "Width: \(size)")

                            if let selectedRoute = selectedRoute {
                                let coordinates = selectedRoute.polyline.coordinates
                                if coordinates.isEmpty {
                                    debugPrint("Coordinates are empty!")
                                    return
                                } else {
                                    debugPrint("Coordinates count: \(coordinates.count)")
                                }

                                // Calculate the geographical bounds of the route
                                let minLat = coordinates.map { $0.latitude }.min() ?? 0
                                let maxLat = coordinates.map { $0.latitude }.max() ?? 0
                                let minLon = coordinates.map { $0.longitude }.min() ?? 0
                                let maxLon = coordinates.map { $0.longitude }.max() ?? 0

                                // Convert the route points to canvas points with margins
                                let canvasPoints = convertCoordinatesToCanvas(points: coordinates, size: size, minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon, margin: 0.1)
                                let smoothPath = createSmoothPath(points: canvasPoints)


                                // Convert the start and end points using the same bounds with margins
                                if let startPointCoordinate = CLLocationCoordinate2D.startPoint(from: route),
                                   let endPointCoordinate = CLLocationCoordinate2D.endPoint(from: route)
                                {
                                    let startPoint = convertCoordinatesToCanvas(points: [startPointCoordinate], size: size, minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon, margin: 0.1).first
                                    
                                    let endPoint = convertCoordinatesToCanvas(points: [endPointCoordinate], size: size, minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon, margin: 0.1).first
                                    
                                    let imageSize = CGSize(width: 40, height: 40)

                                    if let startPoint = startPoint, startPoint.x >= 0, startPoint.y >= 0, startPoint.x <= size.width, startPoint.y <= size.height {
                                        drawCustomIcon(in: context, at: startPoint, size: imageSize, colorScheme: colorScheme)
                                    }

                                    if let endPoint = endPoint, endPoint.x >= 0, endPoint.y >= 0, endPoint.x <= size.width, endPoint.y <= size.height {
                                        drawCustomIcon(in: context, at: endPoint, size: imageSize, colorScheme: colorScheme)
                                    }

                                    // 1. Piirretään varjo reittiviivalle
                                    context.withCGContext { cgContext in
                                        cgContext.setShadow(offset: CGSize(width: 4, height: 4), blur: 5, color: UIColor.black.withAlphaComponent(0.3).cgColor)
                                        cgContext.addPath(smoothPath.cgPath)
                                        cgContext.setStrokeColor(UIColor.gray.cgColor)
                                        cgContext.setLineWidth(5)
                                        cgContext.strokePath()
                                    }

                                    // 2. Piirretään itse reittiviiva varjon päälle
                                    // context.stroke(smoothPath, with: .color(.orange), lineWidth: 5)
                                    context.stroke(smoothPath, with: .color(.orange), lineWidth: 5)
                                    
                                    
                                } else {
                                    debugPrint("Could not calculate startPoint or endPoint for Canvas.")
                                }
                            }
                        }
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.7)
                    }
                } else {
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
                                        .fill(Color.blue)
                                        .opacity(0.3)
                                        .frame(width: simulationPoint.speed < 40 ? 60 : 40, height: simulationPoint.speed < 20 ? 60 : 40)
                                    Circle()
                                        .fill(Color.blue)
                                        .opacity(0.5)
                                        .frame(width: 20, height: 20)
                                    Circle()
                                        .fill(Color.white)
                                        .opacity(1)
                                        .frame(width: 10, height: 10)
                                }
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
                }

                // Lisää AppIcon ZStackiin
                VStack {
                    HStack(alignment: .center) { // HStack asettaa kuvan ja tekstin samalle riville
                        if let image = UIImage(named: "AppIcon") {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                .frame(width: 50, height: 50) // Määritä kuvan koko
                                .padding(.leading, 20)
                                .padding(.top, 15)
                                .shadow(color: Color.black.opacity(0.4), radius: 5, x: 4, y: 4) // Lisää varjo kuvakkeelle
                                .onTapGesture {
                                    showDetails.toggle()
                                }
                        }

                        Text("RIDE Computer")
                            .font(.headline) // Valitse fonttikoko ja tyyli
                            .foregroundColor(.white) // Tekstin väri
                            .padding(.top, 15) // Sama marginaali kuin kuvakkeella
                            .shadow(color: Color.black.opacity(0.4), radius: 5, x: 4, y: 4) // Lisää varjo kuvakkeelle
                        Spacer() // Lisää tyhjää tilaa oikealle
                    }
                    Spacer()
                }

                // Lisätään reittitiedot
                if !showDetails {
                    VStack {
                        Spacer()
                        VStack {
                            HStack(spacing: 20) { // Lisää tilaa palstojen väliin
                                Text("Trip")
                                    .routeHeaders()
                                    .frame(maxWidth: .infinity, alignment: .center) // Keskitetään otsikot
                                Text("Speed")
                                    .routeHeaders()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Text("Time")
                                    .routeHeaders()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            HStack(spacing: 20) { // Lisää tilaa palstojen väliin
                                if unitPreference == 1 {
                                    Text("\(calculateTotalDistance(for: route) / 1609.34, specifier: "%.1f") mi")
                                        .routeDetails()
                                        .frame(maxWidth: .infinity, alignment: .center) // Keskitetään arvot
                                    Text("\(calculateAverageSpeed(for: route) / 1.60934, specifier: "%.1f") mph")
                                        .routeDetails()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    Text("\(formattedElapsedTime(for: route))")
                                        .routeDetails()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    Text("\(calculateTotalDistance(for: route) / 1000, specifier: "%.1f") km")
                                        .routeDetails()
                                        .frame(maxWidth: .infinity, alignment: .center) // Keskitetään arvot
                                    Text("\(calculateAverageSpeed(for: route), specifier: "%.1f") km/h")
                                        .routeDetails()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    Text("\(formattedElapsedTime(for: route))")
                                        .routeDetails()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                        }
                        .padding(10) // Lisää marginaalia
                        .background(colorScheme == .dark ? Color.black.opacity(0.9) : Color.white.opacity(0.9))
                    }
                    .ignoresSafeArea(edges: .bottom)
                }

                // Lisätään reittitiedot
                if showDetails {
                    VStack {
                        Spacer()
                        VStack {
                            if unitPreference == 1 {
                                Text("Trip")
                                    .routeHeaders()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(calculateTotalDistance(for: route) / 1609.34, specifier: "%.1f") mi")
                                    .routeDetails()
                                    .frame(maxWidth: .infinity, alignment: .leading) // Keskitetään arvot

                                Text("Speed")
                                    .routeHeaders()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(calculateAverageSpeed(for: route) / 1.60934, specifier: "%.1f") mph")
                                    .routeDetails()
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Time")
                                    .routeHeaders()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(formattedElapsedTime(for: route))")
                                    .routeDetails()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("Trip")
                                    .routeHeaders()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(calculateTotalDistance(for: route) / 1000, specifier: "%.1f") km")
                                    .routeDetails()
                                    .frame(maxWidth: .infinity, alignment: .leading) // Keskitetään arvot

                                Text("Speed")
                                    .routeHeaders()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(calculateAverageSpeed(for: route), specifier: "%.1f") km/h")
                                    .routeDetails()
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Time")
                                    .routeHeaders()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(formattedElapsedTime(for: route))")
                                    .routeDetails()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.bottom, 70)       // alareunan marginaali
                    .padding(.leading, 20)      // yläreunan marginaali
                    .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 0) // Lisää varjo kuvakkeelle
                }

                // MapButtons-komponentti pysyy ruudun alaosassa
                VStack {
                    Spacer()
                    HStack {
                        Spacer() // Lisää tyhjää tilaa vasemmalle, jotta HStack keskittää MapButtons-komponentin
                        if !hideMapButtons {
                            MapButtons(
                                searchResults: $searchResults,
                                lastPoint: CLLocationCoordinate2D.endPoint(from: route) ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                selectedRoute: $selectedRoute,
                                position: $position,
                                backgroundImage: $backgroundImage,
                                showImagePicker: $showImagePicker,
                                startSimulation: startSimulation,
                                takeScreenshot: takeScreenshot
                            )
                            .padding(.vertical)
                            // .transition(.move(edge: .bottom))
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
                        }
                        Spacer() // Lisää tyhjää tilaa oikealle
                    }
                }
                .ignoresSafeArea()
                .background(Color.clear) // Varmistaa, että painikkeet eivät katoa
                .padding(.bottom, showDetails ? 0 : 50)

                if showFlash {
                    Color.white
                        .edgesIgnoringSafeArea(.all)
                        .opacity(showFlash ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: showFlash)
                }
            }
            .screenshotHelper()
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $backgroundImage)
            }
        }
    }
}

// FullScreenRouteMapView ja MKPolyline-laajennukset pysyvät samoina...

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
