//
//  FieldEditor.swift
//  Example
//
//  Created by Alan Charles on 5/4/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// A labeled, editable text field with a clear button.
///
/// Two initializers: one for `Binding<String>`, one for `Binding<String?>` that
/// treats empty input as `nil`.
///
///     // Live binding — every keystroke writes through (good for search, filters):
///     FieldEditor("Search", text: $query)
///
///     // Commit-on-submit — writes through on Return key only
///     // (good for SDK-backed values where each write triggers a network/log call):
///     FieldEditor("User ID", text: $settingsStore.userId,
///                 placeholder: "—", commitOnSubmit: true)
///
/// In commit-on-submit mode, external writes to the source binding (e.g., a preset
/// changing `userId`) propagate back into the visible draft via `.onChange`.
///
/// Limitation on iOS 14: no focus-loss commit. The user must press Return on the
/// keyboard for the draft to write through. The X clear button still writes
/// through immediately. If you bump the deployment target to iOS 15+, swap the
/// `onCommit:` initializer for `@FocusState` + `.onSubmit` + `.onChange(of:initial:)`.
struct FieldEditor: View {
    private let label: String
    @Binding private var text: String
    private let placeholder: String
    private let labelWidth: CGFloat?
    private let commitOnSubmit: Bool

    /// Local draft used in commit-on-submit mode. In live mode, the TextField binds
    /// directly to `text` and this stays unused.
    @State private var draft: String = ""

    init(
        _ label: String,
        text: Binding<String>,
        placeholder: String = "",
        labelWidth: CGFloat? = 120,
        commitOnSubmit: Bool = false
    ) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.labelWidth = labelWidth
        self.commitOnSubmit = commitOnSubmit
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .frame(width: labelWidth, alignment: .leading)
            field
            if !displayedText.isEmpty {
                Button {
                    // Clear is an explicit gesture — write through immediately
                    // even in commit-on-submit mode. Keeps the X button predictable.
                    draft = ""
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var field: some View {
        if commitOnSubmit {
            TextField(placeholder, text: $draft, onCommit: commit)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .onChange(of: text) { newValue in
                    if draft != newValue { draft = newValue }
                }
                .onAppear { draft = text }
        } else {
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
        }
    }

    /// What the user actually sees in the field — the draft when committing on
    /// submit, the live source binding otherwise. Used to gate the clear button.
    private var displayedText: String {
        commitOnSubmit ? draft : text
    }

    private func commit() {
        guard commitOnSubmit else { return }
        if text != draft {
            text = draft
        }
    }
}

extension FieldEditor {
    /// Convenience initializer for optional bindings. Empty input is rendered as `nil`.
    init(
        _ label: String,
        text: Binding<String?>,
        placeholder: String = "",
        labelWidth: CGFloat? = 120,
        commitOnSubmit: Bool = false
    ) {
        self.init(
            label,
            text: Binding(
                get: { text.wrappedValue ?? "" },
                set: { text.wrappedValue = $0.isEmpty ? nil : $0 }
            ),
            placeholder: placeholder,
            labelWidth: labelWidth,
            commitOnSubmit: commitOnSubmit
        )
    }
}

#Preview {
    VStack(alignment: .leading) {
        FieldEditor("Name", text: .constant("alice"), placeholder: "name")
        FieldEditor(
            "User ID", text: .constant(""), placeholder: "—",
            commitOnSubmit: true)
        FieldEditor("Empty", text: .constant(""), placeholder: "type here")
    }
    .padding()
}
