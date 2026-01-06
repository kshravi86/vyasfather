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
                    // Deep Space Base
                    CosmicTheme.deepSpace
                        .ignoresSafeArea()
                    
                    let glowSize = max(size.width, size.height)
                    
                    // Rotating Nebula Layers
                    Group {
                        // Cyan/Blue Nebula
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        CosmicTheme.accentSoft.opacity(0.2),
                                        Color.blue.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: glowSize * 1.2, height: glowSize * 1.2)
                            .offset(x: -size.width * 0.2, y: -size.height * 0.2)
                            .blur(radius: 120)
                            .rotationEffect(.degrees(animate ? 360 : 0))
                            .animation(.linear(duration: 120).repeatForever(autoreverses: false), value: animate)

                        // Gold/Orange Nebula
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        CosmicTheme.accent.opacity(0.15),
                                        Color.orange.opacity(0.05)
                                    ],
                                    startPoint: .bottomLeading,
                                    endPoint: .topTrailing
                                )
                            )
                            .frame(width: glowSize * 1.0, height: glowSize * 1.0)
                            .offset(x: size.width * 0.3, y: size.height * 0.3)
                            .blur(radius: 100)
                            .rotationEffect(.degrees(animate ? -360 : 0))
                            .animation(.linear(duration: 150).repeatForever(autoreverses: false), value: animate)
                        
                        // Deep Purple/Midnight Nebula (New Layer)
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [CosmicTheme.nebula.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: glowSize * 0.6
                                )
                            )
                            .frame(width: glowSize * 1.5, height: glowSize * 0.8)
                            .rotationEffect(.degrees(45))
                            .offset(y: size.height * 0.1)
                            .blur(radius: 80)
                            .blendMode(.overlay)
                    }

                    // Subtle Pulse Overlay
                    AngularGradient(
                        colors: [
                            CosmicTheme.midnight.opacity(0.3),
                            Color.clear,
                            CosmicTheme.midnight.opacity(0.2)
                        ],
                        center: .center
                    )
                    .scaleEffect(animate ? 1.1 : 1.0)
                    .opacity(0.5)
                    .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)

                    // Star Field
                    Canvas { context, canvasSize in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        for (index, point) in starSeeds.enumerated() {
                            let x = point.x * canvasSize.width
                            let y = point.y * canvasSize.height
                            let sparkle = 1.4 + Double((index % 5)) * 0.6
                            let rect = CGRect(x: x, y: y, width: sparkle, height: sparkle)
                            let baseOpacity = 0.25 + Double((index % 7)) * 0.09
                            let twinkle = sin(time * 0.8 + Double(index) * 0.7) * 0.3
                            let color = Color.white.opacity(max(0.1, baseOpacity + twinkle))
                            context.fill(Path(ellipseIn: rect), with: .color(color))
                        }
                    }
                    .drawingGroup()
                    .ignoresSafeArea()

                    // Vignette
                    RadialGradient(
                        colors: [Color.clear, Color.black.opacity(0.6)],
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
