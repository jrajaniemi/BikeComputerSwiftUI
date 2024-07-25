import Foundation
import MapKit
import SwiftUI

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xff0000) >> 16)/255.0
        let green = Double((rgbValue & 0x00ff00) >> 8)/255.0
        let blue = Double(rgbValue & 0x0000ff)/255.0

        self.init(red: red, green: green, blue: blue)
    }
}

// Laajennetaan CLLocationCoordinate2D käyttökelpoiseksi RouteMapView:ssa
extension CLLocationCoordinate2D {
    static func startPoint(from route: Route) -> CLLocationCoordinate2D? {
        guard let firstPoint = route.points.first else { return nil }
        return CLLocationCoordinate2D(latitude: firstPoint.latitude, longitude: firstPoint.longitude)
    }

    static func endPoint(from route: Route) -> CLLocationCoordinate2D? {
        guard let lastPoint = route.points.last else { return nil }
        return CLLocationCoordinate2D(latitude: lastPoint.latitude, longitude: lastPoint.longitude)
    }
}

extension Route {
    var polyline: MKPolyline {
        let coordinates = points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
}

extension Color {
    static var themeBackground: Color {
        return ThemeManager.shared.currentTheme == .light ? Color.white : Color.black
    }

    static var themeForeground: Color {
        return ThemeManager.shared.currentTheme == .light ? Color.black : Color.white
    }

    static var themeMidGray: Color {
        return ThemeManager.shared.currentTheme == .light ? Color(red: 80/255, green: 80/255, blue: 80/255) : Color(red: 180/255, green: 180/255, blue: 180/255)
    }
}


