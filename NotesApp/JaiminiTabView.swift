import SwiftUI

struct JaiminiTabView: View {
    let planetPositions: [PlanetPosition]
    let houses: [(index: Int, sign: String, deg: Int, min: Int)]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    sectionCard(title: "Chara Karakas", icon: "text.badge.star", color: .orange) {
                        let karakas = JaiminiKarakasCalc.compute(planetPositions: planetPositions, houses: houses, includeRahu: false)
                        VStack(spacing: 8) {
                            ForEach(karakas) { e in
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    PlanetChip(name: e.karakaName)
                                    TagBadge(text: shortCode(for: e.karakaName), color: .orange)
                                    Text(e.planetName)
                                        .font(.subheadline)
                                    TagBadge(text: "#\(e.rank)", color: PlanetStyle.color(for: e.planetName))
                                    Spacer()
                                }
                            }
                        }
                    }

                    sectionCard(title: "Arudha Padas", icon: "seal", color: .indigo) {
                        let arudhas = JaiminiArudhaCalc.compute(planetPositions: planetPositions, houses: houses)
                        VStack(spacing: 8) {
                            ForEach(arudhas) { a in
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text("House \(a.house)").font(.subheadline)
                                    Spacer()
                                    Text("Sign: \(a.houseSign)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text("Lord: \(a.lord) (H\(a.lordHouse) \(a.lordSign))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("Pada: H\(a.padaHouse) \(a.padaSign)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.bottom, 4)
                                Divider().opacity(0.2)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Jaimini")
            .background(WaterTheme.gradient(for: colorScheme))
        }
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

    private func shortCode(for karaka: String) -> String {
        switch karaka.lowercased() {
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
}
