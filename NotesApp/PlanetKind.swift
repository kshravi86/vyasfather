import SwiftUI

enum PlanetKind: String, CaseIterable {
    case sun, moon, mars, mercury, jupiter, venus, saturn, rahu, ketu

    init?(label: String) {
        let key = label
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard let resolved = PlanetKind.aliases[key] else { return nil }
        self = resolved
    }

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .sun: return .yellow
        case .moon: return .cyan
        case .mars: return .red
        case .mercury: return .mint
        case .jupiter: return .orange
        case .venus: return .pink
        case .saturn: return .indigo
        case .rahu: return .purple
        case .ketu: return .gray
        }
    }

    var iconName: String {
        switch self {
        case .sun: return "sun.max.fill"
        case .moon: return "moon.fill"
        case .mars: return "flame.fill"
        case .mercury: return "bolt.fill"
        case .jupiter: return "sparkles"
        case .venus: return "heart.fill"
        case .saturn: return "globe.americas.fill"
        case .rahu: return "arrow.up.circle.fill"
        case .ketu: return "arrow.down.circle.fill"
        }
    }

    private static let aliases: [String: PlanetKind] = {
        var map: [String: PlanetKind] = [:]
        func register(_ labels: [String], as kind: PlanetKind) {
            for label in labels {
                map[label] = kind
            }
        }
        register(["sun", "surya"], as: .sun)
        register(["moon", "chandra"], as: .moon)
        register(["mars", "mangala", "kuja"], as: .mars)
        register(["mercury", "budha"], as: .mercury)
        register(["jupiter", "guru", "brihaspati"], as: .jupiter)
        register(["venus", "shukra"], as: .venus)
        register(["saturn", "shani"], as: .saturn)
        register(["rahu"], as: .rahu)
        register(["ketu"], as: .ketu)
        return map
    }()
}
