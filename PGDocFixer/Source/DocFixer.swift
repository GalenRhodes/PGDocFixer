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

let CR:  String = "\n"
let SPC: String = " "

final public class LogDestination: TextOutputStream { public func write(_ string: String) { if let data: Data = string.data(using: .utf8) { FileHandle.standardError.write(data) } } }

public var errorLog: LogDestination = LogDestination()

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

public class PGDocFixer {
    static let rxLead: String = "^([ \\t]*///[ \\t]+)"
    static let rxLine: String = "\(rxLead)((([|+*-])[ \\t]?)?(.+?))[ \\t]*\\R"

    let rx1:     NSRegularExpression = try! regexML(pattern: "(\(rxLine))+")
    let rx2:     NSRegularExpression = try! regexML(pattern: rxLine)
    let rx3:     NSRegularExpression = try! regexML(pattern: "\\s+")
    let rx4:     NSRegularExpression = try! regexML(pattern: "^\\-[ \\t]*([^:]+:[ \\t]){1,2}")
    let rx5:     NSRegularExpression = try! regexML(pattern: "\\s*\\|\\s*")
    let rx7:     NSRegularExpression = try! regexML(pattern: "\\R")
    let rx8:     NSRegularExpression = try! regexML(pattern: "`([^`]+)`")
    let rxFinal: NSRegularExpression = try! regexML(pattern: "``")

    let maxLineLength:          Int
    let twoThirdsMaxLineLength: Int
    let tablesAsMarkdown:       Bool
    let findReplace:            [RegexRepl]

