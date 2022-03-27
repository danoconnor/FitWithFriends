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
/// Used for sharing a URL to external apps
struct ShareSheet: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIActivityViewController

    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
