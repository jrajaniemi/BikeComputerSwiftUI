import MapKit
import SwiftUI
import UIKit

/// The `MyPosition` view displays the user's location on a map and shows an active route if available.
/// The map is updated in real-time to follow the user's movement and heading direction.
struct MyPosition: View {
    @ObservedObject var locationManager: LocationManager // Manages location updates and handles location data.
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    // The camera's position on the map, set to follow the user's location and heading. If user location is unavailable, the fallback is automatic.

    @AppStorage("unitPreference") private var unitPreference: Int = 0 // 0 for km/h and meters, 1 for mph and miles

    var body: some View {
        ZStack {
            // Displays the map with interaction modes (panning, zooming, etc.).
            Map(position: $position, interactionModes: [.all]) {
                // Checks if there is an active coordinates and draws it on the map if the route has more than 2 points.
                if let coordinates = locationManager.routeManager.currentRoute?.polyline.coordinates, coordinates.count > 2 {
                    MapPolyline(coordinates: coordinates, contourStyle: .geodesic)
                        .stroke(Color.yellow, lineWidth: 5) // Draws a yellow polyline on the map representing the route.
                }
            }
            .mapStyle(.standard) // Uses the standard map style.
            .mapControls {
                MapUserLocationButton() // Button to recenter the map on the user's location.
                MapCompass() // Displays a compass to show the map's orientation.
            }
            .onAppear {
                locationManager.startLocationUpdates() // Starts updating the user's location.
                updateMapCamera() // Updates the camera's position based on the user's location and heading.
            }
            .onReceive(locationManager.$currentUserLocation) { _ in
                updateMapCamera() // Updates the camera when the user's location changes.
            }
            .onReceive(locationManager.$heading) { _ in
                updateMapCamera() // Updates the camera when the user's heading changes.
            }
            
            // Overlay for the speed display
            VStack {
                HStack {
                    // Speed display
                    Text("\(formattedSpeed()) \(unitPreference == 0 ? "km/h" : "mph")")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            VisualEffectBlur(blurStyle: .systemMaterialDark)
                                .cornerRadius(10)
                        )
                        .padding([.top, .leading], 20)
                    Spacer()
                }
                Spacer()
            }
        }
    }

    /// Updates the camera's position to follow the user's current location and heading.
    private func updateMapCamera() {
        guard let userLocation = locationManager.currentUserLocation else { return }

        // Sets the camera position to the user's location and heading. If the location is unavailable, a fallback camera position is used.
        position = .userLocation(followsHeading: true, fallback: .camera(.init(
            centerCoordinate: userLocation, // Centers the camera on the user's current location.
            distance: 1000, // Sets the zoom level to a 1000-meter distance from the user.
            heading: locationManager.heading, // Adjusts the map based on the user's heading (direction).
            pitch: 45.0 // Sets the camera's pitch (tilt angle) to 45 degrees.
        )))
    }
    
    /// Formats the speed value based on the selected unit preference.
    private func formattedSpeed() -> String {
        let speed = unitPreference == 0 ? locationManager.speed : locationManager.imperialSpeed
        return String(format: "%.1f", speed)
    }
}


/*
 
 import MapKit
import SwiftUI

struct MyPosition: View {
    @ObservedObject var locationManager: LocationManager

    /*
     @State private var position: MapCameraPosition = .rect(
         MKMapRect(
             origin: MKMapPoint(.helsinki),
             size: MKMapSize(width: 1, height: 1)
         )
     )

      init(locationManager: LocationManager) {
             self.locationManager = locationManager
             self._position = State(initialValue: .rect(
                 MKMapRect(
                     origin: MKMapPoint(
                         x: locationManager.latitude,
                         y: locationManager.longitude
                     ),
                     size: MKMapSize(width: 0.5, height: 0.5)
                 )
             ))
         }
     */

    @State private var position: MapCameraPosition

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        self._position = State(initialValue: .camera(.init(
            centerCoordinate: CLLocationCoordinate2D(
                latitude: locationManager.latitude,
                longitude: locationManager.longitude
            ),
            distance: 2000,
            heading: locationManager.heading,
            pitch: 45.0
        )))
    }

    var body: some View {
        NavigationStack {
            Map(position: $position, interactionModes: [.all]) {
                /*
                 if let userPosition = locationManager.currentUserLocation {
                     Annotation("User Position", coordinate: userPosition, anchor: .center) {
                         ZStack {
                             Circle()
                                 .fill(Color.blue) // Set the circle's fill color
                                 .opacity(0.4) // Make the circle semi-transparent
                                 .frame(width: 60, height: 60) // Set the size of the circle
                             Circle()
                                 .fill(Color.blue) // Set the circle's fill color
                                 .opacity(0.6) // Make the circle semi-transparent
                                 .frame(width: 30, height: 30) // Set the size of the circle
                             Circle()
                                 .fill(Color.white) // Set the circle's fill color
                                 .opacity(1) // Make the circle semi-transparent
                                 .frame(width: 15, height: 15) // Set the size of the circle
                         }
                     }
                 }
                 */
            }
            .mapStyle(
                .hybrid(
                    elevation: .realistic,
                    showsTraffic: true
                )
            )
            .mapControls {
                MapScaleView()
                MapCompass()
                MapUserLocationButton()
                MapPitchToggle()
            }
            .controlSize(.large)
            .onAppear {
                updatePositionToUserLocation()
            }
            .onChange(of: position) {
                updatePositionToUserLocation()
            }
        }
    }

    private func updatePositionToUserLocation() {
        if let userLocation = locationManager.currentUserLocation {
            position = .userLocation(followsHeading: true, fallback: position)
            debugPrint(msg: "\(userLocation)")
        }
    }
}

let rect = MKMapRect(
    origin: MKMapPoint(.helsinki),
    size: MKMapSize(width: 1, height: 1)
)

extension CLLocationCoordinate2D {
    static let helsinki: Self = .init(
        latitude: 60.17132, longitude: 24.9415
    )
}

*/
