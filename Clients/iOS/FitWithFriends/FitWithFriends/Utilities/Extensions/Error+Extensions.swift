//
//  Error+Extensions.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/6/22.
//

import Foundation

extension Error {
    var xtDebugDescription: String {
        (self as NSError).debugDescription
    }
}
