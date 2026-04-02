import SwiftUI

struct FloatNotificationView: View {
    let message: String
    var onTap: (() -> Void)?

    @State private var isVisible = false
    @State private var bounce = false

    var body: some View {
        HStack(spacing: 10) {
            Text("🦆")
                .font(.system(size: 32))
                .scaleEffect(bounce ? 1.2 : 1.0)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.5)
                    .repeatCount(3, autoreverses: true),
                    value: bounce
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Claude Code")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 280, height: 68)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 24)
        .onTapGesture { onTap?() }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                bounce = true
            }
        }
    }
}
