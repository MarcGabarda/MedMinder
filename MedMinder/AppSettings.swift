import SwiftUI

// MARK: - App Background Themes
// Each case defines a named gradient theme used across the app's background and accent colours.
enum AppBackground: String, CaseIterable {
    case blush    = "Blush"
    case sky      = "Sky"
    case mint     = "Mint"
    case lavender = "Lavender"
    case peach    = "Peach"
    case lilac    = "Lilac"

    var colors: [Color] {
        switch self {
        case .blush:    return [Color(hex: "#FFE4E6")!, Color(hex: "#FECDD3")!]
        case .sky:      return [Color(hex: "#E0F2FE")!, Color(hex: "#BAE6FD")!]
        case .mint:     return [Color(hex: "#D1FAE5")!, Color(hex: "#A7F3D0")!]
        case .lavender: return [Color(hex: "#EDE9FE")!, Color(hex: "#DDD6FE")!]
        case .peach:    return [Color(hex: "#FEF3C7")!, Color(hex: "#FDE68A")!]
        case .lilac:    return [Color(hex: "#FAE8FF")!, Color(hex: "#F5D0FE")!]
        }
    }

    // The accent colour is used for buttons, titles, and icons on top of each theme's background
    var accentColor: Color {
        switch self {
        case .blush:    return Color(hex: "#BE185D")!
        case .sky:      return Color(hex: "#0284C7")!
        case .mint:     return Color(hex: "#059669")!
        case .lavender: return Color(hex: "#7C3AED")!
        case .peach:    return Color(hex: "#D97706")!
        case .lilac:    return Color(hex: "#A21CAF")!
        }
    }
}

// MARK: - Reminder Style
// Controls how the user is presented with a reminder when a notification fires.
enum ReminderStyle: String, CaseIterable {
    case fullScreenAlarm    = "Full-screen alarm"
    case simpleNotification = "Simple notification"

    var icon: String {
        switch self {
        case .fullScreenAlarm:    return "bell.and.waves.left.and.right.fill"
        case .simpleNotification: return "bell.fill"
        }
    }
}

// MARK: - Ringtone Options
// Maps to UNNotificationSound in NotificationManager.resolvedSound().
enum RingtoneOption: String, CaseIterable {
    case `default` = "Default"
    case gentle    = "Gentle"
    case urgent    = "Urgent"
    case chime     = "Chime"
}

// MARK: - App Settings
// Observable settings object injected into the environment at app launch.
// Holds all user preferences that affect appearance and notification behaviour.
@Observable
class AppSettings {
    var selectedBackground: AppBackground = .lavender
    var reminderStyle: ReminderStyle      = .fullScreenAlarm
    var repeatUntilConfirmed: Bool        = true  // schedules follow-up reminders every 5 min until confirmed
    var selectedRingtone: RingtoneOption  = .default
    var notificationsEnabled: Bool        = true
    var badgeCount: Bool                  = true
    var hapticFeedback: Bool              = true
}
