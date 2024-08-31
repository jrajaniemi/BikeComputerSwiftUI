import Foundation
import MapKit
import SwiftUI

struct MapButtons: View {
    @Binding var searchResults: [MKMapItem]
    var lastPoint: CLLocationCoordinate2D
    @Binding var selectedRoute: Route?
    @Binding var position: MapCameraPosition
    @Binding var backgroundImage: UIImage? // New binding for background image
    @Binding var showImagePicker: Bool // New binding to show image picker
    @Environment(\.colorScheme) var colorScheme
    let startSimulation: () -> Void
    let takeScreenshot: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Button {
                selectedRoute = nil // Sulkee karttanäkymän
            } label: {
                Label("Back", systemImage: "arrow.backward.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color.white)
            }
            .buttonStyle(.bordered)

            Button {
                position = .userLocation(followsHeading: true, fallback: .automatic)
            } label: {
                Label("User Location", systemImage: "location")
                    .font(.title3)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.white)
            /*
            Button {
                startSimulation()
            } label: {
                Label("Simulator", systemImage: "play.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.white)
             */
            
            Button {
                takeScreenshot()
            } label: {
                Label("Screenshot", systemImage: "camera.viewfinder")
                    .font(.title3)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.white)
            
            Button {
                showImagePicker = true // Show image picker
            } label: {
                Label("Select Image", systemImage: "photo.fill")
                    .font(.title3)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.white)
        }
        .padding(/*@START_MENU_TOKEN@*/ .all/*@END_MENU_TOKEN@*/)
        .labelStyle(.iconOnly)
        .background(VisualEffectBlur(blurStyle: .systemMaterialDark))
        .cornerRadius(20)
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct MapButtons_Previews: PreviewProvider {
    @State static var searchResults: [MKMapItem] = []
    @State static var position: MapCameraPosition = .automatic
    @State static var backgroundImage: UIImage? = nil // Add state for background image
    @State static var showImagePicker = false // Add state for image picker visibility

    static var previews: some View {
        MapButtons(
            searchResults: $searchResults,
            lastPoint: CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384),
            selectedRoute: .constant(nil),
            position: $position,
            backgroundImage: $backgroundImage, // Provide binding for background image
            showImagePicker: $showImagePicker, // Provide binding for image picker visibility
            startSimulation: {},
            takeScreenshot: {}
        )
    }
}
