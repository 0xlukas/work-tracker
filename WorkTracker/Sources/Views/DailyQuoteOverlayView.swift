import SwiftUI
import AppKit

struct DailyQuoteOverlayView: View {
    let quote: DailyQuote
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.88)

            VStack(spacing: 0) {
                Spacer()

                // Red star accent
                Image(systemName: "star.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.red.opacity(0.7))
                    .padding(.bottom, 32)

                // Quote
                Text("\u{201C}\(quote.text)\u{201D}")
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .frame(maxWidth: 560)

                // Attribution
                VStack(spacing: 4) {
                    Text("— \(quote.thinker)")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(.white.opacity(0.85))

                    if let source = quote.source {
                        Text(source)
                            .font(.system(size: 13, weight: .regular, design: .serif))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.top, 24)

                Spacer()

                // Dismiss hint
                Text("Press any key to start your day")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, 28)
            }
            .padding(48)

            // Invisible key/mouse capture
            KeyCaptureRepresentable(onEvent: onDismiss)
                .frame(width: 0, height: 0)
        }
    }
}

// MARK: - Key & Mouse Capture

private struct KeyCaptureRepresentable: NSViewRepresentable {
    var onEvent: () -> Void

    func makeNSView(context: Context) -> KeyCaptureNSView {
        let view = KeyCaptureNSView()
        view.onEvent = onEvent
        return view
    }

    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) {
        nsView.onEvent = onEvent
    }
}

final class KeyCaptureNSView: NSView {
    var onEvent: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeFirstResponder(self)
        }
    }

    override func keyDown(with event: NSEvent) {
        onEvent?()
    }

    override func mouseDown(with event: NSEvent) {
        onEvent?()
    }
}
