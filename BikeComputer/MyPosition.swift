import MapKit
import SwiftUI

struct MyPosition: View {
    @ObservedObject var locationManager: LocationManager

    @State private var position: MapCameraPosition = .rect(
        MKMapRect(
            origin: MKMapPoint(.helsinki),
            size: MKMapSize(width: 1, height: 1)
        )
    )

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 60.17132, longitude: 24.9415),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        NavigationView {
            Map(position: $position, interactionModes: [.all]) {
                if var userPosition = locationManager.currentUserLocation {
                    Annotation("User Position", coordinate: userPosition, anchor: .bottom) {
                        Image(systemName: "smallcircle.filled.circle")
                            .foregroundColor(.yellow)
                            .font(.largeTitle)
                            .fontWeight(.black)
                    }
                }
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
                if locationManager.currentUserLocation != nil {
                    // position = .camera(MapCameraPosition(centerCoordinate: userLocation, altitude: 1000, pitch: 0, heading: 0))
                    position = .userLocation(followsHeading: true, fallback: .rect(rect))
                } else {
                    // Käytä oletusarvoa tai odota sijainnin päivitystä
                    position = .camera(.init(centerCoordinate: .helsinki, distance: 1000))
                }
            }
        }
    }
}

extension CLLocationCoordinate2D {
    static let newYork: Self = .init(
        latitude: 40.730610,
        longitude: -73.935242
    )

    static let seattle: Self = .init(
        latitude: 47.608013,
        longitude: -122.335167
    )

    static let sanFrancisco: Self = .init(
        latitude: 37.733795,
        longitude: -122.446747
    )
    static let helsinki: Self = .init(
        latitude: 60.17132, longitude: 24.9415
    )
}

let rect = MKMapRect(
    origin: MKMapPoint(.helsinki),
    size: MKMapSize(width: 1, height: 1)
)
