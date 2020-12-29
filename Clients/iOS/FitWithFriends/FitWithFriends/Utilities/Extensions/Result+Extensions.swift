//
//  Result+Extensions.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

extension Result {
    var xtSuccess: Success? {
        switch self {
        case let .success(success):
            return success
        default:
            return nil
        }
    }

    var xtError: Error? {
        switch self {
        case let .failure(error):
            return error
        default:
            return nil
        }
    }
}
