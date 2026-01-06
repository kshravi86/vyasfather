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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                heroCard
                
                VStack(spacing: 24) {
                    timeAndSpaceSection
                    locationSection
                }
                
                calculateChartButton
                    .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 100)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(CosmicTheme.accent)
                            .symbolEffect(.bounce, value: submitted)
                        Text("Cosmic Blueprint")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(CosmicTheme.starlight)
                    }
                    
                    Text(heroMessage)
                        .font(.body)
                        .foregroundColor(CosmicTheme.secondaryText)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            
            if let error = calcError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.pink)
                    Text(error)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.pink)
                }
                .padding(12)
                .background(Color.pink.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(24)
        .background(
            ZStack {
                CosmicTheme.midnight.opacity(0.6)
                RadialGradient(
                    colors: [CosmicTheme.accent.opacity(0.1), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 300
                )
            }
        )
        .cosmicGlass(cornerRadius: 32, tint: CosmicTheme.accent, highlightOpacity: 0.1)
    }

    private var timeAndSpaceSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Time & Date", systemImage: "clock.fill")
                .font(.headline)
                .foregroundColor(CosmicTheme.starlight)
            
            HStack(spacing: 16) {
                // Date Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("DATE")
                        .font(.caption2.bold())
                        .foregroundColor(CosmicTheme.secondaryText)
                        .tracking(1)
                    DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(CosmicTheme.accent)
                        .scaleEffect(0.9, anchor: .leading)
                        .frame(height: 36)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))

                // Time Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("TIME")
                        .font(.caption2.bold())
                        .foregroundColor(CosmicTheme.secondaryText)
                        .tracking(1)
                    DatePicker("", selection: $timeOfBirth, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(CosmicTheme.accent)
                        .scaleEffect(0.9, anchor: .leading)
                        .frame(height: 36)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Birth Place", systemImage: "mappin.circle.fill")
                .font(.headline)
                .foregroundColor(CosmicTheme.starlight)
            
            VStack(spacing: 16) {
                // Active Location Display
                if !selectedTitle.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedTitle)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text([selectedState, selectedCountry].filter({ !$0.isEmpty }).joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundColor(CosmicTheme.secondaryText)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.mint)
                            .font(.title3)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.mint.opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.mint.opacity(0.2), lineWidth: 1))
                    )
                }

                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(CosmicTheme.secondaryText)
                    
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
                .background(Color.black.opacity(0.3))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(searchFocused ? CosmicTheme.accent : Color.white.opacity(0.1), lineWidth: 1)
                )
                .animation(.easeInOut(duration: 0.2), value: searchFocused)
                
                // Search Results
                if resolvingLocation {
                    HStack(spacing: 8) {
                        ProgressView().tint(.white)
                        Text("Locating...").font(.caption).foregroundColor(CosmicTheme.secondaryText)
                    }
                    .padding()
                } else if !searchManager.searchResults.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(searchManager.searchResults.enumerated()), id: \.element) { index, completion in
                            Button {
                                selectLocation(completion)
                            } label: {
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(completion.title)
                                            .font(.body)
                                            .foregroundColor(.white)
                                        Text(completion.subtitle)
                                            .font(.caption)
                                            .foregroundColor(CosmicTheme.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption)
                                        .foregroundColor(CosmicTheme.secondaryText)
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.04))
                            }
                            .buttonStyle(.plain)
                            
                            if index < searchManager.searchResults.count - 1 {
                                Divider().background(Color.white.opacity(0.1))
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
            }
        }
    }

    private var calculateChartButton: some View {
        Button {
            handleChartCalculation()
        } label: {
            HStack(spacing: 12) {
                Text("Calculate Chart")
                    .font(.headline.weight(.bold))
                    .tracking(1)
                Image(systemName: "arrow.right")
                    .font(.headline.weight(.bold))
            }
            .foregroundColor(CosmicTheme.backgroundDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [CosmicTheme.accent, Color.orange.opacity(0.8)],
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



