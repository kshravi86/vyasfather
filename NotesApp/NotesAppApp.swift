import SwiftUI
import CoreData
import UserNotifications

@main
struct HydrationReminderApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // In CI/screenshot mode, skip permission prompts and seed data
        let args = ProcessInfo.processInfo.arguments
        let isScreenshotMode = args.contains("--seed-screenshots")
        if !isScreenshotMode {
            NotificationManager.shared.requestAuthorization()
        }
        if args.contains("--disable-animations") {
            #if canImport(UIKit)
            DispatchQueue.main.async {
                UIView.setAnimationsEnabled(false)
            }
            #endif
        }
        // Seed sample data when running in CI for screenshots
        if isScreenshotMode {
            let context = persistenceController.container.viewContext
            SeedData.seedIfNeeded(in: context)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

enum SeedData {
    static func seedIfNeeded(in context: NSManagedObjectContext) {
        // Avoid duplicating data across runs
        let req: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        req.fetchLimit = 1
        if let count = try? context.count(for: req), count > 0 { return }

        let settings = SettingsProvider.fetchOrCreate(in: context)
        settings.weightKg = 72
        settings.activityLevel = ActivityLevel.medium.rawValue
        settings.dailyGoalMl = HydrationCalculator.goalMl(weightKg: settings.weightKg, activity: .medium)
        settings.cupSizes = "[250,350,500]"
        settings.lastWorkout = Date().addingTimeInterval(-3600 * 3)

        func add(amount: Int64, hoursAgo: Double, drink: String, caffeine: Int? = nil) {
            let e = HydrationEntry(context: context)
            e.amountMl = amount
            e.timestamp = Date().addingTimeInterval(-3600 * hoursAgo)
            e.drinkType = drink
            if let c = caffeine { e.caffeineMg = Int64(c) }
        }

        // Today entries
        add(amount: 350, hoursAgo: 1.0, drink: "water")
        add(amount: 250, hoursAgo: 3.0, drink: "coffee", caffeine: 80)
        add(amount: 500, hoursAgo: 5.5, drink: "water")

        // Yesterday entries
        add(amount: 300, hoursAgo: 26.0, drink: "tea", caffeine: 60)
        add(amount: 400, hoursAgo: 28.0, drink: "water")

        try? context.save()
    }
}
