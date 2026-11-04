import SwiftUI
import MapKit
import CoreLocation

extension CLLocationCoordinate2D {
    static let burjKhalifa = CLLocationCoordinate2D(latitude: 25.1972, longitude: 55.2744)
    static let dubaiMall = CLLocationCoordinate2D(latitude: 25.1985, longitude: 55.2774)
    static let grandMosque = CLLocationCoordinate2D(latitude: 24.4128, longitude: 54.4740)
    static let louvreAbuDhabi = CLLocationCoordinate2D(latitude: 24.5333, longitude: 54.3976)
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 24.9, longitude: 54.9),
                           span: MKCoordinateSpan(latitudeDelta: 2.6, longitudeDelta: 2.6))
    )
    @State private var searchText = ""
    @State private var searchResult: MKMapItem?
    @State private var errorMessage: String?
    @State private var isSearching = false
    @State private var useHybrid = false

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, interactionModes: .all) {
                Marker("Dubai Mall", coordinate: .dubaiMall)
                Marker("Burj Khalifa", coordinate: .burjKhalifa)
                Marker("Sheikh Zayed Grand Mosque", systemImage: "mappin.circle.fill", coordinate: .grandMosque)
                    .tint(.green)
                Annotation("Louvre Abu Dhabi", coordinate: .louvreAbuDhabi, anchor: .bottom) {
                    VStack(spacing: 5) {
                        Text("Louvre Abu Dhabi").font(.caption.bold())
                        Image(systemName: "building.columns.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        Text("Art Museum").font(.caption2)
                    }
                    .padding(8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                }
                UserAnnotation()
                if let searchResult {
                    Marker(searchResult.name ?? "Search result", coordinate: searchResult.placemark.coordinate)
                        .tint(.orange)
                }
            }
            .mapStyle(useHybrid ? .hybrid(elevation: .realistic) : .standard(elevation: .realistic, showsTraffic: true))
            .mapControls {
                MapCompass()
                MapPitchToggle()
                MapUserLocationButton()
            }
            .mapControlVisibility(.visible)
            .onAppear { locationManager.requestPermission() }

            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search places in UAE", text: $searchText)
                        .submitLabel(.search)
                        .onSubmit { Task { await searchPlaces() } }
                        .accessibilityLabel("Search for a place")
                    if isSearching { ProgressView() }
                    Button {
                        Task { await searchPlaces() }
                    } label: {
                        Image(systemName: "arrow.right.circle.fill").font(.title2)
                    }
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
                    .accessibilityLabel("Run search")
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                HStack {
                    Label("UAE Landmarks", systemImage: "map.fill").font(.subheadline.bold())
                    Spacer()
                    Toggle("Hybrid", isOn: $useHybrid).labelsHidden()
                    Text("Hybrid").font(.caption)
                }
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    @MainActor
    private func searchPlaces() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 24.9, longitude: 54.9),
                                            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5))
        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else {
                errorMessage = "No matching place found. Try another search."
                return
            }
            searchResult = item
            cameraPosition = .region(MKCoordinateRegion(center: item.placemark.coordinate,
                                                       span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)))
        } catch {
            errorMessage = "Search failed. Check your internet connection and try again."
        }
    }
}

#Preview {
    ContentView()
}
