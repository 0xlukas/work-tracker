import SwiftUI
import AppKit

struct ComboBoxPicker: NSViewRepresentable {
    let projects: [Project]
    @Binding var selection: Project?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSComboBox {
        let comboBox = NSComboBox()
        comboBox.usesDataSource = false
        comboBox.completes = true  // Auto-complete as you type
        comboBox.isEditable = true
        comboBox.hasVerticalScroller = true
        comboBox.numberOfVisibleItems = 8
        comboBox.delegate = context.coordinator
        comboBox.target = context.coordinator
        comboBox.action = #selector(Coordinator.comboBoxAction(_:))
        comboBox.placeholderString = "Type to search..."
        comboBox.font = .systemFont(ofSize: NSFont.systemFontSize)
        comboBox.controlSize = .regular
        return comboBox
    }

    func updateNSView(_ comboBox: NSComboBox, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updating = true

        comboBox.removeAllItems()
        comboBox.addItems(withObjectValues: projects.map { $0.name })

        if let selected = selection {
            if comboBox.stringValue != selected.name {
                comboBox.stringValue = selected.name
            }
        } else if comboBox.stringValue.isEmpty {
            comboBox.stringValue = ""
        }

        context.coordinator.updating = false
    }

    class Coordinator: NSObject, NSComboBoxDelegate {
        var parent: ComboBoxPicker
        var updating = false

        init(_ parent: ComboBoxPicker) {
            self.parent = parent
        }

        @objc func comboBoxAction(_ sender: NSComboBox) {
            selectProject(from: sender.stringValue)
        }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard !updating, let comboBox = notification.object as? NSComboBox else { return }
            let index = comboBox.indexOfSelectedItem
            if index >= 0 && index < parent.projects.count {
                parent.selection = parent.projects[index]
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard let comboBox = obj.object as? NSComboBox else { return }
            selectProject(from: comboBox.stringValue)
        }

        private func selectProject(from text: String) {
            guard !updating else { return }
            if let match = parent.projects.first(where: { $0.name.localizedCaseInsensitiveCompare(text) == .orderedSame }) {
                parent.selection = match
            } else if let match = parent.projects.first(where: { $0.name.localizedCaseInsensitiveContains(text) }) {
                parent.selection = match
            }
        }
    }
}
