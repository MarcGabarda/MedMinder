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
        // Set the delegate before requesting permission so foreground and
        // tap-response callbacks are handled from the first launch.
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
                    // Connect the store to SwiftData and load saved medicines.
                    // Also pass settings to NotificationManager so it can read
                    // ringtone and repeatUntilConfirmed preferences when scheduling.
                    store.configure(with: container.mainContext)
                    NotificationManager.shared.settings = settings
                }
        }
        .modelContainer(container)
    }
}
