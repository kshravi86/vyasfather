import SwiftUI

struct CosmicBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animate = false

    private let starSeeds: [CGPoint] = (0..<64).map { index in
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

                    let glowSize = max(size.width, size.height)

                    Group {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        CosmicTheme.accentSoft.opacity(0.34),
                                        CosmicTheme.nebula.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: glowSize * 1.08, height: glowSize * 1.08)
                            .offset(x: -size.width * 0.24, y: -size.height * 0.20)
                            .blur(radius: 150)
                            .rotationEffect(.degrees(animate ? 360 : 0))
                            .blendMode(.screen)
                            .animation(.linear(duration: 140).repeatForever(autoreverses: false), value: animate)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        CosmicTheme.rose.opacity(0.30),
                                        CosmicTheme.ember.opacity(0.10)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: glowSize * 0.96, height: glowSize * 0.96)
                            .offset(x: size.width * 0.34, y: -size.height * 0.12)
                            .blur(radius: 135)
                            .rotationEffect(.degrees(animate ? -360 : 0))
                            .blendMode(.screen)
                            .animation(.linear(duration: 160).repeatForever(autoreverses: false), value: animate)

                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [CosmicTheme.violet.opacity(0.26), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: glowSize * 0.6
                                )
                            )
                            .frame(width: glowSize * 1.35, height: glowSize * 0.72)
                            .rotationEffect(.degrees(35))
                            .offset(x: size.width * 0.08, y: size.height * 0.26)
                            .blur(radius: 110)
                            .blendMode(.screen)

                        Ellipse()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.12), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: glowSize * 1.30, height: glowSize * 0.54)
                            .offset(y: -size.height * 0.32)
                            .blur(radius: 90)
                            .blendMode(.screen)
                    }

                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.clear,
                            CosmicTheme.accentSoft.opacity(0.08),
                            Color.clear
                        ],
                        center: .center
                    )
                    .scaleEffect(animate ? 1.1 : 1.0)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animate)

                    Canvas { context, canvasSize in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        for (index, point) in starSeeds.enumerated() {
                            let x = point.x * canvasSize.width
                            let y = point.y * canvasSize.height
                            let sparkle = 1.0 + Double((index % 4)) * 0.55
                            let rect = CGRect(x: x, y: y, width: sparkle, height: sparkle)
                            let baseOpacity = 0.14 + Double((index % 6)) * 0.05
                            let twinkle = sin(time * 0.8 + Double(index) * 0.7) * 0.18
                            let color = Color.white.opacity(max(0.06, baseOpacity + twinkle))
                            context.fill(Path(ellipseIn: rect), with: .color(color))
                        }
                    }
                    .drawingGroup()
                    .ignoresSafeArea()

                    LinearGradient(
                        colors: [Color.white.opacity(0.10), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .blendMode(.screen)
                    .ignoresSafeArea()

                    RadialGradient(
                        colors: [Color.clear, Color.black.opacity(0.34)],
                        center: .center,
                        startRadius: size.width * 0.4,
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
