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
                    let isSelected = selectedTab == tab.id
                    
                    Button {
                        withAnimation(.snappy(duration: 0.4, extraBounce: 0.15)) {
                            selectedTab = tab.id
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? tab.accent : Color.white.opacity(0.6))
                                .scaleEffect(isSelected ? 1.1 : 1.0)
                            
                            Text(tab.title)
                                .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                                .lineLimit(1)
                                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(tab.accent.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(tab.accent.opacity(0.3), lineWidth: 1)
                                    )
                                    .matchedGeometryEffect(id: "activeTabBackground", in: animationNamespace)
                            } else {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
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
