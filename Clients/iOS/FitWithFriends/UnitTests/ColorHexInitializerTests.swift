//
//  ColorHexInitializerTests.swift
//  FitWithFriends
//
//  Covers the `Color(hex:)` initializer added to support the design-system
//  palette (used by FWFAvatar's deterministic color list and the activity
//  strip cards).
//

import SwiftUI
import XCTest
@testable import Fit_with_Friends

final class ColorHexInitializerTests: XCTestCase {

    func test_hex_acceptsSixCharString() {
        // Sanity check: equivalent to red via direct RGB.
        let fromHex = Color(hex: "FF0000")
        let fromRGB = Color(.sRGB, red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        XCTAssertEqual(fromHex.description, fromRGB.description)
    }

    func test_hex_acceptsHashPrefix() {
        XCTAssertEqual(Color(hex: "#16181D").description, Color(hex: "16181D").description)
    }

    func test_hex_isCaseInsensitive() {
        XCTAssertEqual(Color(hex: "fa114f").description, Color(hex: "FA114F").description)
    }

    func test_hex_acceptsEightCharStringWithAlpha() {
        // 80 alpha = 128/255 ≈ 0.5
        let translucent = Color(hex: "80FF0000")
        let expected = Color(.sRGB, red: 1.0, green: 0.0, blue: 0.0, opacity: 128.0 / 255.0)
        XCTAssertEqual(translucent.description, expected.description)
    }

    func test_hex_invalidStringYieldsBlackOpaque() {
        // Out-of-spec strings should produce a deterministic fallback (black) rather than crashing.
        let black = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1.0)
        XCTAssertEqual(Color(hex: "ZZ").description, black.description)
    }
}
