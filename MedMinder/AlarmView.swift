import SwiftUI
import AVFoundation

// MARK: - Alarm View
// Full-screen presentation shown when a medicine reminder fires.
// Plays a looping alarm sound while visible, and schedules follow-up
// notifications in case the user dismisses the app without confirming.
struct AlarmView: View {
    let medicine:  Medicine
    let onDismiss: () -> Void

    @Environment(AppSettings.self) private var settings
    @State private var pulse        = false
    @State private var confirmed    = false
    @State private var audioPlayer: AVAudioPlayer?

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
                pulsingIcon
                timeDisplay
                medicineCard
                Spacer()
                actionButtons
            }
        }
        .onAppear {
            pulse = true
            startAlarmSound()
            NotificationManager.shared.scheduleRepeatReminders(for: medicine)
            triggerHaptic()
        }
        .onDisappear {
            stopAlarmSound()
        }
    }

    // MARK: - Subviews

    private var pulsingIcon: some View {
        ZStack {
            Circle()
                .fill(medicine.color.opacity(0.2))
                .frame(width: 130, height: 130)
                .scaleEffect(pulse ? 1.18 : 1.0)
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
            Circle()
                .fill(medicine.color.opacity(0.35))
                .frame(width: 96, height: 96)
            Image(systemName: "pills.fill")
                .font(.system(size: 48))
                .foregroundStyle(medicine.color)
        }
    }

    private var timeDisplay: some View {
        VStack(spacing: 6) {
            Text(Date(), style: .time)
                .font(.system(size: 34, weight: .light, design: .rounded))
                .foregroundStyle(.primary)
            Text("Time to take your medicine")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var medicineCard: some View {
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
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            // Confirm cancels today's alarm and any repeat reminders, then dismisses.
            Button {
                guard !confirmed else { return }
                withAnimation(.spring(response: 0.3)) { confirmed = true }
                stopAlarmSound()
                NotificationManager.shared.confirmTaken(for: medicine)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { onDismiss() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: confirmed ? "checkmark.circle.fill" : "hand.tap.fill")
                    Text(confirmed ? "Done! Great job" : "Confirm — Medicine Taken")
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

            if !confirmed {
                // Snooze schedules a new notification 10 minutes from now, then dismisses.
                Button {
                    stopAlarmSound()
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

    // MARK: - Audio Loop

    // Plays the user's selected ringtone on loop until the alarm is dismissed.
    private func startAlarmSound() {
        // Map the user's ringtone preference to the bundled sound file.
        // "Default" and "Urgent" fall back to the system sound (a short system tone)
        let resourceName: String
        switch settings.selectedRingtone {
        case .gentle:  resourceName = "gentle"
        case .chime:   resourceName = "chime"
        case .urgent, .default: resourceName = "gentle" // fallback file
        }

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "caf")
                     ?? Bundle.main.url(forResource: resourceName, withExtension: "wav")
                     ?? Bundle.main.url(forResource: resourceName, withExtension: "mp3") else {
            print("AlarmView: no sound file found for \(resourceName)")
            return
        }

        do {
            // .playback ignores the silent switch; .duckOthers lowers other audio while ringing.
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1   // loop forever until stopped
            player.volume        = 1.0
            player.prepareToPlay()
            player.play()
            audioPlayer = player
        } catch {
            print("AlarmView: failed to start alarm sound — \(error)")
        }
    }

    private func stopAlarmSound() {
        audioPlayer?.stop()
        audioPlayer = nil
        // Release the audio session so other audio (music, podcasts) can resume.
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    // MARK: - Haptics

    // Fires a single notification haptic on appear if the user has haptics enabled.
    private func triggerHaptic() {
        guard settings.hapticFeedback else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}

#Preview {
    let medicine = Medicine(name: "Aspirin", dosage: 100, unit: "mg",
                            colorHex: "#DC2626", notes: "Take with food")
    AlarmView(medicine: medicine) {}
        .environment(AppSettings())
}
