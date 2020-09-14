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
        // @f:0
        let args: [String] = [ "docFixer",
                               "--remote-host",  "goober",
                               "--remote-user",  "grhodes",
                               "--remote-path",  "/var/www/html/PGDocFixer",
                               "--log-file",     "./test.log",
                               "--archive-file", "./docs.tar",
                               "--comment-type", "slashes",
                               "--line-length",  "132",
                               "Sources" ]
        // @f:1
        print("""

              EXIT CODE: \(doDocFixer(args: args, replacements: SIMPLEONES))
              """)
    }
}
