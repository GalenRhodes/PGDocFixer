/************************************************************************//**
 *     PROJECT: PGDocFixer
 *    FILENAME: WordWrap.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/15/20
 *
 * Copyright © 2020 Project Galen. All rights reserved.
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

//=============================================================================================================================
///
/// Builds each line.
///
fileprivate final class LineBuilder {
    let prefix2:    String
    let lineLength: Int

    var outs: String = ""
    var line: String = ""
    var idx:  Int    = 0
    var f:    Bool   = true

    init(prefix1: String, prefix2: String, lineLength: Int = 132) {
        self.line = prefix1
        self.prefix2 = prefix2
        self.lineLength = lineLength
    }

    private func addWord(_ str: String) {
        if (line.count + str.count + 1) < lineLength {
            if f {
                line += str
                f = false
            }
            else {
                line += " \(str)"
            }
        }
        else if f {
            outs += "\(line)\(str)\(CR)"
            line = prefix2
        }
        else {
            outs += "\(line)\(CR)"
            line = "\(prefix2)\(str)"
        }
    }

    func addWord(str: String) {
        if idx < str.count { addWord(str.substr(from: idx)) }
    }

    func addWord(str: String, range: NSRange) {
        addWord(str.getPreMatch(start: &idx, range: range))
    }

    func final() -> String {
        outs + line
    }
}

//=================================================================================================================================
///
/// This class supports word wrapping.
///
class WordWrap {

    let prefix1:    String
    let prefix2:    String
    let lineLength: Int

    //=============================================================================================================================
    ///
    /// Initializes the word wrap object.
    ///
    /// - Parameters:
    ///   - prefix1: The prefix to prepend to the beginner of the first line of text.
    ///   - prefix2: the prefix to prepend to all subsequent lines of text.
    ///   - lineLength: the maximum length of each line including the length of each prefix.
    ///
    init(prefix1: String, prefix2: String, lineLength: Int = 132) {
        self.prefix1 = prefix1
        self.prefix2 = prefix2
        self.lineLength = lineLength
    }

    //=============================================================================================================================
    ///
    /// Wraps a string of text to fit in `lineLength` column.
    ///
    /// - Parameter str: the string to wrap.
    /// - Returns: the string formatted into a column of not more than `lineLength` characters.
    ///
    func wrap(str: String) -> String {
        let buffer: LineBuilder = LineBuilder(prefix1: prefix1, prefix2: prefix2, lineLength: lineLength)
        (try! regexML(pattern: "\\s+")).enumerateMatches(in: str) { (m: NSTextCheckingResult?, _, _) in if let m: NSTextCheckingResult = m { buffer.addWord(str: str, range: m.range) } }
        buffer.addWord(str: str)
        return buffer.final()
    }
}

