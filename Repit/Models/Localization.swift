// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import Foundation

/// Resolves English source keys using the app's fixed Spanish interface language.
enum L10n {
    static let locale = Locale(identifier: "es")
    private static let bundle: Bundle = {
        let resourceURL = Bundle.main.bundleURL.appending(path: "es.lproj")
        return Bundle(url: resourceURL) ?? Bundle.main
    }()

    static func text(_ key: String, _ arguments: CVarArg...) -> String {
        let template = bundle.localizedString(forKey: key, value: key, table: nil)
        guard !arguments.isEmpty else { return template }
        return String(format: template, locale: locale, arguments: arguments)
    }
}
