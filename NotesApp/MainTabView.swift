import SwiftUI

struct TabMetadata: Identifiable, Hashable {
    let id: Int
    let title: String
    let icon: String
    var accent: Color = CosmicTheme.accent
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    let tabsMeta: [TabMetadata]
    @Namespace private var animationNamespace
    private let dockShape = RoundedRectangle(cornerRadius: 30, style: .continuous)

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tabsMeta) { tab in
                    let isSelected = selectedTab == tab.id

                    Button {
                        withAnimation(.snappy(duration: 0.4, extraBounce: 0.15)) {
                            selectedTab = tab.id
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(tab.accent.opacity(isSelected ? 0.16 : 0.0))
                                    .frame(width: 38, height: 38)

                                Image(systemName: tab.icon)
                                    .font(.system(size: 17, weight: isSelected ? .bold : .semibold))
                                    .foregroundStyle(isSelected ? tab.accent : Color.white.opacity(0.66))
                                    .scaleEffect(isSelected ? 1.06 : 1.0)
                            }

                            Text(tab.title)
                                .font(.system(size: 11, weight: isSelected ? .bold : .semibold))
                                .lineLimit(1)
                                .foregroundColor(isSelected ? .white : .white.opacity(0.58))
                        }
                        .frame(minWidth: isSelected ? 82 : 70)
                        .padding(.horizontal, isSelected ? 14 : 10)
                        .padding(.vertical, 12)
                        .background {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(Color.white.opacity(0.015))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                    )

                                if isSelected {
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(tab.accent.opacity(0.14))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                                .stroke(tab.accent.opacity(0.35), lineWidth: 1)
                                        )
                                        .matchedGeometryEffect(id: "activeTabBackground", in: animationNamespace)
                                }
                            }
                        }
                        .shadow(color: isSelected ? tab.accent.opacity(0.18) : .clear, radius: 18, x: 0, y: 10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(
            ZStack {
                dockShape
                    .fill(Color.black.opacity(0.30))

                dockShape
                    .fill(.ultraThinMaterial)
                    .opacity(0.88)

                dockShape
                    .fill(CosmicTheme.auroraGradient.opacity(0.10))
            }
        )
        .clipShape(dockShape)
        .overlay(
            dockShape
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.22),
                            .white.opacity(0.05),
                            CosmicTheme.accent.opacity(0.08),
                            .white.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .overlay(alignment: .top) {
            dockShape
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 24)
                .offset(y: 1)
        }
        .shadow(color: Color.black.opacity(0.45), radius: 24, x: 0, y: 14)
    }
}

struct MainTabView_Previews: PreviewProvider {
    struct PreviewHost: View {
        @State private var selected = 0
        private let tabs = [
            TabMetadata(id: 0, title: "Birth", icon: "person.crop.circle", accent: .mint),
            TabMetadata(id: 1, title: "Dasha", icon: "moon.stars.fill", accent: .purple),
            TabMetadata(id: 2, title: "Yogi", icon: "sun.max", accent: .orange),
            TabMetadata(id: 3, title: "More", icon: "ellipsis.circle", accent: .gray)
        ]
        var body: some View {
            ZStack {
                CosmicTheme.backgroundDeep.ignoresSafeArea()
                VStack {
                    Spacer()
                    MainTabView(selectedTab: $selected, tabsMeta: tabs)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
        }
    }

    static var previews: some View {
        PreviewHost()
            .preferredColorScheme(.dark)
    }
}
