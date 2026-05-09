import SwiftUI
import SwiftData

@Observable
class MedicineStore {

    // All medicines loaded from persistent storage
    var medicines: [Medicine] = []

    // SwiftData context — set by MedReminderApp on launch via configure()
    private var context: ModelContext?

    // MARK: - Setup

    /// Called once on app launch to connect the store to the SwiftData context.
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
            print("Failed to fetch medicines: \(error)")
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

    // MARK: - Save

    private func save() {
        guard let context else { return }
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
