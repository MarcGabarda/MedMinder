import SwiftUI

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

                // Pulsing icon
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

                // Time + subtitle
                VStack(spacing: 6) {
                    Text(Date(), style: .time)
                        .font(.system(size: 34, weight: .light, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Time to take your medicine")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Medicine details card
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

                // Action buttons
                VStack(spacing: 14) {

                    // Confirm button
                    Button {
                        guard !confirmed else { return }
                        withAnimation(.spring(response: 0.3)) { confirmed = true }

                        // Delegate all notification logic to NotificationManager
                        NotificationManager.shared.confirmTaken(for: medicine)

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
                            // Delegate snooze scheduling to NotificationManager
                            NotificationManager.shared.scheduleSnoozeNotification(for: medicine)
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
