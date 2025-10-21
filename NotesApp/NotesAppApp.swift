import SwiftUI
import CoreData

@main
struct HydrationReminderApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // In CI/screenshot mode, skip permission prompts and seed data
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--disable-animations") {
            #if canImport(UIKit)
            DispatchQueue.main.async {
                UIView.setAnimationsEnabled(false)
            }
            #endif
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
