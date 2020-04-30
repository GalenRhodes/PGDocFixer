//
//  PGDocFixerTests.swift
//  PGDocFixerTests
//
//  Created by Galen Rhodes on 4/9/20.
//  Copyright © 2020 Project Galen. All rights reserved.
//

import XCTest
@testable import PGDocFixer

class PGDocFixerTests: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testProcessDocument() throws {
        try docFixerII(path: "Rubicon", matchAndReplace: [], logFile: "./runlogtest.txt", docOutput: .Slashes, lineLength: 132)
    }
}
