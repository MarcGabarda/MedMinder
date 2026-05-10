import SwiftUI
import SwiftData
import UserNotifications

@main
struct MedReminderApp: App {
    @State private var store    = MedicineStore()
    @State private var settings = AppSettings()

    // The ModelContainer creates and manages the on-device SQLite database.
    // Declared as a stored property so it persists for the lifetime of the app.
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
                .onAppear {
                    store.configure(with: container.mainContext)
                    NotificationManager.shared.settings = settings
                }
        }
        .modelContainer(container)
    }
}
