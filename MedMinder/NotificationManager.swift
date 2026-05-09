import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Manager
// Centralises all interaction with UNUserNotificationCenter.
// Views and the store never call UNUserNotificationCenter directly —
// they always go through this class, keeping notification logic in one place.
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    // Injected from AppSettings on launch so the manager can read
    // the user's ringtone and repeatUntilConfirmed preferences.
    var settings: AppSettings?

    private override init() {
        super.init()
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Called when a notification arrives while the app is in the foreground.
    // Posts a MedicineAlarm notification so ContentView can present the alarm screen.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let info   = notification.request.content.userInfo
        let isTest = info["isTest"] as? Bool ?? false

        if !isTest,
           let idStr = info["medicineID"] as? String,
           let id    = UUID(uuidString: idStr) {
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

    // Called when the user taps a notification while the app is in the background or closed.
    // Posts the same MedicineAlarm notification so ContentView shows the alarm on app open.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let info   = response.notification.request.content.userInfo
        let isTest = info["isTest"] as? Bool ?? false

        if !isTest,
           let idStr = info["medicineID"] as? String,
           let id    = UUID(uuidString: idStr) {
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

    // MARK: - Scheduling

    // Schedules one repeating notification per selected weekday.
    // Each notification fires at the medicine's reminder time on its specific day.
    // Cancels existing notifications first to avoid duplicates after an edit.
    func scheduleNotifications(for medicine: Medicine) {
        cancelNotifications(for: medicine)
        let content  = buildContent(for: medicine, isTest: false)
        let calendar = Calendar.current
        let hour     = calendar.component(.hour,   from: medicine.reminderTime)
        let minute   = calendar.component(.minute, from: medicine.reminderTime)

        for dayRaw in medicine.reminderDays {
            var dc         = DateComponents()
            dc.hour        = hour
            dc.minute      = minute
            dc.weekday     = dayRaw
            let trigger    = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let request    = UNNotificationRequest(
                identifier: "\(medicine.id.uuidString)-day\(dayRaw)",
                content:    content,
                trigger:    trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    // Schedules a one-off snooze notification 10 minutes from now.
    func scheduleSnoozeNotification(for medicine: Medicine) {
        let content          = UNMutableNotificationContent()
        content.title        = "💊 \(medicine.name.uppercased())"
        content.subtitle     = "Take \(medicine.dosageText) now"
        content.body         = "You snoozed this. Time to take it!"
        content.sound        = resolvedSound()
        content.badge        = 1
        content.userInfo     = ["medicineID": medicine.id.uuidString]
        content.categoryIdentifier = "MEDICINE_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false)
        let request = UNNotificationRequest(
            identifier: "snooze-\(medicine.id)",
            content:    content,
            trigger:    trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // Schedules up to 10 follow-up notifications, 5 minutes apart, for the current alarm session.
    // Only runs if the user has "Repeat until confirmed" enabled in Settings.
    // All repeat notifications are cancelled when the user confirms they have taken the medicine.
    func scheduleRepeatReminders(for medicine: Medicine) {
        guard settings?.repeatUntilConfirmed == true else { return }
        let content = buildContent(for: medicine, isTest: false)

        for i in 1...10 {
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: Double(i) * 300,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "repeat-\(medicine.id)-\(i)",
                content:    content,
                trigger:    trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    // MARK: - Cancellation

    // Cancels today's alarm and any temporary notifications (test, snooze, repeat reminders).
    // The recurring weekly notifications for other days are left intact.
    func confirmTaken(for medicine: Medicine) {
        let today = Calendar.current.component(.weekday, from: Date())
        var ids   = [
            "\(medicine.id.uuidString)-day\(today)",
            "test-\(medicine.id)",
            "snooze-\(medicine.id)"
        ]
        for i in 1...10 {
            ids.append("repeat-\(medicine.id)-\(i)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // Cancels all recurring weekly notifications for a medicine.
    // Called when a medicine is deleted or its schedule is being replaced.
    func cancelNotifications(for medicine: Medicine) {
        let ids = medicine.reminderDays.map { "\(medicine.id.uuidString)-day\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Notification Categories

    // Registers the "Taken" and "Snooze" action buttons that appear on the notification banner.
    func setupNotificationCategories() {
        let confirmAction = UNNotificationAction(
            identifier: "CONFIRM",
            title:      "✅ Taken",
            options:    [.foreground]
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title:      "⏰ Snooze 10 min",
            options:    []
        )
        let category = UNNotificationCategory(
            identifier:         "MEDICINE_REMINDER",
            actions:            [confirmAction, snoozeAction],
            intentIdentifiers:  [],
            options:            [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Private Helpers

    private func buildContent(for medicine: Medicine, isTest: Bool) -> UNMutableNotificationContent {
        let content          = UNMutableNotificationContent()
        content.title        = "\(medicine.name.uppercased())"
        content.subtitle     = "Take \(medicine.dosageText) now"
        content.body         = medicine.notes.isEmpty
            ? "Don't forget your medication! Open the app to confirm."
            : "\(medicine.notes) — Open the app to confirm."
        content.sound        = resolvedSound()
        content.badge        = 1
        content.userInfo     = ["medicineID": medicine.id.uuidString, "isTest": isTest]
        content.categoryIdentifier = "MEDICINE_REMINDER"
        return content
    }

    // Maps the user's ringtone preference to a UNNotificationSound.
    // Gentle and Chime require gentle.caf and chime.caf in the app bundle.
    // Missing files fall back to the system default — the app will not crash.
    private func resolvedSound() -> UNNotificationSound {
        guard let ringtone = settings?.selectedRingtone else { return .default }
        switch ringtone {
        case .default: return .default
        case .gentle:  return UNNotificationSound(named: UNNotificationSoundName("gentle.caf"))
        case .urgent:  return .defaultCritical
        case .chime:   return UNNotificationSound(named: UNNotificationSoundName("chime.caf"))
        }
    }

    // Used only for testing — schedules a notification 5 seconds from now
    // with isTest: true so it does not trigger the in-app alarm screen.
    func scheduleTestNotification(for medicine: Medicine) {
        let content = buildContent(for: medicine, isTest: true)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-\(medicine.id)",
            content:    content,
            trigger:    trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
