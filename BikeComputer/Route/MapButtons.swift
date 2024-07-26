import Foundation
import SwiftUI
import MapKit

struct MapButtons: View {
    @Binding var searchResults: [MKMapItem]
    var lastPoint: CLLocationCoordinate2D
    @Binding var selectedRoute: Route?
    @Binding var position: MapCameraPosition
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 40) {
            Button {
                selectedRoute = nil // Sulkee karttanäkymän
            } label: {
                Label("Back", systemImage: "arrow.backward.circle.fill")
                    .font(.title)
                    .foregroundColor(Color.white)
            }
            .buttonStyle(.bordered)
            
            Button {
                position = .userLocation(followsHeading: true, fallback: .automatic)
            }  label: {
                Label("User Location", systemImage: "location")
                    .font(.title)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.white)

        }
        .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)

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
    
    static var previews: some View {
        MapButtons(searchResults: $searchResults, lastPoint: CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384), selectedRoute: .constant(nil), position: $position)
    }
}
