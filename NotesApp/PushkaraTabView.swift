import SwiftUI

struct PushkaraTabView: View {
    let planetPositions: [PlanetPosition]
    let ascendant: (sign: String, deg: Int, min: Int)?
    @Environment(\.colorScheme) private var colorScheme

    private var evaluatedPushkaras: [PushkaraEntry] {
        var eval = PushkaraUtils.evaluate(planetPositions: planetPositions)
        if let asc = ascendant, let lagnaEntry = PushkaraUtils.evaluateLagna(sign: asc.sign, deg: asc.deg, min: asc.min) {
            eval.append(lagnaEntry)
        }
        return eval
    }
    
    private var pushkaraPlanets: [PushkaraEntry] {
        evaluatedPushkaras.filter { $0.isPushkara }
    }

    var body: some View {
        ZStack {
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                if pushkaraPlanets.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(pushkaraPlanets) { entry in
                                PushkaraCard(entry: entry)
                            }
                        }
                        .padding(20)
                        .padding(.bottom, 80) // Space for floating dock
                    }
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Pushkara Navamsha")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(CosmicTheme.starlight)
            
            Text("Nourishing portions of the zodiac")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.secondaryText)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, CosmicTheme.accent.opacity(0.5), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.top, 8)
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
        .background(CosmicTheme.midnight.opacity(0.4))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(CosmicTheme.secondaryText.opacity(0.5))
            
            Text("No planets in Pushkara")
                .font(.title3.weight(.medium))
                .foregroundColor(CosmicTheme.secondaryText)
            
            Text("Planets here are considered highly auspicious and fortified.")
                .font(.caption)
                .foregroundColor(CosmicTheme.secondaryText.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

struct PushkaraCard: View {
    let entry: PushkaraEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Planet Icon with Glow
            ZStack {
                Circle()
                    .fill(CosmicTheme.accent.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Circle()
                    .stroke(CosmicTheme.accent.opacity(0.3), lineWidth: 1)
                    .frame(width: 56, height: 56)
                
                Image(systemName: PlanetStyle.icon(for: entry.planet))
                    .font(.title2)
                    .foregroundColor(PlanetStyle.color(for: entry.planet))
                    .shadow(color: PlanetStyle.color(for: entry.planet).opacity(0.8), radius: 8, x: 0, y: 0)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.planet)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption2)
                        .foregroundColor(CosmicTheme.secondaryText)
                    
                    if let d9 = entry.d9Sign {
                        Text("Moves to \(d9) Navamsha")
                            .font(.subheadline)
                            .foregroundColor(CosmicTheme.starlight)
                    } else {
                        Text("Pushkara Zone")
                            .font(.subheadline)
                            .foregroundColor(CosmicTheme.starlight)
                    }
                }
            }
            
            Spacer()
            
            // Badge
            VStack {
                Image(systemName: "seal.fill")
                    .font(.title2)
                    .foregroundColor(CosmicTheme.accent)
                    .shadow(color: CosmicTheme.accent.opacity(0.5), radius: 10, x: 0, y: 0)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(CosmicTheme.midnight.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            CosmicTheme.accent.opacity(0.5),
                            CosmicTheme.accent.opacity(0.1),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 10)
    }
}
