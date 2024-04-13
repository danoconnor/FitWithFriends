//
//  EmptyResponse.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import Foundation

/// Used as the expected response data type when we don't expect the server to return any data
public class EmptyResponse: Decodable { 
    public init() {}
}
