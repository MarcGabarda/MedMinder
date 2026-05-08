import SwiftUI

struct MedicineListView: View {
    @Environment(MedicineStore.self) private var store
    @Binding var medicineToEdit: Medicine?
    @Binding var isSelecting: Bool
    @Binding var selectedIDs: Set<UUID>

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.medicines) { medicine in
                    MedicineRowView(
                        medicine: medicine,
                        isSelecting: isSelecting,
                        isSelected: selectedIDs.contains(medicine.id)
                    )
                    .onTapGesture {
                        if isSelecting {
                            if selectedIDs.contains(medicine.id) {
                                selectedIDs.remove(medicine.id)
                            } else {
                                selectedIDs.insert(medicine.id)
                            }
                        } else {
                            medicineToEdit = medicine
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.delete(medicine)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(.systemGroupedBackground))
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct MedicineRowView: View {
    let medicine: Medicine
    let isSelecting: Bool
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .indigo : .gray.opacity(0.4))
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
            } else {
                Circle()
                    .fill(medicine.color)
                    .frame(width: 14, height: 14)
                    .shadow(color: medicine.color.opacity(0.5), radius: 4, y: 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(medicine.name)
                    .font(.headline)

                Text(medicine.dosageText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !medicine.notes.isEmpty {
                    Text(medicine.notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(medicine.reminderTime, style: .time)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.indigo)

                Text(medicine.reminderDayNames)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !isSelecting {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected ? Color.indigo.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    MedicineListView(
        medicineToEdit: .constant(nil),
        isSelecting: .constant(false),
        selectedIDs: .constant([])
    )
    .environment(MedicineStore())
}

