import SwiftUI
import SwiftData

// MARK: - Medicine Store
// Responsible for reading and writing Medicine objects to SwiftData,
@Observable
class MedicineStore {

    var medicines: [Medicine] = []

    // The SwiftData context is injected at launch via configure(with:).
    private var context: ModelContext?

    // Tracks whether the store has already been configured so we don't
    // reload from disk every time ContentView re-appears.
    private var isConfigured = false

    // MARK: - Setup

    func configure(with context: ModelContext) {
        guard !isConfigured else { return }
        self.context = context
        isConfigured = true
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

    // Inserts a new medicine into SwiftData, then refreshes the in-memory array
    // from the database to avoid duplicates and keep sort order correct.
    func add(_ medicine: Medicine) {
        guard let context else { return }
        context.insert(medicine)
        save()
        loadMedicines()
        NotificationManager.shared.scheduleNotifications(for: medicine)
    }

    // Saves changes, then re-assigns the array element
    func update(_ medicine: Medicine) {
        save()
        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
            medicines[index] = medicine
        }
        NotificationManager.shared.scheduleNotifications(for: medicine)
    }

    func delete(_ medicine: Medicine) {
        guard let context else { return }
        NotificationManager.shared.cancelNotifications(for: medicine)
        context.delete(medicine)
        save()
        medicines.removeAll { $0.id == medicine.id }
    }

    // Collects medicines to delete first, then removes them to avoid mutating
    func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { medicines[$0] }
        toDelete.forEach { delete($0) }
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
