import SwiftUI

struct StatusBadge: View {
    let level: SetupHealthLevel
    let summary: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.symbolName)
                .font(.caption2.weight(.bold))
            Text(summary)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(level.tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(level.tint.opacity(0.14), in: Capsule())
        .overlay(
            Capsule().strokeBorder(level.tint.opacity(0.25), lineWidth: 0.5)
        )
    }
}

struct SettingRow<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 12)
            content
                .frame(minWidth: 220, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }
}

struct HealthRow<Actions: View>: View {
    let title: String
    let symbol: String
    let item: SetupHealthItem
    let actions: Actions

    init(
        title: String,
        symbol: String,
        item: SetupHealthItem,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.symbol = symbol
        self.item = item
        self.actions = actions()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(item.level.tint)
                .frame(width: 28, height: 28)
                .background(item.level.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    StatusBadge(level: item.level, summary: item.summary)
                }

                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    actions
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }
}

struct InlineMessage: View {
    let message: String
    let level: SetupHealthLevel

    var body: some View {
        if !message.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: level.symbolName)
                    .font(.caption)
                    .foregroundStyle(level.tint)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(level.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(level.tint.opacity(0.2), lineWidth: 0.5)
            )
            .transition(.opacity)
        }
    }
}

struct TabHeader: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.bottom, 4)
    }
}
