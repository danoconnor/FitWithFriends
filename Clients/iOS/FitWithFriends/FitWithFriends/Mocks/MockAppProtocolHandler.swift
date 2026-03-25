//
//  MockAppProtocolHandler.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/20/22.
//

import Foundation

public class MockAppProtocolHandler: IAppProtocolHandler {
    @Published public var protocolData: AppProtocolData?
    var protocolDataPublisher: Published<AppProtocolData?>.Publisher { $protocolData }

    public init() {}

    public var param_handleProtocol_url: URL?
    public var return_handleProtocol: Bool = true

    public var handleProtocolCallCount = 0
    public func handleProtocol(url: URL) -> Bool {
        handleProtocolCallCount += 1
        param_handleProtocol_url = url
        return return_handleProtocol
    }

    public var return_clearProtocolData_called: Bool = false

    public var clearProtocolDataCallCount = 0
    public func clearProtocolData() {
        clearProtocolDataCallCount += 1
        return_clearProtocolData_called = true
    }
}
