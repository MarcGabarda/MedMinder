import SwiftUI
import SwiftData

// MARK: - Dosage Units
// Defines all valid units a medicine dosage can be measured in.
// Using an enum ensures only valid units can be selected — invalid strings are impossible.
enum DosageUnit: String, CaseIterable, Codable {
    case mg, mcg, g, ml, tablets, capsules, drops, units
}

// MARK: - Weekday
// Represents days of the week using Apple's weekday numbering (1 = Sunday, 7 = Saturday).
enum Weekday: Int, CaseIterable, Codable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday:    return "Su"
        case .monday:    return "Mo"
        case .tuesday:   return "Tu"
        case .wednesday: return "We"
        case .thursday:  return "Th"
        case .friday:    return "Fr"
        case .saturday:  return "Sa"
        }
    }
}

// MARK: - Medicine Model
// The core data model for the app. @Model marks this class for SwiftData persistence —
// every instance is automatically saved to and loaded from the device's local database.
@Model
class Medicine {
    var id: UUID
    var name: String
    var dosage: Double
    var unit: String
    var colorHex: String
    var notes: String
    var reminderTime: Date
    var reminderDays: [Int]

    init(
        id: UUID = UUID(),
        name: String,
        dosage: Double,
        unit: String = DosageUnit.mg.rawValue,
        colorHex: String = "#7C3AED",
        notes: String = "",
        reminderTime: Date = Date(),
        reminderDays: [Int] = [2, 3, 4, 5, 6]
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.unit = unit
        self.colorHex = colorHex
        self.notes = notes
        self.reminderTime = reminderTime
        self.reminderDays = reminderDays
    }

    // Converts the stored hex string to a SwiftUI Color for use in views
    var color: Color {
        Color(hex: colorHex) ?? .purple
    }

    // Formats dosage for display
    var dosageText: String {
        let formatted = dosage.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(dosage))
            : String(dosage)
        return "\(formatted) \(unit)"
    }

    // Converts stored weekday integers into sorted, human-readable abbreviations
    var reminderDayNames: String {
        reminderDays
            .compactMap { Weekday(rawValue: $0) }
            .sorted { $0.rawValue < $1.rawValue }
            .map { $0.shortName }
            .joined(separator: ", ")
    }
}

// MARK: - Color Helpers
// Extensions to convert between SwiftUI Color and hex strings.
extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        h = h.hasPrefix("#") ? String(h.dropFirst()) : h
        var rgb: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&rgb) else { return nil }
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }

    func toHex() -> String {
        let uic = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uic.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
