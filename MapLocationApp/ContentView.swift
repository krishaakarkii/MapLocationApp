import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 61.4978, longitude: 23.7610), // Tampere, Finland as default
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var locations: [SavedLocation] = []
    @State private var showingAddLocation = false
    @State private var newLocationName = ""
    @State private var tappedCoordinate: CLLocationCoordinate2D? = nil
    @State private var isUserLocationSet = false
    @State private var showingLocations = false

    var body: some View {
        VStack {
            Map(coordinateRegion: $region, interactionModes: [.all], showsUserLocation: true, annotationItems: locations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.title)
                        Text(location.name)
                            .font(.caption)
                    }
                }
            }
            .gesture(
                TapGesture().onEnded {
                    let centerCoordinate = region.center
                    tappedCoordinate = centerCoordinate
                    showingAddLocation = true
                }
            )
            .onAppear {
                loadLocations()
            }
            .onChange(of: locationManager.location) { newLocation in
                if let userLocation = newLocation, !isUserLocationSet {
                    region = MKCoordinateRegion(
                        center: userLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                    isUserLocationSet = true
                }
            }

            // New Button to Save User's Current Location
            Button("Save My Location") {
                if let userLocation = locationManager.location {
                    region.center = userLocation.coordinate
                    tappedCoordinate = userLocation.coordinate
                    showingAddLocation = true
                } else {
                    print("User location is not available.")
                }
            }
            .padding()

            // Zoom Controls
            HStack {
                Button("Zoom In") { zoomIn() }
                Button("Zoom Out") { zoomOut() }
            }
            .padding()

            // Save Location Form - triggered on map tap or Save My Location button
            .sheet(isPresented: $showingAddLocation) {
                VStack {
                    TextField("Location Name", text: $newLocationName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Button("Save") {
                        if let coordinate = tappedCoordinate {
                            let newLocation = SavedLocation(name: newLocationName, coordinate: coordinate)
                            locations.append(newLocation)
                            saveLocations()
                            newLocationName = ""
                            tappedCoordinate = nil
                            showingAddLocation = false
                        }
                    }
                }
                .padding()
            }

            // Button to Show All Saved Locations
            Button("Show All Locations") {
                showingLocations = true
            }
            .sheet(isPresented: $showingLocations) {
                List(locations) { location in
                    Button(action: {
                        region.center = location.coordinate
                        showingLocations = false
                    }) {
                        Text(location.name)
                    }
                }
            }

            // Button to Reset Locations
            Button("Reset Locations") {
                locations.removeAll()
                saveLocations()
            }
        }
    }

    private func zoomIn() {
        let newSpan = MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta * 0.5, longitudeDelta: region.span.longitudeDelta * 0.5)
        region.span = newSpan
    }

    private func zoomOut() {
        let newSpan = MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta * 1.5, longitudeDelta: region.span.longitudeDelta * 1.5)
        region.span = newSpan
    }

    private func saveLocations() {
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(locations)
            UserDefaults.standard.set(encoded, forKey: "savedLocations")
            print("Locations saved successfully")
        } catch {
            print("Failed to encode locations: \(error)")
        }
    }

    private func loadLocations() {
        if let savedLocations = UserDefaults.standard.data(forKey: "savedLocations") {
            do {
                let decoder = JSONDecoder()
                locations = try decoder.decode([SavedLocation].self, from: savedLocations)
                print("Locations loaded successfully: \(locations)")
            } catch {
                print("Failed to decode locations: \(error)")
            }
        } else {
            print("No saved locations found")
        }
    }
}

