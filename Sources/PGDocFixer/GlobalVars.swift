/************************************************************************//**
 *     PROJECT: PGDocFixer
 *    FILENAME: GlobalVars.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/4/20
 *
 * Copyright © 2020 Galen Rhodes. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//************************************************************************/

import Foundation

let CR:     String = "\n"
let SPC:    String = " "
let BELEMS: String = "(p|div|table|dl|ol|ul|h1|h2|h3|h4|h5|h6|pre|dt|dd|li|dir|address|article|aside|blockquote|center|del|figure|figcaption|footer|header|hr|ins|main|menu|nav|noscript|section|script)"

let a:                   String      = "(?<!\\w|\\.|/|\\[|@link[01] )\\`?"
let b:                   String      = "\\`?(?!\\w|\\]|\\)|\\})"
let u1:                  String      = "https://developer.apple.com/documentation/swift"
let u2:                  String      = "https://developer.apple.com/documentation/foundation"

//@f:0
let NORMAL_FIND_REPLACE: [RegexRepl] = [
    RegexRepl(pattern: "<code>([^<]+)</code>"                 , repl: "`$1`")           ,
    RegexRepl(pattern: "(?<!\\w)(null)(?!\\w)"                , repl: "`nil`")          ,
    RegexRepl(pattern: "(?<!\\w|`)([Tt]rue|[Ff]alse)(?!\\w|`)", repl: "`$1`")           ,
    RegexRepl(pattern: "\\`(\\[[^]]+\\]\\([^)]+\\))\\`"       , repl: "<code>$1</code>"),
    RegexRepl(pattern: "\\{\\@link0 ([^}]+)\\}"               , repl: "<code>[$1](\(u1)/$1)</code>"),
    RegexRepl(pattern: "\\{\\@link1 ([^}]+)\\}"               , repl: "<code>[$1](\(u2)/$1)</code>"),
]

/*===============================================================================================================================*/
/// <code>[String](https://developer.apple.com/documentation/swift/String)</code>
///
let URL_PREFIX: [String] = [ u1, u2 ]
let URL_REPLACEMENTS: [String: Int] = [:]
//@f:1
