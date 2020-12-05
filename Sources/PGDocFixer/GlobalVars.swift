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
let u1:                  String      = "https://developer.apple.com/documentation/swift/"
let u2:                  String      = "https://developer.apple.com/documentation/foundation/"

//@f:0
let NORMAL_FIND_REPLACE: [RegexRepl] = [
    RegexRepl(pattern: "<code>([^<]+)</code>"                 , repl: "`$1`")           ,
    RegexRepl(pattern: "(?<!\\w)(null)(?!\\w)"                , repl: "`nil`")          ,
    RegexRepl(pattern: "(?<!\\w|`)([Tt]rue|[Ff]alse)(?!\\w|`)", repl: "`$1`")           ,
    RegexRepl(pattern: "\\`(\\[[^]]+\\]\\([^)]+\\))\\`"       , repl: "<code>$1</code>"),
    RegexRepl(pattern: "\\{\\@link0 ([^}]+)\\}"               , repl: "<code>[$1](https://developer.apple.com/documentation/swift/$1)</code>"),
    RegexRepl(pattern: "\\{\\@link1 ([^}]+)\\}"               , repl: "<code>[$1](https://developer.apple.com/documentation/foundation/$1)</code>"),
]

/*===============================================================================================================================*/
/// <code>[String](https://developer.apple.com/documentation/swift/String)</code>
///
let URL_PREFIX: [String] = [ u1, u2 ]

let URL_REPLACEMENTS: [String: Int] = [
    "String"                       : 0,
    "Data"                         : 1,
    "Int"                          : 0,
    "Int32"                        : 0,
    "Int64"                        : 0,
    "Int16"                        : 0,
    "Int8"                         : 0,
    "UInt"                         : 0,
    "UInt32"                       : 0,
    "UInt64"                       : 0,
    "UInt16"                       : 0,
    "UInt8"                        : 0,
    "Float"                        : 0,
    "Float80"                      : 0,
    "Float16"                      : 0,
    "Double"                       : 0,
    "Array"                        : 0,
    "Dictionary"                   : 0,
    "Set"                          : 0,
    "Bool"                         : 0,
    "Range"                        : 0,
    "ClosedRange"                  : 0,
    "Error"                        : 0,
    "Result"                       : 0,
    "Optional"                     : 0,
    "SystemRandomNumberGenerator"  : 0,
    "RandomNumberGenerator"        : 0,
    "Character"                    : 0,
    "Unicode"                      : 0,
    "Unicode.Scalar"               : 0,
    "Unicode.ASCII"                : 0,
    "Unicode.UTF8"                 : 0,
    "Unicode.UTF16"                : 0,
    "Unicode.UTF32"                : 0,
    "Unicode.Encoding"             : 0,
    "UTF8"                         : 0,
    "UTF16"                        : 0,
    "UTF32"                        : 0,
    "UnicodeScalar"                : 0,
    "NSRegularExpression"          : 1,
    "InputStream"                  : 1,
    "OutputStream"                 : 1,
    "Stream"                       : 1,
    "UnsafePoint"                  : 0,
    "UnsafeMutablePointer"         : 0,
    "UnsafeBufferPointer"          : 0,
    "UnsafeMutableBufferPointer"   : 0,
    "UnsafeRawPoint"               : 0,
    "UnsafeMutableRawPointer"      : 0,
    "UnsafeRawBufferPointer"       : 0,
    "UnsafeMutableRawBufferPointer": 0,
]
//@f:1

