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

            Text(formatHours(segment.durationHours))
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

                    Button { onDelete() } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
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
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int(((hours - Double(h)) * 60).rounded())
        return String(format: "%dh %02dm", h, m)
    }
}
