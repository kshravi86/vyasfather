import SwiftUI
import MapKit
import CoreLocation

struct MatchmakingTabView: View {
    let primaryPositions: [PlanetPosition]
    let primaryAscendant: (sign: String, deg: Int, min: Int)?

    @Binding var partnerDateOfBirth: Date
    @Binding var partnerTimeOfBirth: Date
    @ObservedObject var partnerSearchManager: LocationSearchManager
    @Binding var partnerSelectedTitle: String
    @Binding var partnerSelectedCoordinate: CLLocationCoordinate2D?
    @Binding var partnerSelectedState: String
    @Binding var partnerSelectedCountry: String
    @Binding var partnerSelectedTimeZone: TimeZone?
    @Binding var partnerSubmitted: Bool
    @Binding var partnerPlanetPositions: [PlanetPosition]
    let partnerAscendant: (sign: String, deg: Int, min: Int)?
    @Binding var partnerCalcError: String?
    @Binding var partnerLastSyncedAt: Date?

    let matchResult: MatchCompatibility?
    let onRecompute: () -> Void

    @State private var resolvingLocation = false
    @FocusState private var searchFocused: Bool

    private var partnerLocationSummary: String {
        if !partnerSelectedTitle.isEmpty {
            var parts = [partnerSelectedTitle]
            if !partnerSelectedState.isEmpty { parts.append(partnerSelectedState) }
            if !partnerSelectedCountry.isEmpty { parts.append(partnerSelectedCountry) }
            return parts.joined(separator: ", ")
        }
        return "No partner location yet"
    }

    private var partnerCoordinateSummary: String {
        guard let coord = partnerSelectedCoordinate else { return "Lat/Lon pending" }
        return String(format: "Lat %.4f | Lon %.4f", coord.latitude, coord.longitude)
    }

    private var partnerChartReady: Bool {
        partnerSelectedCoordinate != nil && !partnerPlanetPositions.isEmpty && partnerCalcError == nil
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                headerCard
                if let matchResult {
                    compatibilityHighlights(matchResult)
                } else {
                    placeholderHighlights
                }
                partnerInputCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 64)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundColor(.pink)
                Text("Matchmaking")
                    .font(.title3.weight(.semibold))
            }
            if let matchResult {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(matchResult.verdict)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(matchResult.summary)
                            .font(.caption)
                            .foregroundColor(CosmicTheme.secondaryText)
                    }
                    Spacer()
                    progressGauge(score: matchResult.score)
                }
            } else {
                Text("Add partner birth details to contrast both charts. We’ll score Moon tara, elemental flow, and ascendant resonance.")
                    .font(.callout)
                    .foregroundColor(CosmicTheme.secondaryText)
            }
            if let partnerCalcError {
                WarningBanner(message: partnerCalcError)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [.pink.opacity(0.35), .purple.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 22, x: 0, y: 12)
    }

    @ViewBuilder
    private func compatibilityHighlights(_ result: MatchCompatibility) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compatibility cues")
                .font(.headline)
                .foregroundColor(.white)
            VStack(spacing: 12) {
                matchCard(title: "Moon tara", detail: result.taraNote, icon: "moon.stars.fill", tint: .purple)
                matchCard(title: "Elemental flow", detail: result.elementNote, icon: "sparkles", tint: .orange)
                matchCard(title: "Ascendant resonance", detail: result.ascendantNote, icon: "arrow.triangle.merge", tint: .blue)
                if let marsVenusNote = result.marsVenusNote {
                    matchCard(title: "Mars-Venus synastry", detail: marsVenusNote, icon: "flame.fill", tint: .pink)
                }
            }
        }
    }

    private var placeholderHighlights: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compatibility cues")
                .font(.headline)
                .foregroundColor(.white)
            Text("We'll calculate Moon tara, elemental fit, ascendant harmony, and Mars-Venus synastry once partner data is synced.")
                .font(.caption)
                .foregroundColor(CosmicTheme.secondaryText)
                .padding()
                .cosmicGlass(cornerRadius: 18, tint: .white.opacity(0.12), highlightOpacity: 0.15)
        }
    }

    private func matchCard(title: String, detail: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
            }
            Spacer()
        }
        .padding(14)
        .cosmicGlass(cornerRadius: 20, tint: tint.opacity(0.8), highlightOpacity: 0.25)
    }

    private func progressGauge(score: Int) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("\(score)")
                .font(.title.bold())
                .foregroundColor(.white)
            Text("Harmony")
                .font(.caption)
                .foregroundColor(CosmicTheme.secondaryText)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(LinearGradient(colors: [.pink, .orange], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, min(CGFloat(score) / 100.0, 1.0)) * geo.size.width)
                }
            }
            .frame(height: 8)
        }
        .frame(width: 110)
    }

    private var partnerInputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Partner birth details", systemImage: "person.2.fill")
                .font(.headline)
            VStack(alignment: .leading, spacing: 12) {
                Text("Date of birth")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                DatePicker("Partner date", selection: $partnerDateOfBirth, displayedComponents: .date)
                    .datePickerStyle(.graphical)
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("Time of birth")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                DatePicker("Partner time", selection: $partnerTimeOfBirth, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.wheel)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(partnerLocationSummary)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(partnerSelectedCoordinate == nil ? .red : .white)
                Text(partnerCoordinateSummary)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                if let tz = partnerSelectedTimeZone {
                    Text("Time zone: \(tz.identifier)")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.secondaryText)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                Text("Search partner location")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.6))
                    TextField("City, town, village", text: $partnerSearchManager.searchQuery)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .focused($searchFocused)
                    if !partnerSearchManager.searchQuery.isEmpty {
                        Button {
                            partnerSearchManager.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if resolvingLocation {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Resolving location...")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.secondaryText)
                    }
                } else if !partnerSearchManager.searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(partnerSearchManager.searchResults, id: \.self) { completion in
                            Button {
                                selectLocation(completion)
                            } label: {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "location")
                                        .foregroundColor(.pink)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(completion.title)
                                            .font(.subheadline.weight(.semibold))
                                        Text(completion.subtitle)
                                            .font(.caption)
                                            .foregroundColor(CosmicTheme.secondaryText)
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Button {
                onRecompute()
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text(partnerChartReady ? "Refresh compatibility" : "Compute compatibility")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func selectLocation(_ completion: MKLocalSearchCompletion) {
        resolvingLocation = true
        searchFocused = false
        partnerSearchManager.getPlacemark(for: completion) { placemark, error in
            DispatchQueue.main.async {
                resolvingLocation = false
                if let placemark = placemark {
                    partnerSelectedCoordinate = placemark.coordinate
                    partnerSelectedTitle = placemark.name ?? completion.title
                    partnerSelectedState = placemark.administrativeArea ?? ""
                    partnerSelectedCountry = placemark.country ?? ""
                    partnerSelectedTimeZone = placemark.timeZone
                    partnerSubmitted = true
                    onRecompute()
                } else if let error = error {
                    partnerCalcError = error
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
