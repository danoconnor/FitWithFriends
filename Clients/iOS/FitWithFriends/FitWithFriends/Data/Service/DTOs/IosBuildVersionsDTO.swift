//
//  IosBuildVersionsDTO.swift
//  FitWithFriends
//

import Foundation

struct IosBuildVersionsDTO: Decodable {
    let recommendedBuild: String
    let requiredBuild: String
}
