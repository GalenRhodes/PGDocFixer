/************************************************************************//**
 *     PROJECT: PGDocFixer
 *    FILENAME: DocFixer.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/9/2020
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

let rxLead: String = "^([ \\t]*///[ \\t]+)"
let rxLine: String = "\(rxLead)((([|+*-])[ \\t]?)?(.+?))[ \\t]*\\R"

let rx1:                 NSRegularExpression = try! regexML(pattern: "(\(rxLine))+")
let rx2:                 NSRegularExpression = try! regexML(pattern: rxLine)
let rx3:                 NSRegularExpression = try! regexML(pattern: "\\s+")
let rx4:                 NSRegularExpression = try! regexML(pattern: "^\\-[ \\t]*([^:]+:[ \\t]){1,2}")
let rx5:                 NSRegularExpression = try! regexML(pattern: "\\s*\\|\\s*")
let rx6:                 NSRegularExpression = try! regexML(pattern: "^(?:(\\:\\-{3,}\\:)|(\\-{3,}\\:)|(\\:?\\-{3,}))$")
let rx7:                 NSRegularExpression = try! regexML(pattern: "\\R")
let rx8:                 NSRegularExpression = try! regexML(pattern: "`([^`]+)`")
let rxFinal:             NSRegularExpression = try! regexML(pattern: "``")

//@f:0
let NORMAL_FIND_REPLACE: [RegexRepl] = [
    RegexRepl(pattern: "<code>([^<]+)</code>",                      repl: "`$1`"),
    RegexRepl(pattern: "(?<!\\w)(null)(?!\\w)",                     repl: "`nil`"),
    RegexRepl(pattern: "(?<!\\w|`)([Tt]rue|[Ff]alse)(?!\\w|`)",     repl: "`$1`"),
    RegexRepl(pattern: "\\`(\\[[^]]+\\]\\([^)]+\\))\\`",            repl: "<code>$1</code>"),
]
//@f:1

///
///
/// - FileNotFound:
///
public enum DocFixerErrors: Error {
    ///
    case FileNotFound(description: String)
}

///
///
/// - Left:
/// - Center:
/// - Right:
///
enum Alignment {
    case Left
    case Center
    case Right

    //==========================================================================================================================================
    ///
    ///
    /// - Parameter str:
    /// - Returns:
    ///
    static func testAlignment(_ str: String) -> Alignment? {
        if let m: NSTextCheckingResult = rx6.firstMatch(in: str) {
            if m.range(at: 1).location != NSNotFound { return .Center }
            if m.range(at: 2).location != NSNotFound { return .Right }
            if m.range(at: 3).location != NSNotFound { return .Left }
        }
        return nil
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameter align:
    /// - Returns:
    ///
    static func getAlignText(_ align: Alignment) -> String {
        switch align {
            case .Left: return "left"
            case .Center: return "center"
            case .Right: return "right"
        }
    }
}

public class RegexRepl {
    let regex: NSRegularExpression
    let repl:  String

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - pattern:
    ///   - repl:
    public init(pattern: String, repl: String) {
        self.regex = try! regexML(pattern: pattern)
        self.repl = repl
    }
}

public class PGDocFixer {

    let CR:                     String = "\n"
    let SPC:                    String = " "
    let maxLineLength:          Int
    let twoThirdsMaxLineLength: Int
    let tablesAsMarkdown:       Bool
    let findReplace:            [RegexRepl]

