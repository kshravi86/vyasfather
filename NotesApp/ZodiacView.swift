import SwiftUI

struct ZodiacView: View {
    let planetPositions: [PlanetPosition]

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)

            ForEach(0..<12) { i in
                let angle = Angle(degrees: Double(i) * 30 - 90)
                let sign = ZodiacSign(rawValue: i) ?? .aries

                VStack {
                    Text(sign.displayName.prefix(3))
                        .font(.caption)
                        .foregroundColor(CosmicTheme.secondaryText)
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 1, height: 10)
                }
                .rotationEffect(angle + Angle(degrees: 90))
                .offset(x: 120)
                .rotationEffect(angle)
            }

            ForEach(planetPositions) { position in
                let angle = Angle(degrees: position.longitude - 90)
                let color = PlanetStyle.color(for: position.name)

                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                    Text(position.name.prefix(2))
                        .font(.system(size: 6))
                        .foregroundColor(.black)
                }
                .offset(x: 100)
                .rotationEffect(angle)
            }
        }
        .frame(width: 240, height: 240)
    }
}
