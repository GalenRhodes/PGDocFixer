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
        let results: [String] = try! processDocument(filenames: [ "/Users/grhodes/Projects/2020/SwiftProjects/PGSwiftDOM/PGSwiftDOM/Source/DTD.swift" ],
                                                     findsAndReplacements: SIMPLEONES,
                                                     lineLength: 132)

        for str: String in results {
            print(str)
        }
    }
}
