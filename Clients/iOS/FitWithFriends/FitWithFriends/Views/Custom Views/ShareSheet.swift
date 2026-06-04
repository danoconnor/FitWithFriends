//
//  ShareSheet.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/6/22.
//

import Foundation
import SwiftUI
import UIKit

/// A wrapper around UIActivityViewController.
/// Used for sharing content (URLs, plain text, rendered images) to external apps. Each
/// share target picks the activity items it understands, so a single share can offer an
/// image to Photos/Messages and a URL+text to Mail, etc.
struct ShareSheet: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIActivityViewController

    let activityItems: [Any]

    init(activityItems: [Any]) {
        self.activityItems = activityItems
    }

    /// Convenience for the common "share a single URL" callers.
    init(url: URL) {
        self.activityItems = [url]
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
