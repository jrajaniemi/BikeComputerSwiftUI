import Foundation
import SwiftUI
import MapKit

struct MapButtons: View {
    @Binding var searchResults: [MKMapItem]
    var lastPoint: CLLocationCoordinate2D
    @Binding var selectedRoute: Route?
    @Binding var position: MapCameraPosition
    @StateObject private var calculator = SunriseSunsetCalculator()
    @StateObject private var themeManager = ThemeManager.shared
    
    func search(for query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(center: lastPoint, span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125))
        
        Task {
            let search = MKLocalSearch(request: request)
            let response = try? await search.start()
            searchResults = response?.mapItems ?? []
        }
    }
    
    var body: some View {
        HStack(spacing: 40) {
            Button {
                selectedRoute = nil // Sulkee karttanäkymän
            } label: {
                Label("Back", systemImage: "arrow.backward.circle.fill")
                    .font(.title)
                    .foregroundColor(Color.themeForeground)
            }
            .buttonStyle(.bordered)
            
            Button {
                position = .userLocation(followsHeading: true, fallback: .automatic)
            }  label: {
                Label("User Location", systemImage: "location")
                    .font(.title)
            }
            .buttonStyle(.bordered)
            .foregroundColor(Color.themeForeground)

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
