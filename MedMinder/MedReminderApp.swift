import SwiftUI
import SwiftData
import UserNotifications

@main
struct MedReminderApp: App {
    @State private var store    = MedicineStore()
    @State private var settings = AppSettings()

    // The ModelContainer creates and manages the on-device SQLite database.
    let container: ModelContainer = {
        do {
            return try ModelContainer(for: Medicine.self)
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }()

    init() {
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        NotificationManager.shared.setupNotificationCategories()
        Task {
            await NotificationManager.shared.requestPermission()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(settings)
                .task {
                    store.configure(with: container.mainContext)
                    NotificationManager.shared.settings = settings
                }
        }
        .modelContainer(container)
    }
}
