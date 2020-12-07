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
                               "--project",          "Rubicon",
                               "--remote-host",      "goober",
                               "--remote-user",      "grhodes",
                               "--remote-path",      "/var/www/html/Rubicon",
                               "--swift-doc-format", "HTML",
                               "Sources/Rubicon" ]
        // @f:1
        let mAndR: [RegexRepl] = [
            RegexRepl(pattern: "(?<!\\w|`)(nil)(?!\\w|`)", repl: "`$1`"),
            RegexRepl(pattern: "(?<!\\w|`)(\\w+(?:\\.\\w+)*\\([^)]*\\))(?!\\w|`)", repl: "`$1`"),
            RegexRepl(pattern: "(?<!\\w|\\[)([Zz][Ee][Rr][Oo])(?!\\w|\\])", repl: "<code>[$1](https://en.wikipedia.org/wiki/0)</code>")
        ]
        let ec = doDocFixer(args: args, replacements: mAndR)
        print("""

              EXIT CODE: \(ec)
              """)
    }
}
