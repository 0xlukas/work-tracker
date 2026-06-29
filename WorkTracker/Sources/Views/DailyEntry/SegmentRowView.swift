import SwiftUI

struct SegmentRowView: View {
    let segment: WorkSegment
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Time range indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(.blue)
                .frame(width: 3, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(segment.startTime, format: .dateTime.hour().minute())
                    Text("–")
                        .foregroundStyle(.tertiary)
                    Text(segment.endTime, format: .dateTime.hour().minute())
                }
                .font(.body.monospacedDigit())

                if let project = segment.project {
                    Text(project.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(TimeFormatting.hours(segment.durationHours))
                .font(.subheadline.monospacedDigit())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(.primary.opacity(0.05)))

            if isHovered {
                HStack(spacing: 2) {
                    Button { onEdit() } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help(tr("Edit entry"))
                    .accessibilityLabel(tr("Edit entry"))

                    Button { onDelete() } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help(tr("Delete entry"))
                    .accessibilityLabel(tr("Delete entry"))
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        // Double-click to edit; right-click for keyboard/VoiceOver-reachable actions.
        .onTapGesture(count: 2) { onEdit() }
        .contextMenu {
            Button { onEdit() } label: { Label(tr("Edit Entry"), systemImage: "pencil") }
            Button(role: .destructive) { onDelete() } label: { Label(tr("Delete Entry"), systemImage: "trash") }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tr("Time entry %@ to %@, %@",
                               TimeField.format(segment.startTime),
                               TimeField.format(segment.endTime),
                               TimeFormatting.hours(segment.durationHours))
                            + (segment.project.map { ", \($0.name)" } ?? ""))
    }
}
