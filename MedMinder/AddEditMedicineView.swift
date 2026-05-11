import SwiftUI

// Distinguishes between creating a new medicine and editing an existing one.
enum FormMode {
    case add
    case edit(Medicine)
}

// MARK: - Add / Edit Medicine View
// Shared form used for both adding a new medicine and editing an existing one.
// Validates input before saving and shows an alert if required fields are missing.
struct AddEditMedicineView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let mode: FormMode

    @State private var name               = ""
    @State private var dosage             = ""
    @State private var unit: DosageUnit   = .mg
    @State private var selectedColor: Color = Color(hex: "#DC2626")!
    @State private var notes              = ""
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var selectedDays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var showingValidationAlert = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    // Colour options are dark/saturated so they remain readable on white form backgrounds
    let colorOptions: [Color] = [
        Color(hex: "#DC2626")!, Color(hex: "#EA580C")!, Color(hex: "#D97706")!,
        Color(hex: "#059669")!, Color(hex: "#0284C7")!, Color(hex: "#2563EB")!,
        Color(hex: "#7C3AED")!, Color(hex: "#BE185D")!, Color(hex: "#0F766E")!,
        Color(hex: "#475569")!,
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                nameField
                dosageRow
                notesField
                Divider().padding(.vertical, 14)
                colourPicker
                Divider().padding(.vertical, 14)
                timePicker
                Divider().padding(.vertical, 14)
                dayPicker
                Spacer()
                saveButton
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditing ? "Edit Medicine" : "Add Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(.indigo)
                }
            }

            .task { loadExistingValues() }
            .alert("Missing Info", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a name and valid dosage.")
            }
        }
    }

    // MARK: - Form Fields

    private var nameField: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(selectedColor)
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
            TextField("Medicine name", text: $name)
                .font(.headline)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16).padding(.top, 12)
    }

    private var dosageRow: some View {
        HStack(spacing: 10) {
            TextField("Dosage", text: $dosage)
                .keyboardType(.decimalPad)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Picker("Unit", selection: $unit) {
                ForEach(DosageUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.menu).tint(.indigo)
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16).padding(.top, 10)
    }

    private var notesField: some View {
        TextField("Notes (optional)", text: $notes)
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16).padding(.top, 10)
    }

    private var colourPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("COLOUR")
                .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                .padding(.horizontal, 16)
            HStack(spacing: 0) {
                ForEach(colorOptions.indices, id: \.self) { i in
                    let color      = colorOptions[i]
                    let isSelected = color.toHex() == selectedColor.toHex()
                    ZStack {
                        Circle().fill(color)
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 32)
                    .onTapGesture { selectedColor = color }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var timePicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("REMINDER TIME")
                .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.wheel)
                .frame(maxWidth: .infinity).frame(height: 100).clipped()
                .padding(.horizontal, 8)
        }
    }

    private var dayPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REPEAT DAYS")
                .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                .padding(.horizontal, 16)
            HStack(spacing: 6) {
                ForEach(Weekday.allCases) { day in
                    let selected = selectedDays.contains(day.rawValue)
                    Text(day.shortName)
                        .font(.caption).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(selected ? Color.indigo : Color(.secondarySystemBackground))
                        .foregroundStyle(selected ? .white : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            if selectedDays.contains(day.rawValue) {
                                // Prevent deselecting the last remaining day
                                if selectedDays.count > 1 { selectedDays.remove(day.rawValue) }
                            } else {
                                selectedDays.insert(day.rawValue)
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text(isEditing ? "Save Changes" : "Add Medicine")
                .font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 16).padding(.bottom, 24)
    }

    // MARK: - Logic

    // Pre-fills form fields with the existing medicine's values when editing
    private func loadExistingValues() {
        guard case .edit(let m) = mode else { return }
        name         = m.name
        dosage       = m.dosage.truncatingRemainder(dividingBy: 1) == 0
                           ? String(Int(m.dosage)) : String(m.dosage)
        unit         = DosageUnit(rawValue: m.unit) ?? .mg
        selectedColor = m.color
        notes        = m.notes
        reminderTime = m.reminderTime
        selectedDays = Set(m.reminderDays)
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              let val = Double(dosage), val > 0,
              !selectedDays.isEmpty else {
            showingValidationAlert = true
            return
        }
        switch mode {
        case .add:
            store.add(Medicine(
                name:         name.trimmingCharacters(in: .whitespaces),
                dosage:       val,
                unit:         unit.rawValue,
                colorHex:     selectedColor.toHex(),
                notes:        notes,
                reminderTime: reminderTime,
                reminderDays: Array(selectedDays)
            ))
        case .edit(let m):
            m.name         = name.trimmingCharacters(in: .whitespaces)
            m.dosage       = val
            m.unit         = unit.rawValue
            m.colorHex     = selectedColor.toHex()
            m.notes        = notes
            m.reminderTime = reminderTime
            m.reminderDays = Array(selectedDays)
            store.update(m)
        }
        dismiss()
    }
}

#Preview {
    AddEditMedicineView(mode: .add).environment(MedicineStore())
}
