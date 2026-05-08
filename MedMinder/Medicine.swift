import SwiftUI
import SwiftData

enum DosageUnit: String, CaseIterable, Codable {
    case mg, mcg, g, ml, tablets, capsules, drops, units
}

enum Weekday: Int, CaseIterable, Codable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday: return "Su"
        case .monday: return "Mo"
        case .tuesday: return "Tu"
        case .wednesday: return "We"
        case .thursday: return "Th"
        case .friday: return "Fr"
        case .saturday: return "Sa"
        }
    }
}

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

    var color: Color { Color(hex: colorHex) ?? .purple }

    var dosageText: String {
        let f = dosage.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(dosage)) : String(dosage)
        return "\(f) \(unit)"
    }

    var reminderDayNames: String {
        reminderDays.compactMap { Weekday(rawValue: $0) }
            .sorted { $0.rawValue < $1.rawValue }
            .map { $0.shortName }
            .joined(separator: ", ")
    }
}

extension Medicine {
    static var mockMedicines: [Medicine] {
        let cal = Calendar.current
        func t(_ h: Int, _ m: Int) -> Date {
            cal.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
        }
        return [
            Medicine(name: "Aspirin", dosage: 100, unit: "mg", colorHex: "#DC2626", notes: "Take with food", reminderTime: t(8, 0), reminderDays: [2,3,4,5,6]),
            Medicine(name: "Vitamin D", dosage: 1000, unit: "units", colorHex: "#D97706", notes: "Morning with breakfast", reminderTime: t(8, 30), reminderDays: [1,2,3,4,5,6,7]),
            Medicine(name: "Metformin", dosage: 500, unit: "mg", colorHex: "#059669", notes: "After dinner", reminderTime: t(19, 0), reminderDays: [2,3,4,5,6]),
            Medicine(name: "Omega-3", dosage: 1, unit: "capsules", colorHex: "#2563EB", notes: "", reminderTime: t(12, 0), reminderDays: [2,4,6]),
        ]
    }
}

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        h = h.hasPrefix("#") ? String(h.dropFirst()) : h
        var rgb: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&rgb) else { return nil }
        self.init(red: Double((rgb >> 16) & 0xFF) / 255,
                  green: Double((rgb >> 8) & 0xFF) / 255,
                  blue: Double(rgb & 0xFF) / 255)
    }

    func toHex() -> String {
        let uic = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uic.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }
}
