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

// MARK: - Storage Keys
private enum SettingsKey {
    static let background       = "settings.background"
    static let reminderStyle    = "settings.reminderStyle"
    static let repeatUntil      = "settings.repeatUntilConfirmed"
    static let ringtone         = "settings.ringtone"
    static let notifications    = "settings.notificationsEnabled"
    static let badge            = "settings.badgeCount"
    static let haptic           = "settings.hapticFeedback"
}

// MARK: - App Settings
// Observable settings object injected into the environment at app launch.
// All properties persist automatically to UserDefaults via didSet observers.
@Observable
class AppSettings {

    var selectedBackground: AppBackground {
        didSet { UserDefaults.standard.set(selectedBackground.rawValue, forKey: SettingsKey.background) }
    }

    var reminderStyle: ReminderStyle {
        didSet { UserDefaults.standard.set(reminderStyle.rawValue, forKey: SettingsKey.reminderStyle) }
    }

    var repeatUntilConfirmed: Bool {
        didSet { UserDefaults.standard.set(repeatUntilConfirmed, forKey: SettingsKey.repeatUntil) }
    }

    var selectedRingtone: RingtoneOption {
        didSet { UserDefaults.standard.set(selectedRingtone.rawValue, forKey: SettingsKey.ringtone) }
    }

    var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: SettingsKey.notifications) }
    }

    var badgeCount: Bool {
        didSet { UserDefaults.standard.set(badgeCount, forKey: SettingsKey.badge) }
    }

    var hapticFeedback: Bool {
        didSet { UserDefaults.standard.set(hapticFeedback, forKey: SettingsKey.haptic) }
    }

    init() {
        let defaults = UserDefaults.standard

        // Read each saved value, falling back to a sensible default if missing or invalid.
        self.selectedBackground = AppBackground(
            rawValue: defaults.string(forKey: SettingsKey.background) ?? ""
        ) ?? .lavender

        self.reminderStyle = ReminderStyle(
            rawValue: defaults.string(forKey: SettingsKey.reminderStyle) ?? ""
        ) ?? .fullScreenAlarm

        self.repeatUntilConfirmed = defaults.object(forKey: SettingsKey.repeatUntil) as? Bool ?? true

        self.selectedRingtone = RingtoneOption(
            rawValue: defaults.string(forKey: SettingsKey.ringtone) ?? ""
        ) ?? .default

        self.notificationsEnabled = defaults.object(forKey: SettingsKey.notifications) as? Bool ?? true
        self.badgeCount           = defaults.object(forKey: SettingsKey.badge) as? Bool ?? true
        self.hapticFeedback       = defaults.object(forKey: SettingsKey.haptic) as? Bool ?? true
    }
}
