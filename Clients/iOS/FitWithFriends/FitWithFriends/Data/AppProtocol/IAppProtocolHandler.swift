import Combine
import Foundation

/**
 A protocol defining the interface for handling app-specific protocols.
 */
protocol IAppProtocolHandler: AnyObject {
    /// The current protocol data being handled.
    var protocolData: AppProtocolData? { get }

    /// Publisher for the latest protocol URL that the app has been launched with.
    /// This is useful when the app is already open when the user clicks a protocol link to the app.
    var protocolDataPublisher: Published<AppProtocolData?>.Publisher { get }

    /// Handles a given protocol URL.
    /// - Parameter url: The URL to handle.
    /// - Returns: A boolean indicating whether the protocol was successfully handled.
    func handleProtocol(url: URL) -> Bool

    /// Clears the current protocol data.
    func clearProtocolData()
}
