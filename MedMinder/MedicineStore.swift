import SwiftUI

@Observable
class MedicineStore {
    var medicines: [Medicine] = Medicine.mockMedicines

    func add(_ medicine: Medicine) {
        medicines.append(medicine)
        NotificationManager.shared.scheduleNotifications(for: medicine)
    }

    func update(_ medicine: Medicine) {
        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
            medicines[index] = medicine
            NotificationManager.shared.scheduleNotifications(for: medicine)
        }
    }

    func delete(_ medicine: Medicine) {
        NotificationManager.shared.cancelNotifications(for: medicine)
        medicines.removeAll { $0.id == medicine.id }
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            NotificationManager.shared.cancelNotifications(for: medicines[index])
        }
        medicines.remove(atOffsets: offsets)
    }

    func deleteByIDs(_ ids: Set<UUID>) {
        medicines
            .filter { ids.contains($0.id) }
            .forEach { NotificationManager.shared.cancelNotifications(for: $0) }
        medicines.removeAll { ids.contains($0.id) }
    }
}