    init(findAndReplace: [RegexRepl], lineLength: Int = 132) {
        self.maxLineLength = lineLength
        self.twoThirdsMaxLineLength = ((lineLength * 2) / 3)
        self.findReplace = findAndReplace
        self.tablesAsMarkdown = false
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - prefix:
    ///   - word:
    ///   - ic:
    ///   - maxln:
    ///   - line:
    ///   - outs:
    ///
    func foo02(_ prefix: String, _ word: String, _ ic: Int, _ maxln: Int, _ line: inout String, _ outs: inout String) {
        let lc: Int = line.count

        if lc == 0 {
            line = word
        }
        else if (lc + word.count + (outs.isEmpty ? 0 : ic) + 1) < maxln {
            line += SPC + word
        }
        else {
            outs += prefix + line + CR
            line = word
        }
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - indent:
    ///   - para:
    /// - Returns:
    ///
    func adjustIndent(indent: String, para: String) -> Int {
        if let m: NSTextCheckingResult = rx4.firstMatch(in: para) {
            let ic: Int = para.substr(range: m.range).count
            return ((ic >= maxLineLength) ? indent.count : (ic >= twoThirdsMaxLineLength ? indent.count + 4 : ic))
        }
        return indent.count
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - prefix:
    ///   - tab:
    ///   - tag:
    ///   - columnCount:
    ///   - row:
    ///   - columnAligns:
    ///   - outs:
    ///
    func buildHTMLTableRow(_ prefix: String, _ tab: String, _ tag: String, _ columnCount: Int, _ row: [String], _ columnAligns: [Alignment], _ outs: inout String) {
        outs += "\(prefix)\(tab)\(tab)<tr>\n"

        for i: Int in (0 ..< columnCount) {
            let colValue: String = rx8.stringByReplacingMatches(in: (i < row.count ? row[i] : ""), withTemplate: "<code>$1</code>")
            let colAlign: String = Alignment.getAlignText(i < columnAligns.count ? columnAligns[i] : Alignment.Left)
            outs += "\(prefix)\(tab)\(tab)\(tab)<\(tag) align=\"\(colAlign)\"" + (colValue.isEmpty ? " />\n" : ">\(colValue)</\(tag)>\n")
        }

        outs += "\(prefix)\(tab)\(tab)</tr>\n"
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - prefix:
    ///   - table:
    ///   - columnAligns:
    ///   - headerIndex:
    ///   - columnCount:
    /// - Returns:
    ///
    func dumpTableAsHTML(_ prefix: String, _ table: [[String]], _ columnAligns: [Alignment], _ headerIndex: Int, _ columnCount: Int) -> String {
        var outs:     String = "\(prefix)<table class=\"gsr\">\n"
        let tab:      String = "    "
        let rowCount: Int    = table.count
        let hdr:      Int    = ((headerIndex > 0) ? min(headerIndex, rowCount) : 0)

        if hdr > 0 {
            outs += "\(prefix)\(tab)<thead>\n"
            for i: Int in (0 ..< hdr) { buildHTMLTableRow(prefix, tab, "th", columnCount, table[i], columnAligns, &outs) }
            outs += "\(prefix)\(tab)</thead>\n"
        }

        if hdr < rowCount {
            outs += "\(prefix)\(tab)<tbody>\n"
            for i: Int in (hdr ..< rowCount) { buildHTMLTableRow(prefix, tab, "td", columnCount, table[i], columnAligns, &outs) }
            outs += "\(prefix)\(tab)</tbody>\n"
        }

        outs += "\(prefix)</table>\n"
        return outs
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - row:
    ///   - columnWidths:
    ///   - outs:
    ///
    func buildTableRow(_ prefix: String, _ row: [String], _ columnWidths: [Int], _ outs: inout String) {
        let colCount: Int = row.count
        outs += prefix

        for (j, width): (Int, Int) in columnWidths.enumerated() {
            outs += ("| " + ((j < colCount) ? row[j] : "")).padding(toLength: width + 3)
        }

        outs += "|\n"
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - columnAligns:
    ///   - columnWidths:
    ///   - outs:
    ///
    func buildAlignments(_ prefix: String, _ columnAligns: [Alignment], _ columnWidths: [Int], _ outs: inout String) {
        let alignCount: Int = columnAligns.count
        outs += prefix

        for (j, width): (Int, Int) in columnWidths.enumerated() {
            if j < alignCount {
                switch columnAligns[j] {
                    case .Left:   outs += "|----".padding(toLength: width + 3, withPad: "-")
                    case .Center: outs += "|:---".padding(toLength: width + 2, withPad: "-") + ":"
                    case .Right:  outs += "|----".padding(toLength: width + 2, withPad: "-") + ":"
                }
            }
            else {
                outs += "|----".padding(toLength: width + 3, withPad: "-")
            }
        }

        outs += "|\n"
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - prefix:
    ///   - table:
    ///   - headerIndex:
    ///   - columnWidths:
    ///   - columnAligns:
    /// - Returns:
    ///
    func dumpTableAsMarkdown(_ prefix: String, _ table: [[String]], _ headerIndex: Int, _ columnWidths: [Int], _ columnAligns: [Alignment]) -> String {
        var outs: String = ""

        // Now dump the table back out...
        for (i, row): (Int, [String]) in table.enumerated() {
            if i == headerIndex { buildAlignments(prefix, columnAligns, columnWidths, &outs) }
            buildTableRow(prefix, row, columnWidths, &outs)
        }

        return outs
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - prefix:
    ///   - table:
    ///   - headerIndex:
    ///   - columnWidths:
    ///   - columnAligns:
    /// - Returns:
    ///
    func dumpTable(_ prefix: String, _ table: [[String]], _ headerIndex: Int, _ columnWidths: [Int], _ columnAligns: [Alignment]) -> String {
        if tablesAsMarkdown {
            return dumpTableAsMarkdown(prefix, table, headerIndex, columnWidths, columnAligns)
        }
        else {
            return dumpTableAsHTML(prefix, table, columnAligns, headerIndex, columnWidths.count)
        }
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - rowstr:
    ///   - headerIndex:
    ///   - maxColumns:
    ///   - columnWidths:
    ///   - columnAligns:
    ///   - table:
    ///
    func stripTableRow(_ rowstr: String, _ headerIndex: inout Int, _ maxColumns: inout Int, _ columnWidths: inout [Int], _ columnAligns: inout [Alignment], _ table: inout [[String]]) {
        let tabrow: [String] = rowstr.split(regex: rx5)

        if headerIndex < 0, let _ = Alignment.testAlignment(tabrow[0]) {
            headerIndex = table.count
            for c: String in tabrow {
                columnAligns.append(Alignment.testAlignment(c) ?? Alignment.Left)
            }
        }
        else {
            let tc:  Int = tabrow.count
            let cwc: Int = columnWidths.count

            maxColumns = max(maxColumns, tc)
            table.append(tabrow)

            for (ci, str): (Int, String) in tabrow.enumerated() {
                if ci < cwc {
                    columnWidths[ci] = max(columnWidths[ci], str.count)
                }
                else {
                    columnWidths.append(str.count)
                }
            }
        }
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - elem:
    ///   - table:
    ///   - headerIndex:
    ///   - columnWidths:
    ///   - columnAligns:
    ///
    func processHTMLSub(_ elem: HTMLElement, _ table: inout [[String]], _ headerIndex: inout Int, _ columnWidths: inout [Int], _ columnAligns: inout [Alignment]) {
        if elem.name == "tr" {
            var ci:  Int      = 0
            var row: [String] = []

            for e1: HTMLElement in elem.children {
                let name: String = e1.name

                if name == "th" || name == "td" {
                    if name == "th" && headerIndex < 0 { headerIndex = table.count + 1 }
                    let s: String = doSimpleOnes(string: e1.innerDescription.trimmed)
                    row.append(s)
                    if ci < columnWidths.count { columnWidths[ci] = max(columnWidths[ci], s.count) }
                    else { columnWidths.append(s.count) }
                    ci += 1
                }
            }

            table.append(row)
        }
        else {
            for e: HTMLElement in elem.children {
                processHTMLSub(e, &table, &headerIndex, &columnWidths, &columnAligns)
            }
        }
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - prefix:
    ///   - tabstr:
    /// - Returns:
    ///
    func processHTMLTable(prefix: String, table tabstr: String) -> String {
        if let elem: HTMLElement = scanHTML(string: tabstr) {
            if elem.name == "table" {
                var table:        [[String]]  = []
                var headerIndex:  Int         = -1
                var columnWidths: [Int]       = []
                var columnAligns: [Alignment] = []

                for e: HTMLElement in elem.children {
                    processHTMLSub(e, &table, &headerIndex, &columnWidths, &columnAligns)
                }

                return dumpTable(prefix, table, headerIndex, columnWidths, columnAligns)
            }
        }

        return prefix + tabstr
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - prefix:
    ///   - tabstr:
    /// - Returns:
    ///
    func processTable(prefix: String, table tabstr: String) -> String {
        var table:        [[String]]  = []
        var idx01:        Int         = 0
        var maxColumns:   Int         = 0
        var headerIndex:  Int         = -1
        var columnWidths: [Int]       = []
        var columnAligns: [Alignment] = []
        let fixedStr:     String      = doSimpleOnes(string: tabstr)

        rx7.enumerateMatches(in: fixedStr) {
            (m: NSTextCheckingResult?, _, _) in
            if let m: NSTextCheckingResult = m {
                stripTableRow(fixedStr.getPreMatch(start: &idx01, range: m.range), &headerIndex, &maxColumns, &columnWidths, &columnAligns, &table)
            }
        }

        if idx01 < fixedStr.count { stripTableRow(fixedStr.substr(from: idx01), &headerIndex, &maxColumns, &columnWidths, &columnAligns, &table) }
        return dumpTable(prefix, table, headerIndex, columnWidths, columnAligns)
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - prefix:
    ///   - indent:
    ///   - para:
    /// - Returns:
    ///
    func processParagraph(prefix: String, indent: String = "", paragraph para: String) -> String {
        let cleansed: String = doSimpleOnes(string: para)

        if (prefix.count + cleansed.count) <= maxLineLength {
            return prefix + cleansed + CR
        }
        else {
            var index: Int    = 0
            var outs:  String = ""
            var line:  String = ""
            let maxln: Int    = (maxLineLength - prefix.count)
            let ic:    Int    = adjustIndent(indent: indent, para: cleansed)
            let pfx:   String = prefix.padding(toLength: (prefix.count + ic))

            rx3.enumerateMatches(in: cleansed) {
                (m: NSTextCheckingResult?, _, _) in
                if let m: NSTextCheckingResult = m {
                    foo02((outs.isEmpty ? prefix : pfx), cleansed.getPreMatch(start: &index, range: m.range), ic, maxln, &line, &outs)
                }
            }

            let word: String = cleansed.substr(from: index)

            if !(line.isEmpty && word.isEmpty) {
                foo02(pfx, word, ic, maxln, &line, &outs)
                if !line.isEmpty { outs += pfx + line + CR }
            }

            return outs
        }
    }

    //==========================================================================================================================================
    //    Range #0: `/// - Document: `PGDOMDocument``
    //    Range #1: `/// `
    //    Range #2: `- Document: `PGDOMDocument``
    //    Range #3: `- `
    //    Range #4: `-`
    //    Range #5: `Document: `PGDOMDocument``
    //==========================================================================================================================================
    ///
    /// - Parameter block:
    /// - Returns:
    ///
    func processBlock(block: String) -> String {
        var paragraph:   String = ""
        var prefix:      String = ""
        var indent:      String = ""
        var output:      String = ""
        var inTable:     Bool   = false
        var inHTMLTable: Bool   = false
        var startup:     Bool   = true

        rx2.enumerateMatches(in: block) {
            (m: NSTextCheckingResult?, _, _) in

            if let m: NSTextCheckingResult = m {
                let s1: String = m.getSub(string: block, at: 1)
                let s2: String = m.getSub(string: block, at: 2)
                let s3: String = m.getSub(string: block, at: 3)
                let s4: String = m.getSub(string: block, at: 4)
                let s5: String = m.getSub(string: block, at: 5)

                if inTable {
                    if s4 == "|" {
                        paragraph += CR + s5
                    }
                    else {
                        output += processTable(prefix: prefix, table: paragraph)
                        prefix = s1
                        indent = s3
                        paragraph = s2
                        inTable = false
                    }
                }
                else if inHTMLTable {
                    if s2.hasSuffix("</table>") {
                        output += processHTMLTable(prefix: prefix, table: paragraph)
                        inHTMLTable = false
                        paragraph = ""
                        indent = ""
                        prefix = ""
                        startup = true
                    }
                    else {
                        paragraph += " " + s2
                    }
                }
                else if s2.hasPrefix("<table") {
                    if startup { startup = false }
                    else { output += processParagraph(prefix: prefix, indent: indent, paragraph: paragraph) }
                    prefix = s1
                    indent = s3
                    paragraph = s2
                    inHTMLTable = true
                }
                else if s4 == "-" || s4 == "+" || s4 == "*" { // The start of a new paragraph
                    if startup { startup = false }
                    else { output += processParagraph(prefix: prefix, indent: indent, paragraph: paragraph) }
                    prefix = s1
                    indent = s3
                    paragraph = s2
                }
                else if s4 == "|" { // The start of a new table
                    if startup { startup = false }
                    else { output += processParagraph(prefix: prefix, indent: indent, paragraph: paragraph) }
                    prefix = s1
                    indent = s3
                    paragraph = s5
                    inTable = true
                }
                else if startup { // The continuation of the current paragraph
                    prefix = s1
                    indent = s3
                    paragraph = s2
                    startup = false
                }
                else {
                    paragraph += (SPC + s2)
                }
            }
        }

        if paragraph.count > 0 && !startup {
            if inTable {
                output += processTable(prefix: prefix, table: paragraph)
            }
            else if inHTMLTable {
                output += processHTMLTable(prefix: prefix, table: paragraph)
            }
            else {
                output += processParagraph(prefix: prefix, indent: indent, paragraph: paragraph)
            }
        }

        return output
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameter str:
    /// - Returns:
    ///
    func doSimpleOnes(string str: String) -> String {
        rxFinal.stringByReplacingMatches(in: doSimpleOnes(string: doSimpleOnes(string: str, findReplace: findReplace), findReplace: NORMAL_FIND_REPLACE), withTemplate: "`")
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - str:
    ///   - findReplace:
    /// - Returns:
    ///
    func doSimpleOnes(string str: String, findReplace: [RegexRepl]) -> String {
        var s: String = str
        for rpl: RegexRepl in findReplace {
            s = rpl.regex.stringByReplacingMatches(in: s, withTemplate: rpl.repl)
        }
        return s
    }

    //==========================================================================================================================================
    ///
    ///
    /// - Parameter filename:
    ///
    func processDocument(filename: String) throws -> String {
        do {
            var indx: Int    = 0
            var outs: String = ""
            let data: String = try String(contentsOfFile: filename, encoding: String.Encoding.utf8)

            rx1.enumerateMatches(in: data) {
                (m: NSTextCheckingResult?, _, _) in
                if let m: NSTextCheckingResult = m {
                    let range: NSRange = m.range
                    outs += data.getPreMatch(start: &indx, range: range)
                    outs += processBlock(block: data.substr(range: range))
                }
            }

            return outs + data.substr(from: indx)
        }
        catch {
            throw DocFixerErrors.FileNotFound(description: "The file could not be found: \(filename)")
        }
    }
}

//==========================================================================================================================================
///
///
/// - Parameters:
///   - filenames: the filenames of the source code files to process.
///   - findsAndReplacements: any extra matches and replacements to use.
///   - lineLength: the max line length used for word wrapping.
///
/// - Returns: The processed files in the same order that their filenames were given.
/// - Throws: `DocFixerErrors.FileNotFound(description:)` if the file was not found or could not be loaded.
///
public func processDocument(filenames: [String], findsAndReplacements: [RegexRepl] = [], lineLength: Int = 132) throws -> [String] {
    let docFixer: PGDocFixer = PGDocFixer(findAndReplace: findsAndReplacements, lineLength: lineLength)
    var output:   [String]   = []

    for filename: String in filenames {
        output.append(try docFixer.processDocument(filename: filename))
    }

    return output
}

//==========================================================================================================================================
///
///
/// - Parameters:
///   - filename: the filename of the source code file to process.
///   - findsAndReplacements: any extra matches and replacements to use.
///   - lineLength: the max line length used for word wrapping.
///
/// - Returns: The processed file.
/// - Throws: `DocFixerErrors.FileNotFound(description:)` if the file was not found or could not be loaded.
///
public func processDocument(filename: String, findsAndReplacements: [RegexRepl] = [], lineLength: Int = 132) throws -> String {
    try processDocument(filenames: [filename], findsAndReplacements: findsAndReplacements, lineLength: lineLength)[0]
}
