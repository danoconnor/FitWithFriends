//
//  MockAppProtocolHandler.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/20/22.
//

import Foundation

class MockAppProtocolHandler: AppProtocolHandler {
    var return_protocolData: AppProtocolData?
    override var protocolData: AppProtocolData? {
        return return_protocolData
    }

    var return_handleProtocol = false
    override func handleProtocol(url: URL) -> Bool {
        return return_handleProtocol
    }
}
