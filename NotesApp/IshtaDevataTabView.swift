import SwiftUI

struct IshtaDevataTabView: View {
    let planetPositions: [PlanetPosition]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                if let res = IshtaDevataCalcIOS.compute(planetPositions: planetPositions) {
                    VStack(spacing: 14) {
                        sectionCard(title: "Ishta Devata", icon: "flame.fill", color: .pink) {
                            gridRow("Atmakaraka", "\(res.atmakaraka) (Rasi: \(res.akRasiSign))")
                            gridRow("AK in Navamsha", res.akNavamsaSign)
                            gridRow("12th from AK (D9)", res.twelfthFromAKNavamsaSign)
                            gridRow("12th Lord", res.twelfthLord)
                            gridRow("12th Occupant (D9)", res.twelfthOccupant ?? "—")
                            Divider().opacity(0.2)
                            HStack(alignment: .center) {
                                Text("Ishta: ").font(.headline)
                                TagBadge(text: res.deity, color: .pink)
                                Spacer()
                            }
                            Text(res.suggestion)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        sectionCard(title: "Palana Devata", icon: "shield.checkerboard", color: .teal) {
                            gridRow("Amatyakaraka", "\(res.amatyakaraka) (Rasi: \(res.amkRasiSign))")
                            gridRow("AMK in Navamsha", res.amkNavamsaSign)
                            gridRow("6th from AMK (D9)", res.sixthFromAMKNavamsaSign)
                            gridRow("6th Lord", res.sixthLord)
                            gridRow("6th Occupant (D9)", res.sixthOccupant ?? "—")
                            Divider().opacity(0.2)
                            HStack(alignment: .center) {
                                Text("Palana: ").font(.headline)
                                TagBadge(text: res.palanaDeity, color: .teal)
                                Spacer()
                            }
                            Text(res.palanaSuggestion)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                        Text("Unable to determine Ishta Devata with current data")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle("Ishta Devata")
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

    private func gridRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

