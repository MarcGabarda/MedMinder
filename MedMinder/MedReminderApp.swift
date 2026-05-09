import SwiftUI
import SwiftData
import UserNotifications

@main
struct MedReminderApp: App {
    @State private var store    = MedicineStore()
    @State private var settings = AppSettings()

    // SwiftData container — persists Medicine objects to disk automatically
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
                    // Hand the context to the store so it can read/write from disk
                    store.configure(with: container.mainContext)
                }
        }
        .modelContainer(container)
    }
}
