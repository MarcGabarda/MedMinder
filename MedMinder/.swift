import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        // Delegate is set in MedReminderApp.init() — not here
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch { return false }
    }

    // MARK: - Delegate: foreground presentation

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let info = notification.request.content.userInfo
        let isTest = info["isTest"] as? Bool ?? false
        if !isTest, let idStr = info["medicineID"] as? String, let id = UUID(uuidString: idStr) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Notification.Name("MedicineAlarm"),
                    object: nil,
                    userInfo: ["medicineID": id]
                )
            }
        }
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: - Delegate: user tapped notification

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let info = response.notification.request.content.userInfo
        let isTest = info["isTest"] as? Bool ?? false

        if !isTest, let idStr = info["medicineID"] as? String, let id = UUID(uuidString: idStr) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Notification.Name("MedicineAlarm"),
                    object: nil,
                    userInfo: ["medicineID": id]
                )
            }
        }
        completionHandler()
    }

    // MARK: - Schedule recurring reminders

    func scheduleNotifications(for medicine: Medicine) {
        cancelNotifications(for: medicine)
        let content = buildContent(for: medicine, isTest: false)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: medicine.reminderTime)
        let minute = calendar.component(.minute, from: medicine.reminderTime)

        for dayRaw in medicine.reminderDays {
            var dc = DateComponents()
            dc.hour = hour; dc.minute = minute; dc.weekday = dayRaw
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(medicine.id.uuidString)-day\(dayRaw)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    // MARK: - Schedule test notification (bell button in toolbar)

    func scheduleTestNotification(for medicine: Medicine) {
        let content = buildContent(for: medicine, isTest: true)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-\(medicine.id)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Schedule snooze (called from AlarmView)

    func scheduleSnoozeNotification(for medicine: Medicine) {
        let content = UNMutableNotificationContent()
        content.title = "💊 \(medicine.name.uppercased())"
        content.subtitle = "Take \(medicine.dosageText) now"
        content.body = "You snoozed this. Time to take it!"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["medicineID": medicine.id.uuidString]
        content.categoryIdentifier = "MEDICINE_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false)
        let request = UNNotificationRequest(
            identifier: "snooze-\(medicine.id)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Confirm taken (called from AlarmView)
    // Cancels only today's firing — all other scheduled days remain untouched

    func confirmTaken(for medicine: Medicine) {
        let today = Calendar.current.component(.weekday, from: Date())
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                "\(medicine.id.uuidString)-day\(today)",
                "test-\(medicine.id)",
                "snooze-\(medicine.id)"
            ]
        )
    }

    // MARK: - Cancel all recurring reminders for a medicine

    func cancelNotifications(for medicine: Medicine) {
        let ids = medicine.reminderDays.map { "\(medicine.id.uuidString)-day\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Notification categories (Taken / Snooze actions)

    func setupNotificationCategories() {
        let confirmAction = UNNotificationAction(
            identifier: "CONFIRM",
            title: "✅ Taken",
            options: [.foreground]
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "⏰ Snooze 10 min",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: "MEDICINE_REMINDER",
            actions: [confirmAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Private helpers

    private func buildContent(for medicine: Medicine, isTest: Bool) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "💊 \(medicine.name.uppercased())"
        content.subtitle = "Take \(medicine.dosageText) now"
        content.body = medicine.notes.isEmpty
            ? "Don't forget your medication! Open the app to confirm."
            : "\(medicine.notes) — Open the app to confirm."
        content.sound = .default
        content.badge = 1
        content.userInfo = ["medicineID": medicine.id.uuidString, "isTest": isTest]
        content.categoryIdentifier = "MEDICINE_REMINDER"
        return content
    }
}
