import SwiftUI

struct MainTabView: View {
    @Binding var selectedTab: Int
    let tabsMeta: [TabMeta]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tabsMeta) { meta in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = meta.id
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: meta.icon)
                                .font(.subheadline)
                            Text(meta.title)
                                .font(.caption)
                                .fontWeight(selectedTab == meta.id ? .bold : .medium)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(minWidth: 80)
                        .background(selectedTab == meta.id ? CosmicTheme.accent.opacity(0.2) : Color.clear)
                        .foregroundColor(selectedTab == meta.id ? CosmicTheme.accent : CosmicTheme.text)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(CosmicTheme.background.opacity(0.9))
        }
    }
}
