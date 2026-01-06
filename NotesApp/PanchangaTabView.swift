import SwiftUI
import CoreLocation

struct PanchangaTabView: View {
    let dateOfBirth: Date
    let timeOfBirth: Date
    let coordinate: CLLocationCoordinate2D?
    let planetPositions: [PlanetPosition]
    @Environment(\.colorScheme) private var colorScheme

    private func isInIndia(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 6 && coord.latitude <= 36 && coord.longitude >= 68 && coord.longitude <= 98
    }

    private func merge(date: Date, time: Date, in tz: TimeZone) -> Date {
        let cal = Calendar(identifier: .gregorian)
        var dcmp = cal.dateComponents(in: tz, from: date)
        let tcmp = cal.dateComponents(in: tz, from: time)
        dcmp.hour = tcmp.hour
        dcmp.minute = tcmp.minute
        dcmp.second = tcmp.second
        dcmp.nanosecond = 0
        return cal.date(from: dcmp) ?? date
    }

    private var panchangaData: PanchangaResultModel? {
        guard let coord = coordinate else { return nil }
        let tz: TimeZone = isInIndia(coord) ? (TimeZone(identifier: "Asia/Kolkata") ?? .current) : .current
        let dt = merge(date: dateOfBirth, time: timeOfBirth, in: tz)
        return PanchangaCalcIOS.compute(planetPositions: planetPositions, dateTime: dt, timeZone: tz)
    }

    var body: some View {
        ZStack {
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView(showsIndicators: false) {
                    if let p = panchangaData {
                        VStack(spacing: 20) {
                            // Vara (Solar Day)
                            PanchangaCard(
                                title: "Vara",
                                subtitle: "Solar Day",
                                value: p.vara,
                                icon: "sun.max.fill",
                                color: .orange,
                                description: "Governs physical vitality and the ruling planet of the day."
                            )

                            // Tithi (Lunar Day)
                            PanchangaCard(
                                title: "Tithi",
                                subtitle: "Lunar Phase",
                                value: p.tithi,
                                icon: "moonphase.first.quarter",
                                color: .indigo,
                                description: "Influences relationships and emotions. Group: \(p.tithiGroup)."
                            ) {
                                if let meaning = tithiGroupMeaning(p.tithiGroup) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                            .font(.caption)
                                        Text(meaning)
                                            .font(.caption.italic())
                                    }
                                    .foregroundColor(CosmicTheme.starlight.opacity(0.8))
                                    .padding(.top, 4)
                                }
                            }

                            // Nakshatra (Star)
                            PanchangaCard(
                                title: "Nakshatra",
                                subtitle: "Constellation",
                                value: p.nakshatra,
                                icon: "star.fill",
                                color: .cyan,
                                description: "The star governing the mind and destiny patterns."
                            )

                            // Yoga (Union)
                            PanchangaCard(
                                title: "Yoga",
                                subtitle: "Solar-Lunar Union",
                                value: p.yoga,
                                icon: "figure.mind.and.body",
                                color: .teal,
                                description: "Indicates the nature of the union between the individual and the cosmic."
                            ) {
                                Text("Lord: \(p.yogaLord)")
                                    .font(.caption.bold())
                                    .foregroundColor(.teal.opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.teal.opacity(0.1))
                                    .cornerRadius(6)
                                    .padding(.top, 4)
                            }

                            // Karana (Half-Tithi)
                            PanchangaCard(
                                title: "Karana",
                                subtitle: "Half Lunar Day",
                                value: p.karana,
                                icon: "arrow.triangle.2.circlepath",
                                color: .purple,
                                description: "Governs action, achievement and professional success."
                            ) {
                                Text("Lord: \(p.karanaLord)")
                                    .font(.caption.bold())
                                    .foregroundColor(.purple.opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(6)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(20)
                        .padding(.bottom, 80)
                    } else {
                        loadingView
                    }
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Panchanga")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(CosmicTheme.starlight)
            
            Text("The Five Limbs of Time")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.secondaryText)
                .tracking(1)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, CosmicTheme.accent.opacity(0.5), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.top, 8)
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
        .background(CosmicTheme.midnight.opacity(0.4))
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .tint(CosmicTheme.accent)
            Text("Aligning with the cosmos...")
                .font(.subheadline)
                .foregroundColor(CosmicTheme.secondaryText)
            Spacer()
        }
    }

    private func tithiGroupMeaning(_ group: String) -> String? {
        switch group {
        case "Nanda": return "Joy, happiness, pleasure"
        case "Bhadra": return "Auspiciousness, welfare, prosperity"
        case "Jaya": return "Victory, success, overcoming obstacles"
        case "Rikta": return "Emptiness, removal, clearing away"
        case "Poorna": return "Fulfilment, completion, abundance"
        default: return nil
        }
    }
}

struct PanchangaCard<Content: View>: View {
    let title: String
    let subtitle: String
    let value: String
    let icon: String
    let color: Color
    let description: String
    let content: () -> Content

    init(
        title: String,
        subtitle: String,
        value: String,
        icon: String,
        color: Color,
        description: String,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.icon = icon
        self.color = color
        self.description = description
        self.content = content
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon Column
            VStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                Spacer()
            }

            // Content Column
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title.uppercased())
                            .font(.caption.bold())
                            .foregroundColor(color)
                            .tracking(1)
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundColor(CosmicTheme.secondaryText)
                    }
                    Spacer()
                }
                
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(CosmicTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
                
                content()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(CosmicTheme.midnight.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            color.opacity(0.3),
                            color.opacity(0.05),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

