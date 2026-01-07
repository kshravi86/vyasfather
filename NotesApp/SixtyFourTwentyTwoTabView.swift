import SwiftUI

struct SixtyFourTwentyTwoTabView: View {
    let ascendant: (sign: String, deg: Int, min: Int)?
    let planetPositions: [PlanetPosition]
    @Environment(\.colorScheme) private var colorScheme

    private var result: SixtyFourTwentyTwoResultModel {
        SixtyFourTwentyTwoCalcIOS.compute(ascendant: ascendant, planetPositions: planetPositions)
    }

    var body: some View {
        ZStack {
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Explanation
                        Text("The 64th Navamsha and 22nd Drekkana are sensitive points indicating potential obstacles, vulnerabilities, or karmic challenges.")
                            .font(.caption)
                            .foregroundColor(CosmicTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 8)

                        // From Lagna (Self)
                        KharaCard(
                            title: "From Lagna (Self)",
                            subtitle: "Physical & Personal Challenges",
                            drekLord: result.fromLagnaDrekkanaLord,
                            drekSign: result.fromLagnaDrekkanaSign,
                            navLord: result.fromLagnaNavamsaLord,
                            navSign: result.fromLagnaNavamsaSign,
                            tint: .pink
                        )

                        // From Moon (Mind)
                        KharaCard(
                            title: "From Moon (Mind)",
                            subtitle: "Emotional & Mental Hurdles",
                            drekLord: result.fromMoonDrekkanaLord,
                            drekSign: result.fromMoonDrekkanaSign,
                            navLord: result.fromMoonNavamsaLord,
                            navSign: result.fromMoonNavamsaSign,
                            tint: .orange
                        )
                    }
                    .padding(20)
                    .padding(.bottom, 80)
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Karmic Points")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(CosmicTheme.starlight)
            
            Text("64th Navamsha & 22nd Drekkana")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.secondaryText)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.red.opacity(0.5), .clear],
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
}

struct KharaCard: View {
    let title: String
    let subtitle: String
    let drekLord: String
    let drekSign: String
    let navLord: String
    let navSign: String
    let tint: Color
    
    var body: some View {
        VStack(spacing: 0) {
            // Card Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.caption.bold())
                        .foregroundColor(tint)
                        .tracking(1)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(CosmicTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.title2)
                    .foregroundColor(tint)
            }
            .padding(16)
            .background(tint.opacity(0.1))
            
            Divider().background(tint.opacity(0.3))
            
            // Content Grid
            VStack(spacing: 16) {
                // 22nd Drekkana Row
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(tint.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: "triangle.lefthalf.filled") // Drekkana symbol
                            .foregroundColor(tint)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("22nd Drekkana")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("Lord:")
                                .font(.caption)
                                .foregroundColor(CosmicTheme.secondaryText)
                            Text(drekLord)
                                .font(.caption.bold())
                                .foregroundColor(PlanetStyle.color(for: drekLord))
                            
                            Text("•")
                                .foregroundColor(CosmicTheme.secondaryText)
                            
                            Text("Sign:")
                                .font(.caption)
                                .foregroundColor(CosmicTheme.secondaryText)
                            Text(drekSign)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // 64th Navamsha Row
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(tint.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: "square.grid.3x3.fill") // Navamsha symbol
                            .foregroundColor(tint)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("64th Navamsha")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("Lord:")
                                .font(.caption)
                                .foregroundColor(CosmicTheme.secondaryText)
                            Text(navLord)
                                .font(.caption.bold())
                                .foregroundColor(PlanetStyle.color(for: navLord))
                            
                            Text("•")
                                .foregroundColor(CosmicTheme.secondaryText)
                            
                            Text("Sign:")
                                .font(.caption)
                                .foregroundColor(CosmicTheme.secondaryText)
                            Text(navSign)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(CosmicTheme.midnight.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [tint.opacity(0.5), tint.opacity(0.1), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: tint.opacity(0.15), radius: 15, x: 0, y: 5)
    }
}
