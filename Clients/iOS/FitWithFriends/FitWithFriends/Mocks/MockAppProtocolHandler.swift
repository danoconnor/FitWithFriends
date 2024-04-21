//
//  MockAppProtocolHandler.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/20/22.
//

import Foundation

public class MockAppProtocolHandler: AppProtocolHandler {
    public  var return_protocolData: AppProtocolData?
    override public var protocolData: AppProtocolData? {
        return return_protocolData
    }

    public var return_handleProtocol = false
    override public func handleProtocol(url: URL) -> Bool {
        return return_handleProtocol
    }
}
