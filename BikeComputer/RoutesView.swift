import SwiftUI

struct RoutesView: View {
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        VStack {
            Text("Route Information")
                .font(.title)
                .padding()
            
            List {
                ForEach(locationManager.routeManager.routes) { route in
                    VStack(alignment: .leading) {
                        Text(route.name)
                            .font(.headline)
                        Text(route.description)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}
