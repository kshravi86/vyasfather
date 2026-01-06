import SwiftUI

struct UttamaTabView: View {
    let planetPositions: [PlanetPosition]
    let ascendant: (sign: String, deg: Int, min: Int)?
    @Environment(\.colorScheme) private var colorScheme

    private struct EvaluatedBody: Identifiable {
        let id = UUID()
        let name: String
        let sign: String
        let absoluteDegree: Double
        let isUttama: Bool
        let rangeDesc: String
        
        var degreeInSign: String {
            let raw = absoluteDegree.truncatingRemainder(dividingBy: 30.0)
            let dInSign = raw < 0 ? (raw + 30.0) : raw
            let deg = Int(floor(dInSign))
            let min = Int(floor((dInSign - Double(deg)) * 60.0 + 0.5))
            return "\(deg)°\(min)'"
        }
    }

    private var evaluatedBodies: [EvaluatedBody] {
        var bodies: [EvaluatedBody] = []
        
        // Ascendant
        if let asc = ascendant, let z = ZodiacSign.from(name: asc.sign) {
            let abs = Double(z.rawValue) * 30.0 + Double(asc.deg) + Double(asc.min)/60.0
            let ok = DrekkanaUtils.isUttamaDrekkana(sign: z, absoluteDegree: abs)
            bodies.append(EvaluatedBody(
                name: "Ascendant",
                sign: z.displayName,
                absoluteDegree: abs,
                isUttama: ok,
                rangeDesc: DrekkanaUtils.rangeDescription(for: z)
            ))
        }
        
        // Planets
        for pos in planetPositions {
            if let z = ZodiacSign.from(name: pos.sign) {
                let ok = DrekkanaUtils.isUttamaDrekkana(sign: z, absoluteDegree: pos.longitude)
                let name = pos.name + (pos.retrograde ? " (R)" : "")
                bodies.append(EvaluatedBody(
                    name: name,
                    sign: z.displayName,
                    absoluteDegree: pos.longitude,
                    isUttama: ok,
                    rangeDesc: DrekkanaUtils.rangeDescription(for: z)
                ))
            }
        }
        return bodies
    }
    
    private var uttamaBodies: [EvaluatedBody] {
        evaluatedBodies.filter { $0.isUttama }
    }
    
    private var normalBodies: [EvaluatedBody] {
        evaluatedBodies.filter { !$0.isUttama }
    }

    var body: some View {
        ZStack {
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Uttama Section
                        if !uttamaBodies.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Royal Alignment", systemImage: "crown.fill")
                                    .font(.headline)
                                    .foregroundColor(.yellow)
                                    .padding(.horizontal, 4)
                                
                                ForEach(uttamaBodies) { body in
                                    UttamaCard(bodyModel: body)
                                }
                            }
                        } else {
                            // Empty Uttama State
                            VStack(spacing: 12) {
                                Image(systemName: "circle.dashed")
                                    .font(.largeTitle)
                                    .foregroundColor(CosmicTheme.secondaryText.opacity(0.5))
                                Text("No planets in Uttama Drekkana")
                                    .font(.subheadline)
                                    .foregroundColor(CosmicTheme.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        
                        // Normal Section
                        if !normalBodies.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Planetary Positions", systemImage: "circle.grid.cross")
                                    .font(.headline)
                                    .foregroundColor(CosmicTheme.starlight)
                                    .padding(.horizontal, 4)
                                
                                VStack(spacing: 0) {
                                    ForEach(Array(normalBodies.enumerated()), id: \.element.id) { index, body in
                                        CompactBodyRow(bodyModel: body)
                                        if index < normalBodies.count - 1 {
                                            Divider().background(Color.white.opacity(0.1))
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                                .background(CosmicTheme.midnight.opacity(0.6))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 80)
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Uttama Drekkana")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(CosmicTheme.starlight)
            
            Text("Positions of highest dignity in D3")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.secondaryText)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.yellow.opacity(0.5), .clear],
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

struct UttamaCard: View {
    let bodyModel: UttamaTabView.EvaluatedBody
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 52, height: 52)
                Circle()
                    .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                    .frame(width: 52, height: 52)
                Image(systemName: PlanetStyle.icon(for: bodyModel.name))
                    .font(.title2)
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bodyModel.name)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Text("in \(bodyModel.sign) at \(bodyModel.degreeInSign)")
                    .font(.subheadline)
                    .foregroundColor(CosmicTheme.starlight)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("UTTAMA")
                    .font(.caption.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.yellow))
                Text(bodyModel.rangeDesc)
                    .font(.caption2)
                    .foregroundColor(CosmicTheme.secondaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(CosmicTheme.midnight.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.yellow.opacity(0.6), .orange.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.yellow.opacity(0.15), radius: 15, x: 0, y: 5)
    }
}

struct CompactBodyRow: View {
    let bodyModel: UttamaTabView.EvaluatedBody
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: PlanetStyle.icon(for: bodyModel.name))
                    .font(.subheadline)
                    .foregroundColor(PlanetStyle.color(for: bodyModel.name))
                    .frame(width: 20)
                Text(bodyModel.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Text("\(bodyModel.sign) \(bodyModel.degreeInSign)")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                
                // Status indicator (dot)
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

