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

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tabsMeta) { tab in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTab = tab.id
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                if selectedTab == tab.id {
                                    Circle()
                                        .fill(tab.accent.opacity(0.22))
                                        .frame(width: 44, height: 44)
                                        .matchedGeometryEffect(id: "iconBackground", in: animationNamespace)
                                }
                                Image(systemName: tab.icon)
                                    .font(.title3)
                                    .foregroundStyle(selectedTab == tab.id ? tab.accent : Color.white.opacity(0.7))
                            }
                            Text(tab.title)
                                .font(.caption2.weight(selectedTab == tab.id ? .bold : .regular))
                                .lineLimit(1)
                                .foregroundColor(selectedTab == tab.id ? .white : .white.opacity(0.65))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(selectedTab == tab.id ? 0.18 : 0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.white.opacity(selectedTab == tab.id ? 0.45 : 0.15), lineWidth: 1)
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(selectedTab == tab.id ? 0.25 : 0.05),
                            radius: selectedTab == tab.id ? 12 : 4,
                            x: 0,
                            y: 4
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 12)
    }
}

struct MainTabView_Previews: PreviewProvider {
    struct PreviewHost: View {
        @State private var selected = 0
        private let tabs = [
            TabMetadata(id: 0, title: "Birth", icon: "person.crop.circle"),
            TabMetadata(id: 1, title: "Dasha", icon: "moon.stars.fill"),
            TabMetadata(id: 2, title: "Yogi", icon: "sun.max"),
            TabMetadata(id: 3, title: "More", icon: "ellipsis.circle")
        ]
        var body: some View {
            ZStack {
                CosmicBackgroundView()
                VStack {
                    Spacer()
                    MainTabView(selectedTab: $selected, tabsMeta: tabs)
                }
                .padding()
            }
        }
    }

    static var previews: some View {
        PreviewHost()
            .preferredColorScheme(.dark)
    }
}
