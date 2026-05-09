import SwiftUI
import SwiftData
import UserNotifications

@main
struct MedReminderApp: App {
    @State private var store    = MedicineStore()
    @State private var settings = AppSettings()

    let container: ModelContainer = {
        do {
            return try ModelContainer(for: Medicine.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
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
                    // Give NotificationManager access to settings so it can
                    // read ringtone and repeatUntilConfirmed preferences
                    NotificationManager.shared.settings = settings
                }
        }
        .modelContainer(container)
    }
}
