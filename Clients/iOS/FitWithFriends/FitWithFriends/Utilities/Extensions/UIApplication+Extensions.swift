//
//  UIApplication+Extensions.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/5/22.
//

import Foundation
import UIKit

extension UIApplication {
    var keyWindow: UIWindow? {
        // From https://stackoverflow.com/questions/68387187/how-to-use-uiwindowscene-windows-on-ios-15
        return connectedScenes
            // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
            // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
            // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
            // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
}
