import Foundation

struct PanchangaResultModel {
    let tithi: String
    let tithiGroup: String
    let vara: String
    let nakshatra: String
    let yoga: String
    let karana: String
    let yogaLord: String
    let karanaLord: String
}

enum PanchangaCalcIOS {
    private static func normalize(_ deg: Double) -> Double {
        var x = deg.truncatingRemainder(dividingBy: 360.0)
        if x < 0 { x += 360.0 }
        return x
    }

    private static let tithiNames: [String] = [
        "Pratipada","Dvitiya","Tritiya","Chaturthi","Panchami",
        "Shashthi","Saptami","Ashtami","Navami","Dashami",
        "Ekadashi","Dvadashi","Trayodashi","Chaturdashi","Purnima",
        "Pratipada","Dvitiya","Tritiya","Chaturthi","Panchami",
        "Shashthi","Saptami","Ashtami","Navami","Dashami",
        "Ekadashi","Dvadashi","Trayodashi","Chaturdashi","Amavasya"
    ]

    private static let yogaNames: [String] = [
        "Vishkambha","Priti","Ayushman","Saubhagya","Shobhana",
        "Atiganda","Sukarma","Dhriti","Shoola","Ganda",
        "Vriddhi","Dhruva","Vyaghata","Harshana","Vajra",
        "Siddhi","Vyatipata","Variyan","Parigha","Shiva",
        "Siddha","Sadhya","Shubha","Shukla","Brahma",
        "Indra","Vaidhriti"
    ]

    private static let karanaMovable: [String] = ["Bava","Balava","Kaulava","Taitila","Gara","Vanija","Vishti"]

    static func tithiName(moon: Double, sun: Double) -> String {
        let diff = normalize(moon - sun)
        let idx = Int(floor(diff / 12.0)).clamped(to: 0...29)
        let paksha = (idx < 15) ? "Shukla" : "Krishna"
        return "\(paksha) \(tithiNames[idx])"
    }

    static func yogaName(moon: Double, sun: Double) -> String {
        let sum = normalize(moon + sun)
        let idx = Int(floor(sum / (360.0 / 27.0))).clamped(to: 0...26)
        return yogaNames[idx]
    }

    static func karanaName(moon: Double, sun: Double) -> String {
        let diff = normalize(moon - sun)
        let halfIdx = Int(floor(diff / 6.0)) + 1 // 1..60
        switch halfIdx {
        case 1: return "Kimstughna"
        case 2...57:
            return karanaMovable[(halfIdx - 2) % 7]
        case 58: return "Shakuni"
        case 59: return "Chatushpada"
        case 60: return "Naga"
        default: return ""
        }
    }

    static func tithiGroupName(moon: Double, sun: Double) -> String {
        let diff = normalize(moon - sun)
        let idx = Int(floor(diff / 12.0)).clamped(to: 0...29)
        let inPaksha = idx % 15
        switch (inPaksha + 1) % 5 {
        case 1: return "Nanda"
        case 2: return "Bhadra"
        case 3: return "Jaya"
        case 4: return "Rikta"
        default: return "Poorna"
        }
    }

    static func varaName(for date: Date, timeZone: TimeZone) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let wd = cal.component(.weekday, from: date)
        // 1=Sunday per Gregorian
        switch wd {
        case 1: return "Ravivara"
        case 2: return "Somavara"
        case 3: return "Mangalavara"
        case 4: return "Budhavara"
        case 5: return "Guruvara"
        case 6: return "Shukravara"
        default: return "Shanivara"
        }
    }

    static func compute(planetPositions: [PlanetPosition], dateTime: Date, timeZone: TimeZone) -> PanchangaResultModel {
        let sun = planetPositions.first { $0.name == "Sun" }?.longitude ?? 0.0
        let moon = planetPositions.first { $0.name == "Moon" }?.longitude ?? 0.0
        let tithi = tithiName(moon: moon, sun: sun)
        let yoga = yogaName(moon: moon, sun: sun)
        let karana = karanaName(moon: moon, sun: sun)
        let vara = varaName(for: dateTime, timeZone: timeZone)
        let nak: String = {
            if let m = planetPositions.first(where: { $0.name == "Moon" }) {
                return "\(m.nakshatra) • Pada \(m.pada)"
            }
            return "—"
        }()
        return PanchangaResultModel(
            tithi: tithi,
            tithiGroup: tithiGroupName(moon: moon, sun: sun),
            vara: vara,
            nakshatra: nak,
            yoga: yoga,
            karana: karana,
            yogaLord: yogaLordOf(yoga),
            karanaLord: karanaLordOf(karana)
        )
    }

    private static let weekdayPlanets = ["Sun","Moon","Mars","Mercury","Jupiter","Venus","Saturn"]

    static func yogaLordOf(_ yoga: String) -> String {
        guard let idx = yogaNames.firstIndex(of: yoga) else { return "—" }
        return weekdayPlanets[idx % weekdayPlanets.count]
    }

    static func karanaLordOf(_ karana: String) -> String {
        let movable: [String:String] = [
            "Bava":"Sun","Balava":"Moon","Kaulava":"Mars","Taitila":"Mercury","Gara":"Jupiter","Vanija":"Venus","Vishti":"Saturn"
        ]
        return movable[karana] ?? "—"
    }
}

extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int { Swift.min(Swift.max(self, range.lowerBound), range.upperBound) }
}

