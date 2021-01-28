/************************************************************************//**
 *     PROJECT: PGDocFixer
 *    FILENAME: Extensions.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/13/20
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

extension CharacterSet {

    /*===========================================================================================================================*/
    /// A simple concatination of the CharacterSet.whitespacesAndNewlines and CharacterSet.controlCharacters character sets.
    ///
    @usableFromInline static let whitespacesAndNewlinesAndControlCharacters: CharacterSet = CharacterSet.whitespacesAndNewlines.union(CharacterSet.controlCharacters)
}

extension NSRegularExpression {
    @inlinable func matches(in str: String) -> [NSTextCheckingResult] { matches(in: str, range: str.nsRange) }

    @inlinable func firstMatch(in str: String) -> NSTextCheckingResult? { firstMatch(in: str, range: str.nsRange) }

    @inlinable func enumerateMatches(in string: String, options: NSRegularExpression.MatchingOptions = [], using block: @escaping (NSTextCheckingResult?, NSRegularExpression.MatchingFlags, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateMatches(in: string, options: options, range: string.nsRange, using: block)
    }

    @inlinable func stringByReplacingMatches(in string: String, options: NSRegularExpression.MatchingOptions = [], withTemplate templ: String) -> String {
        stringByReplacingMatches(in: string, options: options, range: string.nsRange, withTemplate: templ)
    }
}

extension NSRange {
    @inlinable func stringRange(_ str: String) -> Range<String.Index> { (stringLowerBounds(str) ..< stringUpperBounds(str)) }

    @inlinable func stringUpperBounds(_ str: String) -> String.Index { String.Index(utf16Offset: upperBound, in: str) }

    @inlinable func stringLowerBounds(_ str: String) -> String.Index { String.Index(utf16Offset: lowerBound, in: str) }
}

extension String {
    @inlinable var nsRange: NSRange { NSRange(location: 0, length: endIndex.utf16Offset(in: self)) }

    @inlinable var trimmed: String { self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlinesAndControlCharacters) }

    @inlinable func index(pos: Int) -> String.Index { String.Index(utf16Offset: pos, in: self) }

    @inlinable func range(from: Int, to: Int) -> Range<String.Index> { (index(pos: from) ..< index(pos: to)) }

    @inlinable func range(from: Int) -> Range<String.Index> { (index(pos: from) ..< endIndex) }

    @inlinable func range(to: Int) -> Range<String.Index> { (startIndex ..< index(pos: to)) }

    @inlinable func substr(from: Int, to: Int) -> String { String(self[range(from: from, to: to)]) }

    @inlinable func substr(from: Int) -> String { String(self[range(from: from)]) }

    @inlinable func substr(to: Int) -> String { String(self[range(to: to)]) }

    @inlinable func substr(nsRange: NSRange) -> String { String(self[nsRange.stringRange(self)]) }

    @usableFromInline func split(regex: NSRegularExpression, limit: Int = 0) -> [String] {
        if self.count > 0 && limit != 1 {
            let matches: [NSTextCheckingResult] = regex.matches(in: self)

            if matches.count > 0 {
                if matches.count == 1 || limit == 2 { return _splitIn2(range: matches[0].range, trim: (limit == 0)) }
                else { return _splitInN(matches: matches, max: (((limit < 1) ? Int.max : limit) - 1), trim: (limit == 0)) }
            }
        }

        return [ self ]
    }

    @inlinable func padding(toLength newLength: Int, withPad padString: String = " ") -> String {
        padding(toLength: newLength, withPad: padString, startingAt: 0)
    }

    private func _splitInN(matches: [NSTextCheckingResult], max: Int, trim: Bool) -> [String] {
        var out: [String] = []
        var lst: Int      = _appendFirstSplitSlice(range: matches[0].range, out: &out)

        for mtch: NSTextCheckingResult in matches[1...] {
            _appendSplitSlice(range: mtch.range, out: &out, lst: &lst)

            if out.count >= max {
                _appendSlice(from: lst, to: count, out: &out)
                return out
            }
        }

        _appendSlice(from: lst, to: count, out: &out)
        return (trim ? _trimStringArray(array: out) : out)
    }

    private func _splitIn2(range: NSRange, trim: Bool) -> [String] {
        let up:  Int    = range.upperBound
        let one: String = self.substr(to: range.location)
        return ((trim && up == count) ? [ one ] : [ one, self.substr(from: up) ])
    }

    private func _trimStringArray(array: [String]) -> [String] {
        let j: Int = array.count - 1
        if j > 0 && array[j].count == 0 {
            for i: Int in stride(from: j - 1, to: 0, by: -1) { if array[i].count > 0 { return Array(array[0 ... i]) } }
            return [ "" ]
        }
        return array
    }

    private func _appendFirstSplitSlice(range: NSRange, out: inout [String]) -> Int {
        var lst: Int = 0
        if range.location > lst || range.length > 0 { _appendSplitSlice(range: range, out: &out, lst: &lst) }
        return lst
    }

    private func _appendSplitSlice(range: NSRange, out: inout [String], lst: inout Int) {
        _appendSlice(from: lst, to: range.location, out: &out)
        lst = range.upperBound
    }

    private func _appendSlice(from: Int, to: Int, out: inout [String]) {
        out.append(to > from ? self.substr(from: from, to: to) : "")
    }

    @inlinable func getPreMatch(start: inout Int, range: NSRange) -> String {
        let s: String = ((start == range.location) ? "" : substr(from: start, to: range.location))
        start = range.upperBound
        return s
    }
}

extension NSTextCheckingResult {
    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - string:
    ///   - match:
    ///   - i:
    /// - Returns:
    ///
    @inlinable func getSub(string: String, at i: Int) -> String {
        if i < numberOfRanges {
            let r: NSRange = range(at: i)
            if r.location != NSNotFound { return string.substr(nsRange: r) }
        }
        return ""
    }
}
