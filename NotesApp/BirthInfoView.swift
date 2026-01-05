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
    @Binding var selectedTimeZone: TimeZone?
    @Binding var submitted: Bool
    @Binding var planetPositions: [PlanetPosition]
    let calculator: PlanetaryCalculator
    @Binding var calcError: String?
    @Binding var toast: Toast?
    let onRecompute: () -> Void

    @State private var resolvingLocation = false
    @FocusState private var searchFocused: Bool
    @State private var showingBirthMomentSheet = false

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

    private var statusPill: (text: String, color: Color) {
        if calcError != nil {
            return ("ATTENTION", .pink)
        }
        if planetPositions.isEmpty {
            return ("SETUP", .orange)
        }
        return ("READY", .green)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private var birthDateSummary: String {
        Self.dateFormatter.string(from: dateOfBirth)
    }

    private var birthTimeSummary: String {
        Self.timeFormatter.string(from: timeOfBirth)
    }

    private var canCalculate: Bool {
        selectedCoordinate != nil
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                heroCard
                essentialsCard
                locationCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 100)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(CosmicTheme.accent.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(CosmicTheme.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cosmic Blueprint")
                        .font(.system(.title2, design: .serif).weight(.semibold))
                        .foregroundColor(.white)
                    Text(planetPositions.isEmpty ? "Enter details to begin" : "Chart computed")
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.secondaryText)
                }
                Spacer()
                TagBadge(text: statusPill.text, color: statusPill.color)
            }
            
            Text(heroMessage)
                .foregroundColor(.white.opacity(0.9))
                .font(.subheadline)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                
            if let error = calcError {
                WarningBanner(message: error)
            }
        }
        .padding(24)
        .cosmicGlass(cornerRadius: 28, tint: CosmicTheme.accent, highlightOpacity: 0.1)
    }

    private var essentialsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(
                title: "Birth Essentials",
                subtitle: "Date and time used for calculations",
                icon: "clock.and.arrow.circlepath",
                tint: .cyan
            )
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MOMENT")
                            .font(.caption2.bold())
                            .foregroundColor(CosmicTheme.secondaryText)
                            .tracking(1)
                        Text("\(birthDateSummary) • \(birthTimeSummary)")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button {
                            setBirthMomentToNow()
                        } label: {
                            Text("Now")
                                .font(.caption.bold())
                                .foregroundColor(CosmicTheme.accent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(CosmicTheme.accent.opacity(0.15)))
                        }
                        .buttonStyle(.plain)

                        Button {
                            showingBirthMomentSheet = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Compact Pickers
                HStack(spacing: 12) {
                    compactDatePicker
                    compactTimePicker
                }

                calculateChartButton
            }
            .padding(20)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var calculateChartButton: some View {
        Button {
            handleChartCalculation()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                Text("Calculate Chart")
                    .font(.headline)
            }
            .foregroundColor(CosmicTheme.backgroundDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(CosmicTheme.accent)
            )
            .shadow(color: CosmicTheme.accent.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!canCalculate)
        .opacity(canCalculate ? 1 : 0.6)
        .padding(.top, 4)
    }

    private var compactDatePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Date", systemImage: "calendar")
                .font(.caption.weight(.medium))
                .foregroundColor(CosmicTheme.secondaryText)
            DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(CosmicTheme.accent)
                .scaleEffect(0.9, anchor: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var compactTimePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Time", systemImage: "clock")
                .font(.caption.weight(.medium))
                .foregroundColor(CosmicTheme.secondaryText)
            DatePicker("", selection: $timeOfBirth, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(CosmicTheme.accent)
                .scaleEffect(0.9, anchor: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(
                title: "Location",
                subtitle: "Coordinates and timezone",
                icon: "mappin.and.ellipse",
                tint: .mint
            )
            
            VStack(alignment: .leading, spacing: 16) {
                if !selectedTitle.isEmpty {
                    HStack(alignment: .top) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(Color.mint, Color.mint.opacity(0.3))
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedTitle)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text([selectedState, selectedCountry].filter({ !$0.isEmpty }).joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.secondaryText)
                            
                            if let coord = selectedCoordinate {
                                Text(String(format: "%.4f, %.4f", coord.latitude, coord.longitude))
                                    .font(.caption.monospaced())
                                    .foregroundColor(Color.white.opacity(0.5))
                                    .padding(.top, 2)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.mint.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mint.opacity(0.2), lineWidth: 1))
                }
                
                searchFieldPanel
                
                if resolvingLocation {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                        Text("Resolving location…")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                } else if !searchManager.searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(searchManager.searchResults.enumerated()), id: \.element) { index, completion in
                            Button {
                                selectLocation(completion)
                            } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                        .foregroundColor(CosmicTheme.secondaryText)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(completion.title)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                        Text(completion.subtitle)
                                            .font(.caption)
                                            .foregroundColor(CosmicTheme.secondaryText)
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.04))
                            }
                            .buttonStyle(.plain)
                            
                            if index < searchManager.searchResults.count - 1 {
                                Divider().background(Color.white.opacity(0.1))
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .cardBackground(tint: .mint)
    }

    private var searchFieldPanel: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))
            TextField("Search city...", text: $searchManager.searchQuery)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .focused($searchFocused)
                .foregroundColor(.white)
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
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
                    selectedTimeZone = placemark.timeZone
                    submitted = true
                    toast = Toast(title: "Location updated", subtitle: selectedTitle, systemImage: "checkmark")
                } else if let error = error {
                    selectedTimeZone = nil
                    toast = Toast(title: "Location error", subtitle: error, systemImage: "exclamationmark.triangle")
                }
            }
        }
    }

    private func handleChartCalculation() {
        guard canCalculate else {
            toast = Toast(
                title: "Location required",
                subtitle: "Select a birth location to compute the chart",
                systemImage: "mappin.and.ellipse"
            )
            return
        }
        onRecompute()
        submitted = true
        toast = Toast(
            title: "Chart updated",
            subtitle: "\(birthDateSummary) - \(birthTimeSummary)",
            systemImage: "sparkles"
        )
    }

    private func setBirthMomentToNow() {
        let now = Date()
        dateOfBirth = now
        timeOfBirth = now
        toast = Toast(
            title: "Set to now",
            subtitle: "\(birthDateSummary) - \(birthTimeSummary)",
            systemImage: "clock.badge.checkmark"
        )
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

private struct BirthMomentSheet: View {
    @Binding var dateOfBirth: Date
    @Binding var timeOfBirth: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                CosmicBackgroundView()
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Pick a date", systemImage: "calendar")
                            .font(.headline)
                            .foregroundColor(.white)
                        DatePicker("Date", selection: $dateOfBirth, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .tint(CosmicTheme.accent)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(CosmicTheme.glassGradient(tint: CosmicTheme.accentSoft))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(CosmicTheme.panelStroke, lineWidth: 1)
                                    )
                            )
                        Divider()
                            .overlay(CosmicTheme.panelStroke)
                        Label("Pick a time", systemImage: "clock")
                            .font(.headline)
                            .foregroundColor(.white)
                        DatePicker("Time", selection: $timeOfBirth, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .tint(CosmicTheme.accent)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(CosmicTheme.glassGradient(tint: CosmicTheme.accent))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(CosmicTheme.panelStroke, lineWidth: 1)
                                    )
                            )
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(CosmicTheme.panelFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(CosmicTheme.panelStroke, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Birth moment")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(tint)
                .frame(width: 4, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
            }
            Spacer()
            
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(tint.opacity(0.8))
        }
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
            selectedTimeZone: .constant(TimeZone(identifier: "Asia/Kolkata")),
            submitted: .constant(true),
            planetPositions: .constant([
                PlanetPosition(name: "Sun", longitude: 0, sign: "Aries", deg: 10, min: 15, nakshatra: "Ashwini", pada: 2, retrograde: false),
                PlanetPosition(name: "Moon", longitude: 0, sign: "Cancer", deg: 5, min: 21, nakshatra: "Pushya", pada: 3, retrograde: false)
            ]),
            calculator: PlanetaryCalculator(),
            calcError: .constant(nil),
            toast: .constant(nil),
            onRecompute: {}
        )
        .preferredColorScheme(.dark)
    }
}


