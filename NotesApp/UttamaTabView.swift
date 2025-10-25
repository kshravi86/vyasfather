import SwiftUI

struct UttamaTabView: View {
    let planetPositions: [PlanetPosition]
    let ascendant: (sign: String, deg: Int, min: Int)?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    if let asc = ascendant, let z = ZodiacSign.from(name: asc.sign) {
                        sectionCard(title: "Ascendant", icon: "arrow.up.right", color: .orange) {
                            let abs = Double(z.rawValue) * 30.0 + Double(asc.deg) + Double(asc.min)/60.0
                            let ok = DrekkanaUtils.isUttamaDrekkana(sign: z, absoluteDegree: abs)
                            row(name: "Ascendant", sign: z.displayName, abs: abs, ok: ok)
                        }
                    }

                    sectionCard(title: "Planets", icon: "sparkles", color: .indigo) {
                        VStack(spacing: 8) {
                            ForEach(planetPositions) { pos in
                                if let z = ZodiacSign.from(name: pos.sign) {
                                    let ok = DrekkanaUtils.isUttamaDrekkana(sign: z, absoluteDegree: pos.longitude)
                                    row(name: pos.name + (pos.retrograde ? " (℞)" : ""), sign: z.displayName, abs: pos.longitude, ok: ok)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Uttama Drekkana")
            .background(CosmicTheme.gradient(for: colorScheme).ignoresSafeArea())
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private func sectionCard<T: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> T) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.headline)
            }
            content()
        }
        .cardBackground()
    }

    private func row(name: String, sign: String, abs: Double, ok: Bool) -> some View {
        let raw = abs.truncatingRemainder(dividingBy: 30.0)
        let dInSign = raw < 0 ? (raw + 30.0) : raw
        let deg = Int(floor(dInSign))
        let min = Int(floor((dInSign - Double(deg)) * 60.0 + 0.5))
        return HStack(alignment: .firstTextBaseline) {
            PlanetChip(name: name)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(sign) \(deg)°\(min)'")
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                if let z = ZodiacSign.from(name: sign) {
                    Text("Uttama: \(ok ? "Yes" : "No")  •  \(DrekkanaUtils.rangeDescription(for: z))")
                        .font(.caption2)
                        .foregroundColor(ok ? .green : CosmicTheme.secondaryText)
                }
            }
        }
    }
}

