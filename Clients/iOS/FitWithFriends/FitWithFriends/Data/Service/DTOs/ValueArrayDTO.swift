//
//  ValueArrayDTO.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/12/24.
//

import Foundation

/// Allows sending a POST request with an array of entities
public struct ValueArrayDTO<T>: Encodable where T : Encodable {
    public let values: [T]
}
