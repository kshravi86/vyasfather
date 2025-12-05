import CoreData
import Foundation

/// Activity presets that influence the auto-generated daily hydration goal.
enum ActivityLevel: String, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    /// Extra millilitres we add on top of the base weight calculation.
    var activityBonusMl: Double {
        switch self {
        case .low:
            return 0
        case .medium:
            return 350
        case .high:
            return 700
        }
    }
}

/// Fallback values used when the user has not configured hydration yet.
private enum HydrationDefaults {
    static let weightKg: Double = 70
    static let activityLevel: ActivityLevel = .medium
    static let cupSizes: [Int] = [250, 350, 500]
    static let minimumGoal: Double = 1_500
}

struct HydrationCalculator {
    /// Returns a goal in millilitres using weight and activity cues, enforcing a reasonable floor.
    static func goalMl(weightKg: Double?, activity: ActivityLevel?) -> Int64 {
        let base = ((weightKg ?? HydrationDefaults.weightKg) * 35).rounded()
        let adjusted = base + (activity ?? HydrationDefaults.activityLevel).activityBonusMl
        return Int64(max(HydrationDefaults.minimumGoal, adjusted))
    }
}

/// Encodes/decodes cup-size preferences persisted as JSON in Core Data. Keeps
/// the values positive, deduplicated, and sorted to avoid UI surprises.
private enum HydrationCupSizeCodec {
    static func decode(_ value: String?) -> [Int] {
        guard let raw = value,
              let data = raw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([Int].self, from: data) else {
            return HydrationDefaults.cupSizes
        }
        let sanitized = decoded.filter { $0 > 0 }
        return sanitized.isEmpty ? HydrationDefaults.cupSizes : sanitized
    }

    static func encode(_ sizes: [Int]) -> String {
        let sanitized = Array(Set(sizes.filter { $0 > 0 })).sorted()
        let payload = sanitized.isEmpty ? HydrationDefaults.cupSizes : sanitized
        guard let data = try? JSONEncoder().encode(payload),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }
}

/// Core Data access layer for hydration settings so SwiftUI views do not juggle
/// fetch requests and persistence rules on their own.
enum HydrationSettingsStore {
    /// Returns the existing settings row or creates one with sensible defaults.
    /// Missing values are backfilled to avoid crashing older payloads.
    static func fetchOrCreate(in context: NSManagedObjectContext) -> UserSettings {
        let request = NSFetchRequest<UserSettings>(entityName: "UserSettings")
        request.fetchLimit = 1

        if let existing = (try? context.fetch(request))?.first {
            ensureDefaultsIfNeeded(existing, context: context)
            return existing
        }

        let settings = UserSettings(context: context)
        settings.weightKg = HydrationDefaults.weightKg
        settings.activityLevel = HydrationDefaults.activityLevel.rawValue
        settings.dailyGoalMl = HydrationCalculator.goalMl(weightKg: settings.weightKg, activity: .medium)
        settings.cupSizes = HydrationCupSizeCodec.encode(HydrationDefaults.cupSizes)
        persistIfNeeded(context)
        return settings
    }

    /// Convenience accessor to avoid leaking JSON decoding to the UI layer.
    static func cupSizes(from settings: UserSettings) -> [Int] {
        HydrationCupSizeCodec.decode(settings.cupSizes)
    }

    /// Writes cup sizes and keeps storage format consistent.
    static func setCupSizes(_ sizes: [Int], for settings: UserSettings) {
        settings.cupSizes = HydrationCupSizeCodec.encode(sizes)
    }

    private static func ensureDefaultsIfNeeded(_ settings: UserSettings, context: NSManagedObjectContext) {
        var didChange = false
        if settings.dailyGoalMl == 0 {
            settings.dailyGoalMl = HydrationCalculator.goalMl(weightKg: settings.weightKg, activity: .medium)
            didChange = true
        }
        if settings.cupSizes?.isEmpty ?? true {
            settings.cupSizes = HydrationCupSizeCodec.encode(HydrationDefaults.cupSizes)
            didChange = true
        }
        if didChange {
            persistIfNeeded(context)
        }
    }

    private static func persistIfNeeded(_ context: NSManagedObjectContext) {
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            assertionFailure("Failed to persist hydration settings: \(error)")
        }
    }
}

/// Legacy alias used by TodayView to access hydration settings.
enum SettingsProvider {
    static func fetchOrCreate(in context: NSManagedObjectContext) -> UserSettings {
        HydrationSettingsStore.fetchOrCreate(in: context)
    }

    static func cupSizes(from settings: UserSettings) -> [Int] {
        HydrationSettingsStore.cupSizes(from: settings)
    }
}

extension Calendar {
    /// Returns the start of the current day in the receiver's time zone.
    func startOfToday() -> Date { startOfDay(for: Date()) }
}

struct HydrationStats {
    /// Returns the sum of all drinks logged since the start of today.
    static func todayTotalMl(context: NSManagedObjectContext) -> Int64 {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "HydrationEntry")
        let start = Calendar.current.startOfToday()
        request.predicate = NSPredicate(format: "timestamp >= %@", start as NSDate)
        request.resultType = .dictionaryResultType
        let sum = NSExpressionDescription()
        sum.name = "total"
        sum.expression = NSExpression(forFunction: "sum:", arguments: [NSExpression(forKeyPath: "amountMl")])
        sum.expressionResultType = .integer64AttributeType
        request.propertiesToFetch = [sum]
        if let result = try? context.fetch(request) as? [[String: Any]],
           let total = result.first?["total"] as? Int64 {
            return total
        }
        return 0
    }
}

enum HydrationLogError: LocalizedError {
    case persistence(Error)

    var errorDescription: String? {
        switch self {
        case let .persistence(error):
            return "Saving the hydration entry failed: \(error.localizedDescription)"
        }
    }
}

/// Persists a hydration entry and schedules an inactivity reminder when it succeeds.
@discardableResult
func logDrink(
    context: NSManagedObjectContext,
    amountMl: Int,
    drinkType: String,
    caffeineMg: Int = 0
) throws -> HydrationEntry {
    let entry = HydrationEntry(context: context)
    entry.amountMl = Int64(amountMl)
    entry.timestamp = Date()
    entry.drinkType = drinkType
    entry.caffeineMg = Int64(caffeineMg)
    do {
        try context.save()
    } catch {
        context.delete(entry)
        throw HydrationLogError.persistence(error)
    }
    NotificationManager.shared.scheduleInactivityReminder(after: 90)
    return entry
}

func formatDateRange(start: Date, end: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
}

func formatDuration(start: Date, end: Date) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    let components = calendar.dateComponents([.year, .month, .day], from: start, to: end)
    let years = components.year ?? 0
    let months = components.month ?? 0
    let days = components.day ?? 0
    var parts: [String] = []
    if years != 0 { parts.append("\(years)y") }
    if months != 0 { parts.append("\(months)m") }
    if days != 0 || parts.isEmpty { parts.append("\(days)d") }
    return parts.joined(separator: " ")
}
