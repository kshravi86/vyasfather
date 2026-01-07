import SwiftUI

struct JaiminiTabView: View {
    let planetPositions: [PlanetPosition]
    let houses: [(index: Int, sign: String, deg: Int, min: Int)]
    @Environment(\.colorScheme) private var colorScheme

    private var karakas: [KarakaEntryModel] {
        JaiminiKarakasCalc.compute(planetPositions: planetPositions, houses: houses, includeRahu: false)
    }
    
    private var arudhas: [ArudhaEntryModel] {
        JaiminiArudhaCalc.compute(planetPositions: planetPositions, houses: houses)
    }

    var body: some View {
        ZStack {
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        karakaSection
                        arudhaSection
                    }
                    .padding(20)
                    .padding(.bottom, 80)
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Jaimini Sutras")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(CosmicTheme.starlight)
            
            Text("Soul signifiers and social reflections")
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
    
    private var karakaSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Chara Karakas", systemImage: "sparkles.rectangle.stack.fill")
                    .font(.title3.weight(.bold))
                    .foregroundColor(CosmicTheme.starlight)
                Text("Planets as dynamic signifiers of the soul's journey")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
            }
            
            VStack(spacing: 12) {
                ForEach(karakas) { karaka in
                    KarakaCard(karaka: karaka)
                }
            }
        }
    }
    
    private var arudhaSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Arudha Padas", systemImage: "mirror.side.left")
                    .font(.title3.weight(.bold))
                    .foregroundColor(CosmicTheme.starlight)
                Text("The manifest reflection of houses in the material world")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(arudhas) { arudha in
                    ArudhaCard(arudha: arudha)
                }
            }
        }
    }
}

struct KarakaCard: View {
    let karaka: KarakaEntryModel
    
    private var isAtmakaraka: Bool { karaka.rank == 1 }
    private var shortCode: String {
        switch karaka.karakaName.lowercased() {
        case "atmakaraka": return "AK"
        case "amatyakaraka": return "AmK"
        case "bhratrikaraka": return "BK"
        case "matrikaraka": return "MK"
        case "putrakaraka": return "PK"
        case "gnatikaraka": return "GK"
        case "darakaraka": return "DK"
        default: return "K"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank / Code
            ZStack {
                Circle()
                    .fill(isAtmakaraka ? Color.yellow.opacity(0.2) : CosmicTheme.midnight.opacity(0.5))
                    .frame(width: 44, height: 44)
                
                Text(shortCode)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(isAtmakaraka ? .yellow : .white.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(karaka.karakaName)
                    .font(.headline.weight(.medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Text(karaka.planetName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(PlanetStyle.color(for: karaka.planetName))
                    
                    Text("in \(karaka.sign)")
                        .font(.caption)
                        .foregroundColor(CosmicTheme.secondaryText)
                    
                    Text(String(format: "%.2f°", karaka.degreeInSign))
                        .font(.caption.monospaced())
                        .foregroundColor(CosmicTheme.secondaryText)
                }
            }
            
            Spacer()
            
            if isAtmakaraka {
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 8)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isAtmakaraka ? CosmicTheme.accent.opacity(0.05) : CosmicTheme.midnight.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: isAtmakaraka 
                            ? [.yellow.opacity(0.4), .orange.opacity(0.1)] 
                            : [.white.opacity(0.1), .white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct ArudhaCard: View {
    let arudha: ArudhaEntryModel
    
    private var isSpecial: Bool { arudha.house == 1 || arudha.house == 12 }
    private var code: String {
        switch arudha.house {
        case 1: return "AL" // Arudha Lagna
        case 12: return "UL" // Upapada Lagna
        default: return "A\(arudha.house)"
        }
    }
    
    private var tint: Color {
        if arudha.house == 1 { return .mint }
        if arudha.house == 12 { return .pink }
        return .indigo
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(code)
                    .font(.headline.weight(.bold))
                    .foregroundColor(tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tint.opacity(0.15))
                    .cornerRadius(6)
                
                Spacer()
                
                if isSpecial {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(tint)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(arudha.padaSign)
                    .font(.title3.weight(.medium))
                    .foregroundColor(.white)
                
                Text("Lord: \(arudha.lord)")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(CosmicTheme.midnight.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSpecial ? tint.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
