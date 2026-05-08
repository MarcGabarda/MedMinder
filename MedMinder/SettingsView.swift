import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("App Theme")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 10) {
                            ForEach(AppBackground.allCases, id: \.self) { bg in
                                let selected = settings.selectedBackground == bg
                                VStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(LinearGradient(colors: bg.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(height: 56)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(selected ? Color.primary : Color.clear, lineWidth: 3)
                                        )
                                        .overlay(
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.white)
                                                .opacity(selected ? 1 : 0)
                                        )
                                    Text(bg.rawValue)
                                        .font(.caption2)
                                        .foregroundStyle(selected ? .primary : .secondary)
                                }
                                .onTapGesture { withAnimation { settings.selectedBackground = bg } }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Reminder Style") {
                    ForEach(ReminderStyle.allCases, id: \.self) { style in
                        HStack {
                            Image(systemName: style.icon).foregroundStyle(.indigo).frame(width: 28)
                            Text(style.rawValue)
                            Spacer()
                            if settings.reminderStyle == style {
                                Image(systemName: "checkmark").foregroundStyle(.indigo).fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { settings.reminderStyle = style }
                    }
                }

                if settings.reminderStyle == .fullScreenAlarm {
                    Section("Alarm Options") {
                        @Bindable var s = settings
                        Toggle(isOn: $s.repeatUntilConfirmed) {
                            Label("Repeat until confirmed", systemImage: "repeat")
                        }.tint(.indigo)
                        Toggle(isOn: $s.hapticFeedback) {
                            Label("Haptic feedback", systemImage: "waveform")
                        }.tint(.indigo)
                    }
                }

                Section("Ringtone") {
                    ForEach(RingtoneOption.allCases, id: \.self) { tone in
                        HStack {
                            Image(systemName: "music.note").foregroundStyle(.indigo).frame(width: 28)
                            Text(tone.rawValue)
                            Spacer()
                            if settings.selectedRingtone == tone {
                                Image(systemName: "checkmark").foregroundStyle(.indigo).fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { settings.selectedRingtone = tone }
                    }
                }

                Section("Notifications") {
                    @Bindable var s = settings
                    Toggle(isOn: $s.notificationsEnabled) {
                        Label("Enable notifications", systemImage: "bell.fill")
                    }.tint(.indigo)
                    Toggle(isOn: $s.badgeCount) {
                        Label("Show badge count", systemImage: "app.badge.fill")
                    }.tint(.indigo)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(.indigo).fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    SettingsView().environment(AppSettings())
}
