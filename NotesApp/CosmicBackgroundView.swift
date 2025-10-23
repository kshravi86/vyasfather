import SwiftUI

struct CosmicBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animate = false

    private let starSeeds: [CGPoint] = (0..<80).map { index in
        let x = Double((index * 37) % 97) / 97.0
        let y = Double((index * 53) % 89) / 89.0
        return CGPoint(x: x, y: y)
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            TimelineView(.animation) { timeline in
                ZStack {
                    CosmicTheme.gradient(for: colorScheme)
                        .ignoresSafeArea()
                    AngularGradient(
                        colors: [
                            Color.purple.opacity(0.35),
                            Color.blue.opacity(0.2),
                            Color.indigo.opacity(0.4),
                            Color.orange.opacity(0.25)
                        ],
                        center: .center
                    )
                    .scaleEffect(animate ? 1.3 : 1.0)
                    .rotationEffect(.degrees(animate ? 360 : 0))
                    .animation(.linear(duration: 60).repeatForever(autoreverses: false), value: animate)
                    .blendMode(.screen)

                    Canvas { context, canvasSize in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        for (index, point) in starSeeds.enumerated() {
                            let x = point.x * canvasSize.width
                            let y = point.y * canvasSize.height
                            let sparkle = 1.4 + Double((index % 5)) * 0.6
                            let rect = CGRect(x: x, y: y, width: sparkle, height: sparkle)
                            let baseOpacity = 0.25 + Double((index % 7)) * 0.09
                            let twinkle = sin(time * 1.2 + Double(index) * 0.7) * 0.2
                            let color = Color.white.opacity(max(0.05, baseOpacity + twinkle))
                            context.fill(Path(ellipseIn: rect), with: .color(color))
                        }
                    }
                    .drawingGroup()
                    .ignoresSafeArea()

                    RadialGradient(
                        colors: [Color.black.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: max(size.width, size.height)
                    )
                    .ignoresSafeArea()
                }
            }
        }
        .onAppear { animate = true }
    }
}

struct CosmicBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        CosmicBackgroundView()
    }
}
