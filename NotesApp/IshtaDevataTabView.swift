import SwiftUI

struct IshtaDevataTabView: View {
    let planetPositions: [PlanetPosition]
    let ascendant: (sign: String, deg: Int, min: Int)?
    @Environment(\.colorScheme) private var colorScheme

    private var result: IshtaDevataResultModel? {
        IshtaDevataCalcIOS.compute(planetPositions: planetPositions, ascendant: ascendant)
    }

    private var d9: (ascSign: String, entries: [D9Entry]) {
        VargaCalculatorIOS.computeD9(planetPositions: planetPositions, ascendant: ascendant)
    }

    var body: some View {
        ZStack {
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView(showsIndicators: false) {
                    if let res = result {
                        VStack(spacing: 24) {
                            // Ishta Devata (Hero)
                            IshtaHeroCard(result: res)
                            
                            // Palana Devata
                            PalanaCard(result: res)
                            
                            // Context Section
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Navamsha Context", systemImage: "square.grid.3x3.fill")
                                    .font(.headline)
                                    .foregroundColor(CosmicTheme.starlight)
                                    .padding(.horizontal, 4)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(d9.entries) { entry in
                                        CompactPlanetCard(entry: entry)
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .padding(.bottom, 80)
                    } else {
                        emptyStateView
                    }
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Ishta Devata")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(CosmicTheme.starlight)
            
            Text("The chosen deity for liberation")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.secondaryText)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.pink.opacity(0.5), .clear],
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
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text("Insufficent data to calculate")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.secondaryText)
            Spacer()
        }
    }
}

struct IshtaHeroCard: View {
    let result: IshtaDevataResultModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ISHTA DEVATA")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(2)
                    Text(result.deity)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.pink)
                    .shadow(color: .pink.opacity(0.5), radius: 10)
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color.pink.opacity(0.6), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Details
            VStack(alignment: .leading, spacing: 16) {
                // Key Planets
                HStack(spacing: 20) {
                    DetailColumn(title: "Atmakaraka", value: result.atmakaraka)
                    DetailColumn(title: "Determined By", value: result.ishtaDeterminingPlanet)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Suggestion
                VStack(alignment: .leading, spacing: 6) {
                    Label("Sadhana Suggestion", systemImage: "hands.sparkles.fill")
                        .font(.caption.bold())
                        .foregroundColor(CosmicTheme.starlight)
                    
                    Text(result.suggestion)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
            .background(CosmicTheme.midnight.opacity(0.6))
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.pink.opacity(0.5), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.pink.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}

struct PalanaCard: View {
    let result: IshtaDevataResultModel
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: "shield.fill")
                    .font(.title2)
                    .foregroundColor(.teal)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("PALANA DEVATA")
                    .font(.caption.bold())
                    .foregroundColor(.teal)
                    .tracking(1)
                Text(result.palanaDeity)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text("Sustainer in this life")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(16)
        .background(CosmicTheme.midnight.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.teal.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CompactPlanetCard: View {
    let entry: D9Entry
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: PlanetStyle.icon(for: entry.planet))
                    .font(.subheadline)
                    .foregroundColor(PlanetStyle.color(for: entry.planet))
                Text(entry.planet)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
            }
            Spacer()
            Text(entry.sign)
                .font(.caption.bold())
                .foregroundColor(CosmicTheme.secondaryText)
        }
        .padding(12)
        .background(CosmicTheme.midnight.opacity(0.4))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct DetailColumn: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .foregroundColor(CosmicTheme.secondaryText)
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}
