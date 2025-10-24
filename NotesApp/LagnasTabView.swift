import SwiftUI
import CoreLocation

struct LagnasTabView: View {
    let dateOfBirth: Date
    let timeOfBirth: Date
    let coordinate: CLLocationCoordinate2D?
    let planetPositions: [PlanetPosition]
    let ascendant: (sign: String, deg: Int, min: Int)?
    @Environment(\.colorScheme) private var colorScheme
    private let calculator = PlanetaryCalculator()

    private func merge(date: Date, time: Date, in tz: TimeZone) -> Date {
        let cal = Calendar(identifier: .gregorian)
        var dcmp = cal.dateComponents(in: tz, from: date)
        let tcmp = cal.dateComponents(in: tz, from: time)
        dcmp.hour = tcmp.hour
        dcmp.minute = tcmp.minute
        dcmp.second = tcmp.second
        return cal.date(from: dcmp) ?? date
    }
    
    private var mergedDateTime: Date {
        merge(date: dateOfBirth, time: timeOfBirth, in: TimeZone.current)
    }
    
    private var natalAscendantAbsolute: Double {
        guard let a = ascendant, let sIdx = ZodiacSign.from(name: a.sign)?.rawValue else { return 0.0 }
        return Double(sIdx) * 30.0 + Double(a.deg) + Double(a.min)/60.0
    }

    var body: some View {
        NavigationView {
            Group {
                if let coord = coordinate {
                    let tz = TimeZone.current
                    let dt = mergedDateTime
                    let natalAscAbs = natalAscendantAbsolute
                    let gl = SpecialLagnasCalc.ghatikaLagna(date: dt, tz: tz, coord: coord, calculator: calculator)
                    let hl = SpecialLagnasCalc.horaLagna(date: dt, tz: tz, coord: coord, natalAscAbs: natalAscAbs, calculator: calculator)
                    let hlj = SpecialLagnasCalc.horaLagnaJaimini(date: dt, tz: tz, coord: coord, calculator: calculator)
                    let indu = SpecialLagnasCalc.induLagna(planetPositions: planetPositions, ascSignName: ascendant?.sign ?? "Aries")

                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 20) {
                            // Header section
                            headerSection()
                            
                            // Main content in a grid layout
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 20) {
                                enhancedLagnaCard(
                                    title: "Ghatika Lagna",
                                    subtitle: "Time-based calculation",
                                    icon: "clock.badge.checkmark",
                                    iconBg: .orange,
                                    lagna: gl,
                                    description: "Shows timing of important events"
                                )
                                
                                enhancedLagnaCard(
                                    title: "Hora Lagna",
                                    subtitle: "Wealth & prosperity",
                                    icon: "clock",
                                    iconBg: .teal,
                                    lagna: hl,
                                    description: "Indicates financial matters"
                                )
                                
                                enhancedLagnaCard(
                                    title: "Hora Lagna",
                                    subtitle: "Jaimini method",
                                    icon: "clock.arrow.circlepath",
                                    iconBg: .indigo,
                                    lagna: hlj,
                                    description: "Alternative calculation method"
                                )
                                
                                enhancedLagnaCard(
                                    title: "Indu Lagna",
                                    subtitle: "Wealth indicator",
                                    icon: "indianrupeesign.circle",
                                    iconBg: .purple,
                                    lagna: indu,
                                    description: "Material prosperity analysis"
                                )
                            }
                            .padding(.horizontal)
                            
                            // Additional info section
                            infoSection()
                        }
                        .padding(.vertical)
                    }
                } else {
                    loadingStateView()
                }
            }
            .navigationTitle("Special Lagnas")
            .navigationBarTitleDisplayMode(.large)
            .background(CosmicTheme.gradient(for: colorScheme))
        }
    }
    
    @ViewBuilder
    private func headerSection() -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.title2)
                    .foregroundColor(CosmicTheme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Special Lagnas")
                        .font(.title3.bold())
                        .foregroundColor(CosmicTheme.text)
                    Text("Auxiliary ascendants for deeper analysis")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.secondaryText)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func enhancedLagnaCard(
        title: String,
        subtitle: String,
        icon: String,
        iconBg: Color,
        lagna: (sign: String, deg: Int, min: Int)?,
        description: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon and title
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconBg.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(iconBg)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(CosmicTheme.text)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(CosmicTheme.secondaryText)
                }
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Main content
            if let lagna = lagna {
                VStack(alignment: .leading, spacing: 12) {
                    // Sign display
                    HStack {
                        Text("Sign")
                            .font(.subheadline)
                            .foregroundColor(CosmicTheme.secondaryText)
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(iconBg.opacity(0.15))
                                .frame(height: 32)
                            Text(lagna.sign)
                                .font(.subheadline.bold())
                                .foregroundColor(iconBg)
                        }
                    }
                    
                    // Degree and minute display
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Degrees")
                                .font(.caption)
                                .foregroundColor(CosmicTheme.secondaryText)
                            Text("\(lagna.deg)°")
                                .font(.subheadline.bold())
                                .foregroundColor(CosmicTheme.text)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Minutes")
                                .font(.caption)
                                .foregroundColor(CosmicTheme.secondaryText)
                            Text("\(lagna.min)'")
                                .font(.subheadline.bold())
                                .foregroundColor(CosmicTheme.text)
                        }
                        
                        Spacer()
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title3)
                        .foregroundColor(.orange)
                    Text("Data Unavailable")
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.secondaryText)
                    Text("Check birth details")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.secondaryText.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            // Description
            Text(description)
                .font(.caption)
                .foregroundColor(CosmicTheme.secondaryText.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    iconBg.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: iconBg.opacity(0.1), radius: 8, x: 0, y: 4)
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
    
    @ViewBuilder
    private func infoSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("About Special Lagnas")
                    .font(.headline)
                    .foregroundColor(CosmicTheme.text)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    title: "Ghatika Lagna",
                    description: "Calculated based on sunrise time, shows timing of events"
                )
                InfoRow(
                    title: "Hora Lagna",
                    description: "Indicates wealth, material gains, and financial prospects"
                )
                InfoRow(
                    title: "Indu Lagna",
                    description: "Special lagna for analyzing wealth and prosperity"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func loadingStateView() -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(CosmicTheme.accent)
            }
            
            VStack(spacing: 8) {
                Text("Calculating Lagnas")
                    .font(.headline)
                    .foregroundColor(CosmicTheme.text)
                Text("Please wait while we determine your location and calculate the special lagnas...")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InfoRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(CosmicTheme.text)
            Text(description)
                .font(.caption)
                .foregroundColor(CosmicTheme.secondaryText)
                .lineLimit(2)
        }
    }
}
