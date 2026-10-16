// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.text("Credits")) {
                    HStack(spacing: 12) {
                        RepitSymbol().frame(width: 30, height: 32)
                        Text("repit").font(.system(.title2, design: .rounded).bold())
                    }.padding(.vertical, 6)
                    Text("Copyright © 2026 gsanz.dev").textSelection(.enabled)
                    Text(L10n.text("Original project copyright notice. Modified versions may identify their contributions separately."))
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
                Section(L10n.text("Free software")) {
                    Text(L10n.text("GNU GPL version 3, with attribution notice preservation."))
                    Text(L10n.text("You may use, copy, modify, and redistribute this software under its license. It comes without warranty unless expressly stated otherwise."))
                        .font(.subheadline)
                    NavigationLink(L10n.text("Read GNU GPLv3")) {
                        LegalTextView(title: "GNU GPLv3", resource: "LICENSE", fileExtension: nil)
                    }.accessibilityIdentifier("readLicense")
                    NavigationLink(L10n.text("Read attribution condition")) {
                        LegalTextView(title: L10n.text("Attribution"), resource: "ATTRIBUTION", fileExtension: "md")
                    }.accessibilityIdentifier("readAttribution")
                }
                Section(L10n.text("Source code for this version")) {
                    if let source = Bundle.main.url(forResource: "Repit-Source", withExtension: "zip") {
                        ShareLink(item: source) {
                            Label(L10n.text("Save or share source code"), systemImage: "doc.zipper")
                        }.accessibilityIdentifier("shareSource")
                        Text(L10n.text("The app includes a ZIP with the source for this build, the Xcode project, and instructions to modify and build it."))
                            .font(.footnote).foregroundStyle(Theme.muted)
                    } else {
                        Text(L10n.text("The source archive was not found in this build."))
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Theme.background)
            .navigationTitle(L10n.text("About repit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("Close")) { dismiss() }.accessibilityIdentifier("closeAbout")
                }
            }
        }
    }
}

private struct LegalTextView: View {
    let title: String
    let resource: String
    let fileExtension: String?

    private var text: String {
        guard let url = Bundle.main.url(forResource: resource, withExtension: fileExtension),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return L10n.text("The legal text could not be opened in this build.")
        }
        return contents
    }

    var body: some View {
        ScrollView {
            Text(text)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .accessibilityIdentifier("legalText")
        }
        .background(Theme.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
