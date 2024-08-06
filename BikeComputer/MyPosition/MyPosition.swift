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
#if DEBUG
            print("\(userLocation)")
#endif
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


