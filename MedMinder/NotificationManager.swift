import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Manager
// Centralises all interaction with UNUserNotificationCenter.
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    var settings: AppSettings?

    // How many repeat reminders to schedule per alarm session.
    private let repeatReminderCount = 10

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
    func scheduleNotifications(for medicine: Medicine) {
        cancelNotifications(for: medicine)

        guard settings?.notificationsEnabled ?? true else { return }

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
        guard settings?.notificationsEnabled ?? true else { return }

        let content          = UNMutableNotificationContent()
        content.title        = "💊 \(medicine.name.uppercased())"
        content.subtitle     = "Take \(medicine.dosageText) now"
        content.body         = "You snoozed this. Time to take it!"
        content.sound        = resolvedSound()
        content.badge        = (settings?.badgeCount ?? true) ? 1 : nil
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

    // Schedules up to N follow-up notifications, 5 minutes apart, for the current
    func scheduleRepeatReminders(for medicine: Medicine) {
        cancelRepeatReminders(for: medicine)

        guard settings?.repeatUntilConfirmed == true,
              settings?.notificationsEnabled ?? true else { return }

        let content = buildContent(for: medicine, isTest: false)

        for i in 1...repeatReminderCount {
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
    func confirmTaken(for medicine: Medicine) {
        let today = Calendar.current.component(.weekday, from: Date())
        var ids   = [
            "\(medicine.id.uuidString)-day\(today)",
            "test-\(medicine.id)",
            "snooze-\(medicine.id)"
        ]
        for i in 1...repeatReminderCount {
            ids.append("repeat-\(medicine.id)-\(i)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // Cancels all recurring + temporary notifications for a medicine
    func cancelNotifications(for medicine: Medicine) {
        var ids: [String] = []

        for day in 1...7 {
            ids.append("\(medicine.id.uuidString)-day\(day)")
        }

        // Temporary notifications.
        ids.append("test-\(medicine.id)")
        ids.append("snooze-\(medicine.id)")
        for i in 1...repeatReminderCount {
            ids.append("repeat-\(medicine.id)-\(i)")
        }

        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ids)
    }

    // Removes only the repeat reminders for a medicine.
    private func cancelRepeatReminders(for medicine: Medicine) {
        let ids = (1...repeatReminderCount).map { "repeat-\(medicine.id)-\($0)" }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Notification Categories

    // Registers the "Taken" and "Snooze" action buttons that appear on the notification banner.
    func setupNotificationCategories() {
        let confirmAction = UNNotificationAction(
            identifier: "CONFIRM",
            title:      "Taken",
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
        content.badge        = (settings?.badgeCount ?? true) ? 1 : nil
        content.userInfo     = ["medicineID": medicine.id.uuidString, "isTest": isTest]
        content.categoryIdentifier = "MEDICINE_REMINDER"
        return content
    }

    // Maps the user's ringtone preference to a UNNotificationSound.
    private func resolvedSound() -> UNNotificationSound {
        guard let ringtone = settings?.selectedRingtone else { return .default }
        switch ringtone {
        case .default: return .default
        case .gentle:  return UNNotificationSound(named: UNNotificationSoundName("gentle.caf"))
        case .urgent:  return .defaultCritical
        case .chime:   return UNNotificationSound(named: UNNotificationSoundName("chime.caf"))
        }
    }

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
