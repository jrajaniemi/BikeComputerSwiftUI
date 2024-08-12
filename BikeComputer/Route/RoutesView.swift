import CoreLocation
import MapKit
import SwiftUI

struct RoutesView: View {
    @ObservedObject var locationManager: LocationManager

    @Binding var selectedRoute: Route?

    @Environment(\.colorScheme) var colorScheme

    @AppStorage("unitPreference") private var unitPreference: Int = 0

    @State private var editingRouteID: UUID?
    @State private var editMode = false
    @State private var showEditForm = false
    @State private var routeToEdit: Route?

    var body: some View {
        NavigationStack {
            routeListView
                .refreshable {
                    locationManager.routeManager.loadRoutes()
                }
                .listStyle(GroupedListStyle())
                .navigationTitle("Routes Information")
                .toolbarBackground(colorScheme == .dark ? Color.black : Color.white)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if editMode == false {
                            Button("Edit") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    editMode = true
                                }
                            }
                        } else {
                            Button("Done") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    editMode = false
                                }
                            }
                        }
                    }
                }
                .sheet(isPresented: $showEditForm) {
                    if let route = routeToEdit {
                        RouteEditForm(locationManager: locationManager, route: route, onSave: {
                            showEditForm = false
                        })
                    }
                }
        }
    }

    private var routeListView: some View {
        List {
            ForEach(locationManager.routeManager.routes.sorted(by: { $0.startDate > $1.startDate })) { route in
                RouteRowView(route: route)
            }
            .onDelete(perform: deleteRoute)
        }
    }

    private func RouteRowView(route: Route) -> some View {
        Group {
            Button(action: {
                selectedRoute = route
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(route.name)
                            .font(.body)
                        routeDetailsView(route: route)
                            .font(.caption2)
                    }
                    Spacer()

                    if editMode == true {
                        Button(action: {
                            routeToEdit = route
                            showEditForm = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        }
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    private func routeDetailsView(route: Route) -> some View {
        HStack {
            if unitPreference == 1 {
                Image(systemName: "map")
                Text("\(calculateTotalDistance(for: route) / 1609.34, specifier: "%.2f") mi")
                Image(systemName: "gauge")
                Text("\(calculateAverageSpeed(for: route) / 1.60934, specifier: "%.1f") mph")
                Image(systemName: "stopwatch")
                Text("\(formattedElapsedTime(for: route))")
            } else {
                Image(systemName: "map")
                Text("\(calculateTotalDistance(for: route) / 1000, specifier: "%.2f") km")
                Image(systemName: "gauge")
                Text("\(calculateAverageSpeed(for: route), specifier: "%.1f") km/h")
                Image(systemName: "stopwatch")
                Text("\(formattedElapsedTime(for: route))")
            }
        }
    }

    func deleteRoute(offsets: IndexSet) {
        for index in offsets {
            let sortedRoutes = locationManager.routeManager.routes.sorted(by: { $0.startDate > $1.startDate })
            let route = sortedRoutes[index]
            locationManager.routeManager.deleteRoute(route: route)
        }
    }

    func updateRouteName(for route: Route, with newName: String) {
        if let index = locationManager.routeManager.routes.firstIndex(where: { $0.id == route.id }) {
            locationManager.routeManager.routes[index].name = newName
            locationManager.routeManager.saveCurrentRoute()
        }
    }
}

struct RouteEditForm: View {
    @ObservedObject var locationManager: LocationManager

    @State var route: Route

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedActivity: TrackableWorkoutActivityType = .other

    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Route Details")) {
                    VStack(alignment: .leading) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Route Name", text: $route.name)
                    }
                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextEditor(text: $route.description)
                            .frame(height: 150) // Määritetään korkeus
                            .border(Color.gray, width: 1) // Reuna korostaa kenttää
                            .padding(.top, -8) // Vähennetään ylimääräinen tila
                    }

                    Picker("Activity Type", selection: $selectedActivity) {
                        ForEach(TrackableWorkoutActivityType.allCases, id: \.self) { activity in
                            Text(activity.activityName).tag(activity)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
            }
            .navigationTitle("Edit Route")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // route.activityType = selectedActivity.activity
                        locationManager.routeManager.updateRoute(route)
                        onSave()
                    }
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                }
            }
        }
    }
}

#Preview {
    RoutesView(locationManager: PreviewLocationManager(), selectedRoute: .constant(nil))
}
