import SwiftUI

// MARK: - Empty State View
// Shown on the main screen when the user has no medicines saved.
// Guides new users toward adding their first medicine.
struct EmptyStateView: View {
    @Binding var showingAddSheet: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.1))
                    .frame(width: 130, height: 130)
                Image(systemName: "pills.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            VStack(spacing: 8) {
                Text("No Medicines Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Add your first medicine and set up\nreminders so you never miss a dose.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button {
                showingAddSheet = true
            } label: {
                Label("Add Medicine", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .indigo.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

#Preview {
    EmptyStateView(showingAddSheet: .constant(false))
}
