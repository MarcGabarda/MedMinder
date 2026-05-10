import SwiftUI
import SwiftData

// MARK: - Medicine Store
// Responsible for reading and writing Medicine objects to SwiftData,
// and coordinating with NotificationManager when medicines are added, edited, or removed.
@Observable
class MedicineStore {

    var medicines: [Medicine] = []

    // The SwiftData context is injected at launch via configure(with:).
    // It is optional only because it cannot be set during init — the container
    // must be created first in MedReminderApp before it can be passed here.
    private var context: ModelContext?

    // MARK: - Setup

    func configure(with context: ModelContext) {
        self.context = context
        loadMedicines()
    }

    // MARK: - Load

    private func loadMedicines() {
        guard let context else { return }
        do {
            let descriptor = FetchDescriptor<Medicine>(
                sortBy: [SortDescriptor(\.name)]
            )
            medicines = try context.fetch(descriptor)
        } catch {
            print("MedicineStore: failed to fetch medicines — \(error)")
            medicines = []
        }
    }

    // MARK: - CRUD

    func add(_ medicine: Medicine) {
        guard let context else { return }
        context.insert(medicine)
        save()
        medicines.append(medicine)
        NotificationManager.shared.scheduleNotifications(for: medicine)
    }

    /// Updates an existing medicine's properties and reschedules its notifications.
    func update(_ medicine: Medicine) {
        save()
        NotificationManager.shared.scheduleNotifications(for: medicine)
    }

    func delete(_ medicine: Medicine) {
        guard let context else { return }
        NotificationManager.shared.cancelNotifications(for: medicine)
        context.delete(medicine)
        save()
        medicines.removeAll { $0.id == medicine.id }
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            delete(medicines[index])
        }
    }

    func deleteByIDs(_ ids: Set<UUID>) {
        medicines
            .filter { ids.contains($0.id) }
            .forEach { delete($0) }
    }

    // MARK: - Persistence

    private func save() {
        guard let context else { return }
        do {
            try context.save()
        } catch {
            print("MedicineStore: failed to save context — \(error)")
        }
    }
}
