//
//  ErrorWithDetails.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/22.
//

import Foundation

public protocol ErrorWithDetails {
    var errorDetails: FWFErrorDetails? { get }
}
