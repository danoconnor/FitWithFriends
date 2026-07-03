//
//  ShareSheet.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/6/22.
//

import Foundation
import SwiftUI
import UIKit

/// A wrapper around UIActivityViewController
/// Used for sharing a URL or plain text to external apps
struct ShareSheet: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIActivityViewController

    let activityItems: [Any]

    init(url: URL) {
        self.activityItems = [url]
    }

    init(text: String) {
        self.activityItems = [text]
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
