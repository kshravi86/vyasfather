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
            HStack(spacing: 8) {
                ForEach(tabsMeta) { tab in
                    let isSelected = selectedTab == tab.id
                    
                    Button {
                        withAnimation(.snappy(duration: 0.4, extraBounce: 0.15)) {
                            selectedTab = tab.id
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? tab.accent : Color.white.opacity(0.5))
                                .scaleEffect(isSelected ? 1.1 : 1.0)
                            
                            Text(tab.title)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                .lineLimit(1)
                                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                        }
                        .frame(width: 64)
                        .padding(.vertical, 10)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(tab.accent.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(tab.accent.opacity(0.3), lineWidth: 1)
                                    )
                                    .matchedGeometryEffect(id: "activeTabBackground", in: animationNamespace)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(
            ZStack {
                CosmicTheme.midnight.opacity(0.7)
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.9)
            }
        )
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.2),
                            .white.opacity(0.05),
                            .white.opacity(0.05),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
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