    ///
    /// Code blocks can extend across several blocks so we need to
    /// let the code that only knows about a single block know that
    /// it is in the middle of a possibly larger code block. This
    /// field holds a flag to do just that. 'true' means we're in
    /// the middle of a code block and 'false' means we aren't.
    ///
    var insideCodeBlock:        Bool = false

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
                    let s: String = doSimpleOnes(string: e1.innerHtml.trimmed)
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
    ///   - dlStr:
    /// - Returns:
    ///
    func processDL(prefix: String, dl dlStr: String) -> String {
        if let elem: HTMLElement = scanHTML(string: dlStr) {
            if elem.name == "dl" {
                var f: Bool     = true
                var t: String   = ""
                var d: String   = ""
                var l: [DLItem] = []

                for e: HTMLElement in elem.children {
                    if f {
                        if e.name == "dt" {
                            t = e.innerHtml
                            f = false
                        }
                    }
                    else {
                        if e.name == "dd" {
                            d = e.innerHtml
                            f = true
                            l.append(DLItem(dt: t, dd: d))
                            t = ""
                            d = ""
                        }
                    }
                }

                var outs: String = "\(prefix)<dl>\n"
                for i: DLItem in l { outs += i.getHTML(prefix: prefix, lineLength: maxLineLength) }
                return outs + "\(prefix)</dl>\n"
            }
        }

        return prefix + dlStr
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
            let pfx: String = prefix.padding(toLength: (prefix.count + adjustIndent(indent: indent, para: cleansed)))
            return WordWrap(prefix1: prefix, prefix2: pfx, lineLength: maxLineLength).wrap(str: cleansed) + CR
        }
    }

    enum BlockType {
        case Normal
        case MarkDownTable
        case HTMLTable
        case DefList
        case CodeBlock
        case Preformatted
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
        var paragraph: String    = ""
        var prefix:    String    = ""
        var indent:    String    = ""
        var output:    String    = ""
        var blockType: BlockType = insideCodeBlock ? .CodeBlock : .Normal
        var startup:   Bool      = !insideCodeBlock

        rx2.enumerateMatches(in: block) {
            (m: NSTextCheckingResult?, _, _) in

            if let m: NSTextCheckingResult = m {
                let s1: String = m.getSub(string: block, at: 1)
                let s2: String = m.getSub(string: block, at: 2)
                let s3: String = m.getSub(string: block, at: 3)
                let s4: String = m.getSub(string: block, at: 4)
                let s5: String = m.getSub(string: block, at: 5)

                switch blockType {
                    case .MarkDownTable:
                        if s4 == "|" {
                            paragraph += CR + s5
                        }
                        else {
                            output += processTable(prefix: prefix, table: paragraph)
                            prefix = s1
                            indent = s3
                            paragraph = s2
                            blockType = .Normal
                        }
                    case .HTMLTable:
                        if s2.hasSuffix("</table>") {
                            output += processHTMLTable(prefix: prefix, table: paragraph)
                            blockType = .Normal
                            paragraph = ""
                            indent = ""
                            prefix = ""
                            startup = true
                        }
                        else {
                            paragraph += " " + s2
                        }
                    case .DefList:
                        if s2.hasSuffix("</dl>") {
                            output += processDL(prefix: prefix, dl: paragraph)
                            blockType = .Normal
                            paragraph = ""
                            indent = ""
                            prefix = ""
                            startup = true
                        }
                        else {
                            paragraph += " " + s2
                        }
                    case .CodeBlock:
                        if s2 == "```" || s2 == "~~~" {
                            output += paragraph + m.getSub(string: block, at: 0)
                            blockType = .Normal
                            insideCodeBlock = false
                            paragraph = ""
                            indent = ""
                            prefix = ""
                            startup = true
                        }
                        else {
                            //----------------------------------------------------------------------------
                            // Code blocks just get passed through without any conversion or formatting.
                            //----------------------------------------------------------------------------
                            paragraph += m.getSub(string: block, at: 0)
                        }
                    case .Preformatted:
                        if s2.hasSuffix("</pre>") {
                            output += paragraph + m.getSub(string: block, at: 0)
                            blockType = .Normal
                            insideCodeBlock = false
                            paragraph = ""
                            indent = ""
                            prefix = ""
                            startup = true
                        }
                        else {
                            //----------------------------------------------------------------------------
                            // Preformatted blocks just get passed through without any conversion or
                            // formatting.
                            //----------------------------------------------------------------------------
                            paragraph += m.getSub(string: block, at: 0)
                        }
                    default:
                        if s2.hasPrefix("<pre") {
                            if startup { startup = false }
                            else { output += processParagraph(prefix: prefix, indent: indent, paragraph: paragraph) }
                            prefix = ""
                            indent = ""
                            //----------------------------------------------------------------------------
                            // Preformatted blocks just get passed through without any conversion or
                            // formatting.
                            //----------------------------------------------------------------------------
                            paragraph = m.getSub(string: block, at: 0)
                            blockType = .Preformatted
                            insideCodeBlock = true
                        }
                        else if s2.hasPrefix("<table") {
                            if startup { startup = false }
                            else { output += processParagraph(prefix: prefix, indent: indent, paragraph: paragraph) }
                            prefix = s1
                            indent = s3
                            paragraph = s2
                            blockType = .HTMLTable
                        }
                        else if s2.hasPrefix("<dl") {
                            if startup { startup = false }
                            else { output += processParagraph(prefix: prefix, indent: indent, paragraph: paragraph) }
                            prefix = s1
                            indent = s3
                            paragraph = s2
                            blockType = .DefList
                        }
                        else if s4 == "|" { // The start of a new table
                            if startup { startup = false }
                            else { output += processParagraph(prefix: prefix, indent: indent, paragraph: paragraph) }
                            prefix = s1
                            indent = s3
                            paragraph = s5
                            blockType = .MarkDownTable
                        }
                        else if s2 == "~~~" || s2 == "```" {
                            if startup { startup = false }
                            else { output += processParagraph(prefix: prefix, indent: indent, paragraph: paragraph) }
                            prefix = ""
                            indent = ""
                            //----------------------------------------------------------------------------
                            // Code blocks just get passed through without any conversion or formatting.
                            //----------------------------------------------------------------------------
                            paragraph = m.getSub(string: block, at: 0)
                            blockType = .CodeBlock
                            insideCodeBlock = true
                        }
                        else if s4 == "-" || s4 == "+" || s4 == "*" { // The start of a new paragraph
                            if startup { startup = false }
                            else { output += processParagraph(prefix: prefix, indent: indent, paragraph: paragraph) }
                            prefix = s1
                            indent = s3
                            paragraph = s2
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
        }

        if paragraph.count > 0 && !startup {
            switch blockType {
                case .MarkDownTable:
                    output += processTable(prefix: prefix, table: paragraph)
                case .HTMLTable:
                    output += processHTMLTable(prefix: prefix, table: paragraph)
                case .DefList:
                    output += processDL(prefix: prefix, dl: paragraph)
                case .CodeBlock:
                    output += paragraph
                default:
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
