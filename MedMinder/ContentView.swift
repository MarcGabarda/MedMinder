import SwiftUI
import UserNotifications

struct ContentView: View {
    @Environment(MedicineStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @State private var showingAddSheet    = false
    @State private var medicineToEdit: Medicine? = nil
    @State private var isSelecting        = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var showingSettings    = false
    @State private var alarmMedicine: Medicine? = nil
    @State private var isShowingAlarm     = false
    @State private var showingUpToDate    = false
    @State private var pendingMedicines: [Medicine] = []  // medicines due right now

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: settings.selectedBackground.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Button(isSelecting ? "Cancel" : "Select") {
                            withAnimation { isSelecting.toggle(); selectedIDs.removeAll() }
                        }
                        .foregroundStyle(settings.selectedBackground.accentColor)
                        .opacity(store.medicines.isEmpty ? 0 : 1)

                        Spacer()

                        if isSelecting {
                            Button {
                                withAnimation {
                                    store.deleteByIDs(selectedIDs)
                                    selectedIDs.removeAll()
                                    isSelecting = false
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(selectedIDs.isEmpty ? Color.gray.opacity(0.4) : .red)
                            }
                            .disabled(selectedIDs.isEmpty)
                        } else {
                            HStack(spacing: 20) {

                                // Bell button — checks pending notifications to decide what to show
                                Button {
                                    guard !isShowingAlarm else { return }
                                    checkAndShowAlarmStatus()
                                } label: {
                                    Image(systemName: "bell.fill")
                                        .foregroundStyle(settings.selectedBackground.accentColor.opacity(0.7))
                                }

                                Button { showingSettings = true } label: {
                                    Image(systemName: "gearshape.fill")
                                        .foregroundStyle(settings.selectedBackground.accentColor)
                                }

                                Button { showingAddSheet = true } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(settings.selectedBackground.accentColor)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 16)

                    Text("My Medicines")
                        .font(.custom("Georgia-BoldItalic", size: 34))
                        .foregroundStyle(settings.selectedBackground.accentColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 22)
                        .padding(.top, 18)
                        .padding(.bottom, 20)

                    if store.medicines.isEmpty {
                        EmptyStateView(showingAddSheet: $showingAddSheet)
                    } else {
                        MedicineListView(
                            medicineToEdit: $medicineToEdit,
                            isSelecting: $isSelecting,
                            selectedIDs: $selectedIDs
                        )
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddSheet) { AddEditMedicineView(mode: .add) }
            .sheet(item: $medicineToEdit) { AddEditMedicineView(mode: .edit($0)) }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingUpToDate) {
                UpToDateView(onDismiss: { showingUpToDate = false })
                    .presentationDetents([.medium])
            }
            .fullScreenCover(item: $alarmMedicine) { medicine in
                AlarmView(medicine: medicine) {
                    alarmMedicine = nil
                    isShowingAlarm = false
                }
            }
            // Triggered by real scheduled notifications only
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineAlarm"))) { notif in
                guard !isShowingAlarm else { return }
                guard notif.userInfo?["isTest"] as? Bool != true else { return }
                if let id  = notif.userInfo?["medicineID"] as? UUID,
                   let med = store.medicines.first(where: { $0.id == id }) {
                    isShowingAlarm = true
                    alarmMedicine  = med
                }
            }
        }
    }

    // MARK: - Bell button logic
    // Checks if any of today's medicine notifications are still pending.
    // If yes → show the alarm for the first pending one.
    // If no  → show the "you're up to date" screen.

    private func checkAndShowAlarmStatus() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let today = Calendar.current.component(.weekday, from: Date())

            // Find medicines that still have a pending notification for today
            let dueMedicines = store.medicines.filter { medicine in
                let todayIdentifier = "\(medicine.id.uuidString)-day\(today)"
                return requests.contains { $0.identifier == todayIdentifier }
            }

            DispatchQueue.main.async {
                if let first = dueMedicines.first {
                    // Something is still pending — show alarm for it
                    isShowingAlarm = true
                    alarmMedicine  = first
                } else {
                    // Nothing pending — all confirmed or no medicines scheduled today
                    showingUpToDate = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(MedicineStore())
        .environment(AppSettings())
}
