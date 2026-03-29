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

    private var heroMessage: String {
        if planetPositions.isEmpty {
            return "Share your birth moment to unveil the cosmic script written in the stars."
        }
        if let asc = calculator.ascendant {
            return "Ascendant rising in \(asc.sign) at \(asc.deg)°\(asc.min)' anchors your personal dharma."
        }
        return "Your chart is ready. Explore insights across the dashboard."
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

    private var canCalculate: Bool {
        selectedCoordinate != nil
    }

    private var formattedBirthDate: String {
        dateOfBirth.formatted(date: .abbreviated, time: .omitted)
    }

    private var formattedBirthTime: String {
        timeOfBirth.formatted(date: .omitted, time: .shortened)
    }

    private var selectedLocationDetail: String {
        let parts = [selectedState, selectedCountry].filter { !$0.isEmpty }
        if parts.isEmpty {
            return "Search a birthplace to resolve the location automatically."
        }
        return parts.joined(separator: ", ")
    }

    private var timeZoneDetail: String {
        guard let selectedTimeZone else {
            return "Timezone resolves automatically after you choose a city."
        }
        return selectedTimeZone.identifier.replacingOccurrences(of: "_", with: " ")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                heroCard

                timeAndSpaceSection
                locationSection

                calculateChartButton
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 120)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.headline.weight(.bold))
                            .foregroundColor(CosmicTheme.accent)
                            .symbolEffect(.bounce, value: submitted)

                        Text("BIRTH SETUP")
                            .font(.caption.weight(.bold))
                            .tracking(2)
                            .foregroundColor(CosmicTheme.secondaryText)
                    }

                    Text("Cosmic Blueprint")
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .foregroundColor(CosmicTheme.starlight)

                    Text(heroMessage)
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.secondaryText)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                statusTag(text: statusPill.text, color: statusPill.color)
            }

            ViewThatFits {
                HStack(spacing: 10) {
                    momentBadge(icon: "calendar", title: formattedBirthDate, tint: CosmicTheme.accent)
                    momentBadge(icon: "clock", title: formattedBirthTime, tint: CosmicTheme.accentSoft)

                    if !selectedTitle.isEmpty {
                        momentBadge(icon: "mappin.and.ellipse", title: selectedTitle, tint: .mint)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    momentBadge(icon: "calendar", title: formattedBirthDate, tint: CosmicTheme.accent)
                    momentBadge(icon: "clock", title: formattedBirthTime, tint: CosmicTheme.accentSoft)

                    if !selectedTitle.isEmpty {
                        momentBadge(icon: "mappin.and.ellipse", title: selectedTitle, tint: .mint)
                    }
                }
            }

            if let error = calcError {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Calculation issue")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)

                        Text(error)
                            .font(.caption)
                            .foregroundColor(CosmicTheme.secondaryText)
                            .lineSpacing(2)
                    }
                }
                .padding(14)
                .cosmicGlass(cornerRadius: 18, tint: .yellow, highlightOpacity: 0.15)
            }
        }
        .padding(24)
        .background(
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.white.opacity(0.02))

                Circle()
                    .fill(CosmicTheme.accent.opacity(0.14))
                    .frame(width: 180, height: 180)
                    .blur(radius: 16)
                    .offset(x: 60, y: -70)

                Circle()
                    .fill(CosmicTheme.accentSoft.opacity(0.10))
                    .frame(width: 120, height: 120)
                    .blur(radius: 18)
                    .offset(x: -40, y: 80)

                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(CosmicTheme.heroGradient.opacity(0.18))
            }
        )
        .cosmicGlass(cornerRadius: 32, tint: CosmicTheme.accent, highlightOpacity: 0.14)
    }

    private var timeAndSpaceSection: some View {
        sectionCard(
            title: "Birth Moment",
            subtitle: "Date and time shape the chart foundation, houses and ascendant.",
            icon: "clock.badge.checkmark",
            tint: CosmicTheme.accent
        ) {
            VStack(alignment: .leading, spacing: 16) {
                ViewThatFits {
                    HStack(spacing: 10) {
                        momentBadge(icon: "calendar", title: formattedBirthDate, tint: CosmicTheme.accent)
                        momentBadge(icon: "clock", title: formattedBirthTime, tint: CosmicTheme.accentSoft)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        momentBadge(icon: "calendar", title: formattedBirthDate, tint: CosmicTheme.accent)
                        momentBadge(icon: "clock", title: formattedBirthTime, tint: CosmicTheme.accentSoft)
                    }
                }

                Button {
                    setBirthMomentToNow()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption.weight(.bold))
                        Text("Use Current Time")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundColor(CosmicTheme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(CosmicTheme.accent.opacity(0.12))
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(CosmicTheme.accent.opacity(0.24), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.scale)

                ViewThatFits {
                    HStack(spacing: 14) {
                        pickerCard(
                            title: "Date",
                            subtitle: "Calendar reference",
                            icon: "calendar",
                            tint: CosmicTheme.accent
                        ) {
                            DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .tint(CosmicTheme.accent)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        pickerCard(
                            title: "Time",
                            subtitle: "Local birth time",
                            icon: "clock",
                            tint: CosmicTheme.accentSoft
                        ) {
                            DatePicker("", selection: $timeOfBirth, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .tint(CosmicTheme.accentSoft)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    VStack(spacing: 14) {
                        pickerCard(
                            title: "Date",
                            subtitle: "Calendar reference",
                            icon: "calendar",
                            tint: CosmicTheme.accent
                        ) {
                            DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .tint(CosmicTheme.accent)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        pickerCard(
                            title: "Time",
                            subtitle: "Local birth time",
                            icon: "clock",
                            tint: CosmicTheme.accentSoft
                        ) {
                            DatePicker("", selection: $timeOfBirth, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .tint(CosmicTheme.accentSoft)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                Text("Pick the closest known time. Even small shifts can change house placement and the rising sign.")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                    .lineSpacing(3)
            }
        }
    }

    private var locationSection: some View {
        sectionCard(
            title: "Birthplace",
            subtitle: "Search any city or town and the app will resolve coordinates and timezone.",
            icon: "mappin.circle.fill",
            tint: .mint
        ) {
            VStack(spacing: 16) {
                if !selectedTitle.isEmpty {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedTitle)
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(selectedLocationDetail)
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.secondaryText)

                            Text(timeZoneDetail)
                                .font(.caption)
                                .foregroundColor(CosmicTheme.secondaryText.opacity(0.85))
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.mint)
                            .font(.title3)
                    }
                    .padding(16)
                    .cosmicGlass(cornerRadius: 22, tint: .mint, highlightOpacity: 0.12)
                }

                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(searchFocused ? CosmicTheme.accent : CosmicTheme.secondaryText)

                    TextField("Search city (e.g. Bangalore)", text: $searchManager.searchQuery)
                        .font(.body)
                        .foregroundColor(.white)
                        .tint(CosmicTheme.accent)
                        .disableAutocorrection(true)
                        .focused($searchFocused)

                    if !searchManager.searchQuery.isEmpty {
                        Button {
                            searchManager.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(CosmicTheme.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black.opacity(0.22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(
                                    searchFocused ? CosmicTheme.accent.opacity(0.45) : Color.white.opacity(0.08),
                                    lineWidth: 1
                                )
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: searchFocused)

                if resolvingLocation {
                    HStack(spacing: 10) {
                        ProgressView().tint(.white)
                        Text("Resolving city details...")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.secondaryText)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cosmicGlass(cornerRadius: 18, tint: CosmicTheme.accentSoft, highlightOpacity: 0.1)
                } else if !searchManager.searchResults.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(searchManager.searchResults.enumerated()), id: \.element) { index, completion in
                            Button {
                                selectLocation(completion)
                            } label: {
                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(completion.title)
                                            .font(.body.weight(.medium))
                                            .foregroundColor(.white)

                                        Text(completion.subtitle)
                                            .font(.caption)
                                            .foregroundColor(CosmicTheme.secondaryText)
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.up.right.circle.fill")
                                        .font(.body)
                                        .foregroundColor(.mint)
                                }
                                .padding(16)
                                .background(Color.white.opacity(index.isMultiple(of: 2) ? 0.03 : 0.015))
                            }
                            .buttonStyle(.plain)

                            if index < searchManager.searchResults.count - 1 {
                                Divider().background(Color.white.opacity(0.1))
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(searchManager.searchQuery.isEmpty ? "Search for a birthplace" : "No matches yet")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)

                        Text(searchManager.searchQuery.isEmpty
                             ? "Start with a city or town name. Coordinates and timezone will be attached automatically."
                             : "Try a nearby city, shorter spelling, or the English name.")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.secondaryText)
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cosmicGlass(cornerRadius: 18, tint: Color.white.opacity(0.25), highlightOpacity: 0.08)
                }
            }
        }
    }

    private var calculateChartButton: some View {
        Button {
            handleChartCalculation()
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(canCalculate ? "Generate Full Chart" : "Select a birthplace first")
                        .font(.headline.weight(.bold))
                        .tracking(0.6)

                    Text(canCalculate
                         ? "Compute planets, houses and dashas from the selected birth data."
                         : "Birthplace is required to calculate an accurate chart.")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.backgroundDeep.opacity(0.72))
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 42, height: 42)

                    Image(systemName: canCalculate ? "sparkles" : "mappin.slash")
                        .font(.headline.weight(.bold))
                }
            }
            .foregroundColor(CosmicTheme.backgroundDeep)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [CosmicTheme.accent, CosmicTheme.ember],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .blendMode(.overlay)
            )
            .shadow(color: CosmicTheme.accent.opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(.scale)
        .disabled(!canCalculate)
        .opacity(canCalculate ? 1 : 0.5)
        .animation(.easeInOut, value: canCalculate)
    }

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.16))
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(CosmicTheme.secondaryText)
                        .lineSpacing(3)
                }
            }

            content()
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cosmicGlass(cornerRadius: 28, tint: tint, highlightOpacity: 0.13)
    }

    private func momentBadge(icon: String, title: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundColor(tint)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(tint.opacity(0.24), lineWidth: 1)
                )
        )
    }

    private func statusTag(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .tracking(1.2)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.14))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(color.opacity(0.24), lineWidth: 1)
                    )
            )
    }

    private func pickerCard<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.16))
                        .frame(width: 30, height: 30)

                    Image(systemName: icon)
                        .font(.caption.weight(.bold))
                        .foregroundColor(tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1)
                        .foregroundColor(CosmicTheme.secondaryText)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.secondaryText.opacity(0.82))
                }
            }

            content()
                .font(.body.weight(.medium))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(tint.opacity(0.22), lineWidth: 1)
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
                    // Auto-calculate if ready
                    if canCalculate {
                        onRecompute()
                    }
                } else if let error = error {
                    selectedTimeZone = nil
                    toast = Toast(title: "Location error", subtitle: error, systemImage: "exclamationmark.triangle")
                }
            }
        }
    }

    private func handleChartCalculation() {
        guard canCalculate else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        onRecompute()
        submitted = true
    }

    private func setBirthMomentToNow() {
        let now = Date()
        dateOfBirth = now
        timeOfBirth = now
    }
}

// Button Style for organic press effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scale: ScaleButtonStyle { ScaleButtonStyle() }
}



