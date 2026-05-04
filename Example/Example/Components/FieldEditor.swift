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
///     FieldEditor("User ID", text: $settingsStore.userId, placeholder: "—")
///     FieldEditor("Search", text: $query)
struct FieldEditor: View {
    private let label: String
    @Binding private var text: String
    private let placeholder: String
    private let labelWidth: CGFloat?

    init(
        _ label: String,
        text: Binding<String>,
        placeholder: String = "",
        labelWidth: CGFloat? = 120
    ) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.labelWidth = labelWidth
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .frame(width: labelWidth, alignment: .leading)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
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
}

extension FieldEditor {
    /// Convenience initializer for optional bindings. Empty input is rendered as `nil`.
    init(
        _ label: String,
        text: Binding<String?>,
        placeholder: String = "",
        labelWidth: CGFloat? = 120
    ) {
        self.init(
            label,
            text: Binding(
                get: { text.wrappedValue ?? "" },
                set: { text.wrappedValue = $0.isEmpty ? nil : $0 }
            ),
            placeholder: placeholder,
            labelWidth: labelWidth
        )
    }
}

#Preview {
    VStack(alignment: .leading) {
        FieldEditor("Name", text: .constant("alice"), placeholder: "name")
        FieldEditor("User ID", text: .constant(""), placeholder: "—")
        FieldEditor("Empty", text: .constant(""), placeholder: "type here")
    }
    .padding()
}
