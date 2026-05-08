import SwiftUI
import UserNotifications

struct AlarmView: View {
    let medicine: Medicine
    let onDismiss: () -> Void

    @Environment(AppSettings.self) private var settings
    @State private var pulse = false
    @State private var confirmed = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [medicine.color.opacity(0.25), medicine.color.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(medicine.color.opacity(0.2))
                        .frame(width: 130, height: 130)
                        .scaleEffect(pulse ? 1.18 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                            value: pulse
                        )
                    Circle()
                        .fill(medicine.color.opacity(0.35))
                        .frame(width: 96, height: 96)
                    Image(systemName: "pills.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(medicine.color)
                }

                VStack(spacing: 6) {
                    Text(Date(), style: .time)
                        .font(.system(size: 34, weight: .light, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Time to take your medicine")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Circle().fill(medicine.color).frame(width: 14, height: 14)
                        Text(medicine.name).font(.title2).fontWeight(.bold)
                        Spacer()
                    }
                    HStack {
                        Label(medicine.dosageText, systemImage: "scalemass.fill")
                            .font(.headline).foregroundStyle(.secondary)
                        Spacer()
                    }
                    if !medicine.notes.isEmpty {
                        HStack {
                            Label(medicine.notes, systemImage: "note.text")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding(22)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 14) {

                    // Confirm button
                    Button {
                        guard !confirmed else { return }
                        withAnimation(.spring(response: 0.3)) { confirmed = true }

                        // Cancel only today's firing so it won't pop up again today
                        // All other scheduled days remain untouched
                        let today = Calendar.current.component(.weekday, from: Date())
                        UNUserNotificationCenter.current().removePendingNotificationRequests(
                            withIdentifiers: [
                                "\(medicine.id.uuidString)-day\(today)",
                                "test-\(medicine.id)",
                                "snooze-\(medicine.id)"
                            ]
                        )

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            onDismiss()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: confirmed ? "checkmark.circle.fill" : "hand.tap.fill")
                            Text(confirmed ? "Done! Great job 💪" : "Confirm — Medicine Taken")
                                .fontWeight(.semibold)
                        }
                        .font(.headline)
                        .foregroundStyle(confirmed ? .white : medicine.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(confirmed ? Color.green : medicine.color.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(confirmed ? Color.clear : medicine.color, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .animation(.easeInOut(duration: 0.3), value: confirmed)
                    }
                    .disabled(confirmed)

                    // Snooze button
                    if !confirmed {
                        Button {
                            let content = UNMutableNotificationContent()
                            content.title = "💊 \(medicine.name.uppercased())"
                            content.subtitle = "Take \(medicine.dosageText) now"
                            content.body = "You snoozed this. Time to take it!"
                            content.sound = .default
                            content.badge = 1
                            content.userInfo = ["medicineID": medicine.id.uuidString]
                            content.categoryIdentifier = "MEDICINE_REMINDER"

                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false)
                            let request = UNNotificationRequest(
                                identifier: "snooze-\(medicine.id)",
                                content: content,
                                trigger: trigger
                            )
                            UNUserNotificationCenter.current().add(request)
                            onDismiss()
                        } label: {
                            Text("Snooze 10 minutes")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear { pulse = true }
    }
}

#Preview {
    AlarmView(medicine: Medicine.mockMedicines[0]) {}
        .environment(AppSettings())
}
