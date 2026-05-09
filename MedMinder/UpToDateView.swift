import SwiftUI

// MARK: - Up To Date View
// Shown as a half-sheet when the user taps the bell button but no medicines are pending for today.
// This covers two scenarios: all medicines have been confirmed, or none are scheduled for today.
struct UpToDateView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 130, height: 130)
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 96, height: 96)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                }

                VStack(spacing: 10) {
                    Text("You're All Up To Date")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("No medicines are due right now.\nCheck back when your next reminder is scheduled.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)

                Spacer()

                Button(action: onDismiss) {
                    Text("Got it")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    UpToDateView(onDismiss: {})
}
