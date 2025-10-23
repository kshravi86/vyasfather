import SwiftUI
import MapKit
import CoreLocation

struct BirthInfoView: View {
    @Binding var dateOfBirth: Date
    @Binding var timeOfBirth: Date
    @ObservedObject var searchManager: LocationSearchManager
    @Binding var selectedTitle: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedState: String
    @Binding var selectedCountry: String
    @Binding var submitted: Bool
    @Binding var planetPositions: [PlanetPosition]
    let calculator: PlanetaryCalculator
    @Binding var calcError: String?
    @Binding var toast: Toast?
    @Binding var showDiagnostics: Bool

    @State private var resolvingLocation = false
    @FocusState private var searchFocused: Bool

    private var locationSummary: String {
        if !selectedTitle.isEmpty {
            var components = [selectedTitle]
            if !selectedState.isEmpty { components.append(selectedState) }
            if !selectedCountry.isEmpty { components.append(selectedCountry) }
            return components.joined(separator: ", ")
        }
        return "No location selected"
    }

    private var heroMessage: String {
        if planetPositions.isEmpty {
            return "Share the birth moment and we will choreograph the full cosmic script for you."
        }
        if let asc = calculator.ascendant {
            return "Ascendant rising in \(asc.sign) at \(asc.deg)°\(asc.min)' anchors your personal dharma."
        }
        return "Your chart is ready. Explore yogas, dashas and more insights using the tabs below."
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                heroCard
                essentialsCard
                locationCard
                insightsCard
                diagnosticsCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 80)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 8, x: 0, y: 0)
                Text("Intelligent birth blueprint")
                    .font(.title3.weight(.semibold))
            }
            Text(heroMessage)
                .foregroundColor(CosmicTheme.secondaryText)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            if let error = calcError {
                WarningBanner(message: error)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.35), Color.blue.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
                .blendMode(.screen)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 22, x: 0, y: 12)
    }

    private var essentialsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Birth essentials", systemImage: "clock.and.arrow.circlepath")
                .font(.headline)
            VStack(alignment: .leading, spacing: 12) {
                Text("Date of birth")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                DatePicker("Date", selection: $dateOfBirth, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .accentColor(CosmicTheme.accent)
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("Time of birth")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                DatePicker("Time", selection: $timeOfBirth, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.wheel)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Birth location", systemImage: "mappin.and.ellipse")
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                Text(locationSummary)
                    .font(.subheadline)
                    .foregroundColor(locationSummary == "No location selected" ? .red : CosmicTheme.text)
                if let coordinate = selectedCoordinate {
                    Text(String(format: "Lat %.4f  |  Lon %.4f", coordinate.latitude, coordinate.longitude))
                        .font(.caption)
                        .foregroundColor(CosmicTheme.secondaryText)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                Text("Search city, town or village")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.6))
                    TextField("Bengaluru, Karnataka", text: $searchManager.searchQuery)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .focused($searchFocused)
                    if !searchManager.searchQuery.isEmpty {
                        Button {
                            searchManager.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                if resolvingLocation {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Resolving location…")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.secondaryText)
                    }
                } else if !searchManager.searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(searchManager.searchResults, id: \.self) { completion in
                            Button {
                                selectLocation(completion)
                            } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "location")
                                        .foregroundColor(CosmicTheme.accent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(completion.title)
                                            .font(.subheadline.weight(.semibold))
                                        Text(completion.subtitle)
                                            .font(.caption)
                                            .foregroundColor(CosmicTheme.secondaryText)
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Key cosmic signals", systemImage: "chart.xyaxis.line")
                .font(.headline)
            if planetPositions.isEmpty {
                Text("Fill in the birth details to map planetary guardians and yogas instantly.")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(planetPositions) { planet in
                            PlanetChip(name: planet.name)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var diagnosticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Advanced tools", systemImage: "gearshape.2")
                .font(.headline)
            Text("Inspect Swiss ephemeris assets, logs and planetary calculations when you need to debug deeper.")
                .font(.caption)
                .foregroundColor(CosmicTheme.secondaryText)
            Button {
                showDiagnostics = true
            } label: {
                Label("Open diagnostics", systemImage: "waveform.path.ecg")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(CosmicTheme.accent.opacity(0.2))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.bottom, 20)
    }

    private func selectLocation(_ completion: MKLocalSearchCompletion) {
        resolvingLocation = true
        searchFocused = false
        searchManager.getPlacemark(for: completion) { placemark, error in
            DispatchQueue.main.async {
                resolvingLocation = false
                if let placemark = placemark {
                    selectedCoordinate = placemark.coordinate
                    selectedTitle = placemark.name ?? completion.title
                    selectedState = placemark.administrativeArea ?? ""
                    selectedCountry = placemark.country ?? ""
                    submitted = true
                    toast = Toast(title: "Location updated", subtitle: selectedTitle, systemImage: "checkmark")
                } else if let error = error {
                    toast = Toast(title: "Location error", subtitle: error, systemImage: "exclamationmark.triangle")
                }
            }
        }
    }
}

private struct WarningBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text(message)
                .font(.footnote)
                .foregroundColor(CosmicTheme.text)
        }
        .padding(12)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct BirthInfoView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = LocationSearchManager()
        BirthInfoView(
            dateOfBirth: .constant(Date()),
            timeOfBirth: .constant(Date()),
            searchManager: manager,
            selectedTitle: .constant("Bengaluru"),
            selectedCoordinate: .constant(CLLocationCoordinate2D(latitude: 12.97, longitude: 77.59)),
            selectedState: .constant("Karnataka"),
            selectedCountry: .constant("India"),
            submitted: .constant(true),
            planetPositions: .constant([
                PlanetPosition(name: "Sun", longitude: 0, sign: "Aries", deg: 10, min: 15, nakshatra: "Ashwini", pada: 2, retrograde: false),
                PlanetPosition(name: "Moon", longitude: 0, sign: "Cancer", deg: 5, min: 21, nakshatra: "Pushya", pada: 3, retrograde: false)
            ]),
            calculator: PlanetaryCalculator(),
            calcError: .constant(nil),
            toast: .constant(nil),
            showDiagnostics: .constant(false)
        )
        .preferredColorScheme(.dark)
    }
}
