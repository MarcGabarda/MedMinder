import SwiftUI
import UserNotifications

@main
struct MedReminderApp: App {
    @State private var store = MedicineStore()
    @State private var settings = AppSettings()

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
        }
    }
}
