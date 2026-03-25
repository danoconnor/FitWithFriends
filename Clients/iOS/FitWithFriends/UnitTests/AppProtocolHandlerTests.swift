import XCTest
import Combine
@testable import Fit_with_Friends

final class AppProtocolHandlerTests: XCTestCase {
    private var appProtocolHandler: AppProtocolHandler!

    override func setUp() {
        super.setUp()
        appProtocolHandler = AppProtocolHandler()
    }

    override func tearDown() {
        appProtocolHandler = nil
        super.tearDown()
    }

    func test_handleProtocol_withValidJoinCompetitionURL_shouldReturnTrueAndSetProtocolData() {
        // Arrange
        let competitionId = UUID()
        let competitionToken = "abcde"
        let url = URL(string: "fitwithfriends://joincompetition?competitionId=\(competitionId.uuidString)&competitionToken=\(competitionToken)")!

        let (expectation, cancellable) = expectProtocolDataUpdate(expectParsedData: true)

        // Act
        let handled = appProtocolHandler.handleProtocol(url: url)

        // Assert
        XCTAssertTrue(handled, "The URL should be handled successfully")
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(appProtocolHandler.protocolData, "Protocol data should be set")
        XCTAssertTrue(appProtocolHandler.protocolData is JoinCompetitionProtocolData, "Protocol data should be of type JoinCompetitionProtocolData")

        if let protocolData = appProtocolHandler.protocolData as? JoinCompetitionProtocolData {
            XCTAssertEqual(protocolData.competitionId, competitionId, "Competition ID should match the query parameter")
            XCTAssertEqual(protocolData.competitionToken, competitionToken, "Competition token should match the query parameter")
        }

        cancellable.cancel()
    }

    func test_handleProtocol_withInvalidURL_shouldReturnFalseAndNotSetProtocolData() {
        // Arrange
        let url = URL(string: "fitwithfriends://invalidaction")!

        let (expectation, cancellable) = expectProtocolDataUpdate(expectParsedData: false)

        // Act
        let handled = appProtocolHandler.handleProtocol(url: url)

        // Assert
        XCTAssertFalse(handled, "The URL should not be handled")
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(appProtocolHandler.protocolData, "Protocol data should not be set")

        cancellable.cancel()
    }

    func test_handleProtocol_withAssociatedDomainURL_shouldReturnTrueAndSetProtocolData() {
        // Arrange
        let competitionId = UUID()
        let competitionToken = "abcde"
        let url = URL(string: "https://fitwithfriends.com/joincompetition?competitionId=\(competitionId.uuidString)&competitionToken=\(competitionToken)")!

        let (expectation, cancellable) = expectProtocolDataUpdate(expectParsedData: true)

        // Act
        let handled = appProtocolHandler.handleProtocol(url: url)

        // Assert
        XCTAssertTrue(handled, "The URL should be handled successfully")
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(appProtocolHandler.protocolData, "Protocol data should be set")
        XCTAssertTrue(appProtocolHandler.protocolData is JoinCompetitionProtocolData, "Protocol data should be of type JoinCompetitionProtocolData")

        if let protocolData = appProtocolHandler.protocolData as? JoinCompetitionProtocolData {
            XCTAssertEqual(protocolData.competitionId, competitionId, "Competition ID should match the query parameter")
            XCTAssertEqual(protocolData.competitionToken, competitionToken, "Competition token should match the query parameter")
        }

        cancellable.cancel()
    }

    func test_clearProtocolData_shouldSetProtocolDataToNil() {
        // Arrange
        let url = URL(string: "fitwithfriends://joincompetition?competitionId=12345")!
        _ = appProtocolHandler.handleProtocol(url: url)

        // Act
        appProtocolHandler.clearProtocolData()

        // Assert
        XCTAssertNil(appProtocolHandler.protocolData, "Protocol data should be cleared")
    }

    // The protocol data is updated async during parsing, so create an expectation to wait for that update
    private func expectProtocolDataUpdate(expectParsedData: Bool, timeout: TimeInterval = 1.0) -> (XCTestExpectation, AnyCancellable) {
        let expectation = XCTestExpectation(description: "Protocol data should be updated")
        var cancellable: AnyCancellable!

        cancellable = appProtocolHandler.protocolDataPublisher.sink { data in
            if expectParsedData && data != nil {
                expectation.fulfill()
            } else if !expectParsedData && data == nil {
                expectation.fulfill()
            }
        }

        return (expectation, cancellable)
    }
}
