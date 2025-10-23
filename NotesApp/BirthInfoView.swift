import SwiftUI
import MapKit

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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let err = calcError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                            Text(err)
                                .foregroundColor(.white)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 15) {
                        Text("Birth Details")
                            .font(.title2).bold()
                            .foregroundColor(CosmicTheme.text)
                        DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                        DatePicker("Time of Birth", selection: $timeOfBirth, displayedComponents: .hourAndMinute)
                    }
                    .cardBackground()

                    VStack(alignment: .leading, spacing: 15) {
                        Text("Place of Birth")
                            .font(.title2).bold()
                            .foregroundColor(CosmicTheme.text)

                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(CosmicTheme.secondaryText)
                            TextField("Enter place name", text: $searchManager.searchQuery)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.words)
                        }

                        if !searchManager.searchResults.isEmpty {
                            List(Array(searchManager.searchResults.enumerated()), id: \.0) { _, result in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.title).font(.body)
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle).font(.caption).foregroundColor(CosmicTheme.secondaryText)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    searchManager.getPlacemark(for: result) { placemark, _ in
                                        if let pm = placemark {
                                            self.selectedTitle = result.title
                                            self.selectedCoordinate = pm.coordinate
                                            self.selectedState = pm.administrativeArea ?? ""
                                            self.selectedCountry = pm.country ?? ""
                                            self.submitted = false
                                        }
                                    }
                                }
                            }
                            .frame(minHeight: 120, maxHeight: 240)
                            .listStyle(.plain)
                        }

                        if let c = selectedCoordinate {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Selected: \(selectedTitle)").font(.headline)
                                Text(String(format: "Lat: %.6f, Lon: %.6f", c.latitude, c.longitude))
                                    .font(.subheadline)
                                    .foregroundColor(CosmicTheme.secondaryText)
                                if !selectedState.isEmpty || !selectedCountry.isEmpty {
                                    Text([selectedState, selectedCountry].filter { !$0.isEmpty }.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(CosmicTheme.secondaryText)
                                }
                            }
                        }
                    }
                    .cardBackground()

                    Button(action: { submitted = true }) {
                        Text("Create Chart")
                            .font(.headline)
                            .foregroundColor(CosmicTheme.background)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(CosmicTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .disabled(selectedCoordinate == nil)

                    if submitted {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Planetary Positions (Lahiri)")
                                .font(.title2).bold()
                                .foregroundColor(CosmicTheme.text)

                            if planetPositions.isEmpty {
                                ProgressView()
                            } else {
                                ZodiacView(planetPositions: planetPositions)
                                    .padding(.vertical)

                                ForEach(planetPositions) { pos in
                                    HStack {
                                        PlanetChip(name: pos.name)
                                        Spacer()
                                        Text("\(pos.sign) \(pos.deg)°\(pos.min)'  ·  \(pos.nakshatra) p\(pos.pada)" + (pos.retrograde ? "  ℞" : ""))
                                            .foregroundColor(CosmicTheme.secondaryText)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .cardBackground()
                    }
                }
                .padding()
            }
            .navigationTitle("Birth Info")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showDiagnostics = true
                    } label: {
                        Image(systemName: "wrench.and.screwdriver")
                    }
                    .accessibilityLabel("Diagnostics")
                }
            }
            .background(CosmicTheme.gradient(for: colorScheme))
            .foregroundColor(CosmicTheme.text)
        }
    }
}
