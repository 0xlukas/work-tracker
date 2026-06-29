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
                    .font(.largeTitle)
                    .foregroundStyle(.red.opacity(0.7))
                    .padding(.bottom, 32)
                    .accessibilityHidden(true)

                // Quote
                Text("\u{201C}\(quote.text)\u{201D}")
                    .font(.system(.title, design: .serif).weight(.light))
                    .italic()
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .frame(maxWidth: 560)

                // Attribution
                VStack(spacing: 4) {
                    Text("— \(quote.thinker)")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(.white.opacity(0.85))

                    if let source = quote.source {
                        Text(source)
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.top, 24)

                Spacer()

                // Dismiss hint
                Text(tr("Press any key, or click anywhere, to start your day"))
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 28)
            }
            .padding(48)

            // Visible, accessible close affordance (Escape and any-key also dismiss).
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)   // Escape
                    .help(tr("Dismiss (Esc)"))
                    .accessibilityLabel(tr("Dismiss quote"))
                    .padding(20)
                }
                Spacer()
            }

            // Invisible key/mouse capture (any key or click dismisses)
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
