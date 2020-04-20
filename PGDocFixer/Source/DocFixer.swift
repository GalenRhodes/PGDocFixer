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

//=================================================================================================================================
///
///
final public class LogDestination: TextOutputStream {

    //=============================================================================================================================
    ///
    ///
    /// - Parameter string:
    ///
    public func write(_ string: String) {
        if let data: Data = string.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}

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

    //=============================================================================================================================
    /// Code blocks can extend across several blocks so we need to
    /// let the code that only knows about a single block know that
    /// it is in the middle of a possibly larger code block. This
    /// field holds a flag to do just that. 'true' means we're in
    /// the middle of a code block and 'false' means we aren't.
    ///
    var blockType:              BlockType = .Normal

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - findAndReplace:
    ///   - lineLength:
    ///
    init(findAndReplace: [RegexRepl], lineLength: Int = 132) {
        self.maxLineLength = lineLength
        self.twoThirdsMaxLineLength = ((lineLength * 2) / 3)
        self.findReplace = findAndReplace
        self.tablesAsMarkdown = false
    }

    //=============================================================================================================================
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

    //=============================================================================================================================
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

    //=============================================================================================================================
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

    //=============================================================================================================================
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

    //=============================================================================================================================
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

    //=============================================================================================================================
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

    //=============================================================================================================================
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

    //=============================================================================================================================
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

    //=============================================================================================================================
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

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - prefix:
    ///   - tabstr:
    /// - Returns:
    ///
    func processHTMLTable(workers q: Workers) -> String {
        if let elem: HTMLElement = scanHTML(string: q.paragraph) {
            if elem.name == "table" {
                var table:        [[String]]  = []
                var headerIndex:  Int         = -1
                var columnWidths: [Int]       = []
                var columnAligns: [Alignment] = []

                for e: HTMLElement in elem.children {
                    processHTMLSub(e, &table, &headerIndex, &columnWidths, &columnAligns)
                }

                return dumpTable(q.prefix, table, headerIndex, columnWidths, columnAligns)
            }
        }

        return q.prefix + q.paragraph
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - prefix:
    ///   - dlStr:
    /// - Returns:
    ///
    func processDL(workers q: Workers) -> String {
        if let elem: HTMLElement = scanHTML(string: q.paragraph) {
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

                var outs: String = "\(q.prefix)<dl>\n"
                for i: DLItem in l { outs += i.getHTML(prefix: q.prefix, lineLength: maxLineLength) }
                return outs + "\(q.prefix)</dl>\n"
            }
        }

        return q.prefix + q.paragraph
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - prefix:
    ///   - tabstr:
    /// - Returns:
    ///
    func processTable(workers q: Workers) -> String {
        var table:        [[String]]  = []
        var idx01:        Int         = 0
        var maxColumns:   Int         = 0
        var headerIndex:  Int         = -1
        var columnWidths: [Int]       = []
        var columnAligns: [Alignment] = []
        let fixedStr:     String      = doSimpleOnes(string: q.paragraph)

        rx7.enumerateMatches(in: fixedStr) {
            (m: NSTextCheckingResult?, _, _) in
            if let m: NSTextCheckingResult = m {
                stripTableRow(fixedStr.getPreMatch(start: &idx01, range: m.range), &headerIndex, &maxColumns, &columnWidths, &columnAligns, &table)
            }
        }

        if idx01 < fixedStr.count { stripTableRow(fixedStr.substr(from: idx01), &headerIndex, &maxColumns, &columnWidths, &columnAligns, &table) }
        return dumpTable(q.prefix, table, headerIndex, columnWidths, columnAligns)
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - prefix:
    ///   - indent:
    ///   - para:
    /// - Returns:
    ///
    func processParagraph(workers q: Workers) -> String {
        let cleansed: String = doSimpleOnes(string: q.paragraph)

        if (q.prefix.count + cleansed.count) <= maxLineLength {
            return q.prefix + cleansed + CR
        }
        else {
            let pfx: String = q.prefix.padding(toLength: (q.prefix.count + adjustIndent(indent: q.indent, para: cleansed)))
            return WordWrap(prefix1: q.prefix, prefix2: pfx, lineLength: maxLineLength).wrap(str: cleansed) + CR
        }
    }

    //=============================================================================================================================
    ///
    ///
    /// - Normal:
    /// - MarkDownTable:
    /// - HTMLTable:
    /// - DefList:
    /// - CodeBlock:
    /// - Preformatted:
    ///
    enum BlockType {
        case Normal
        case MarkDownTable
        case HTMLTable
        case DefList
        case CodeBlock
        case Preformatted
    }

    //=============================================================================================================================
    ///
    ///
    typealias BlockParts = (s0: String, s1: String, s2: String, s3: String, s4: String, s5: String)

    //=============================================================================================================================
    ///
    ///
    typealias Workers = (paragraph: String, prefix: String, indent: String, startup: Bool)

    //=============================================================================================================================
    //    Range #0: `/// - Document: `PGDOMDocument``
    //    Range #1: `/// `
    //    Range #2: `- Document: `PGDOMDocument``
    //    Range #3: `- `
    //    Range #4: `-`
    //    Range #5: `Document: `PGDOMDocument``
    //=============================================================================================================================
    ///
    /// - Parameter block:
    /// - Returns:
    ///
    func processBlock(block: String) -> String {
        var q:      Workers = (paragraph: "", prefix: "", indent: "", startup: (blockType == .Normal))
        var output: String  = ""
        rx2.enumerateMatches(in: block) { (m: NSTextCheckingResult?, _, _) in if let m: NSTextCheckingResult = m { output += handleRawBlock(workers: &q,
                                                                                                                                            blockParts: getBlockParts(match: m, block: block)) } }
        output += closeFile(workers: q)
        return output
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - q:
    ///   - s:
    /// - Returns:
    ///
    func handleRawBlock(workers q: inout Workers, blockParts s: BlockParts) -> String {
        //@f:0
        switch blockType {
            case .MarkDownTable: return handleMarkDownTableBlock(workers: &q, blockParts: s)
            case .HTMLTable:     return handleHTMLTableBlock(workers: &q, blockParts: s)
            case .DefList:       return handleDefListBlock(workers: &q, blockParts: s)
            case .CodeBlock:     return handleCodeBlock(workers: &q, blockParts: s)
            case .Preformatted:  return handlePreformattedBlock(workers: &q, blockParts: s)
            default:             return handleNormal(blockParts: s, workers: &q)
        }
        //@f:1
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - q:
    ///   - s:
    /// - Returns:
    ///
    func handleMarkDownTableBlock(workers q: inout Workers, blockParts s: BlockParts) -> String {
        var output: String = ""
        if s.s4 == "|" {
            q.paragraph += CR + s.s5
        }
        else {
            output = processTable(workers: q)
            resetBlock(workers: &q, startup: q.startup, paragraph: s.s2, indent: s.s3, prefix: s.s1)
        }
        return output
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - q:
    ///   - s:
    /// - Returns:
    ///
    func handleHTMLTableBlock(workers q: inout Workers, blockParts s: BlockParts) -> String {
        var output: String = ""
        if s.s2.hasSuffix("</table>") {
            output = processHTMLTable(workers: q)
            resetBlock(workers: &q)
        }
        else {
            q.paragraph += " " + s.s2
        }
        return output
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - q:
    ///   - s:
    /// - Returns:
    ///
    func handleDefListBlock(workers q: inout Workers, blockParts s: BlockParts) -> String {
        var output: String = ""
        if s.s2.hasSuffix("</dl>") {
            output = processDL(workers: q)
            resetBlock(workers: &q)
        }
        else {
            q.paragraph += " " + s.s2
        }
        return output
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - q:
    ///   - s:
    /// - Returns:
    ///
    func handleCodeBlock(workers q: inout Workers, blockParts s: BlockParts) -> String {
        var output: String = ""
        if s.s2 == "```" || s.s2 == "~~~" {
            output = q.paragraph + s.s0
            resetBlock(workers: &q)
        }
        else {
            q.paragraph += s.s0
        }
        return output
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - q:
    ///   - s:
    /// - Returns:
    ///
    func handlePreformattedBlock(workers q: inout Workers, blockParts s: BlockParts) -> String {
        var output: String = ""
        if s.s2.hasSuffix("</pre>") {
            output = q.paragraph + s.s0
            resetBlock(workers: &q)
        }
        else {
            q.paragraph += s.s0
        }
        return output
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - m:
    ///   - block:
    /// - Returns:
    ///
    func getBlockParts(match m: NSTextCheckingResult, block: String) -> BlockParts {
        (s0: m.getSub(string: block, at: 0),
         s1: m.getSub(string: block, at: 1),
         s2: m.getSub(string: block, at: 2),
         s3: m.getSub(string: block, at: 3),
         s4: m.getSub(string: block, at: 4),
         s5: m.getSub(string: block, at: 5))
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - s:
    ///   - q:
    /// - Returns:
    ///
    private func handleNormal(blockParts s: BlockParts, workers q: inout Workers) -> String {
        //@f:0
        if s.s2.hasPrefix("<pre")                         { return closeParagraph(workers: &q, paragraph: s.s0, blockType: .Preformatted)                              }
        else if s.s2 == "~~~" || s.s2 == "```"            { return closeParagraph(workers: &q, paragraph: s.s0, blockType: .CodeBlock)                                 }
        else if s.s2.hasPrefix("<dl")                     { return closeParagraph(workers: &q, paragraph: s.s2, indent: s.s3, prefix: s.s1, blockType: .DefList)       }
        else if s.s2.hasPrefix("<table")                  { return closeParagraph(workers: &q, paragraph: s.s2, indent: s.s3, prefix: s.s1, blockType: .HTMLTable)     }
        else if s.s4 == "|"                               { return closeParagraph(workers: &q, paragraph: s.s5, indent: s.s3, prefix: s.s1, blockType: .MarkDownTable) }
        else if s.s4 == "-" || s.s4 == "+" || s.s4 == "*" { return closeParagraph(workers: &q, paragraph: s.s2, indent: s.s3, prefix: s.s1, blockType: .Normal)        }
        else if q.startup                                 { q = (prefix: s.s1, indent: s.s3, paragraph: s.s2, startup: false)                                          }
        else                                              { q.paragraph += (SPC + s.s2)                                                                                }
        //@f:1
        blockType = .Normal
        return ""
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameter q:
    /// - Returns:
    ///
    private func closeFile(workers q: Workers) -> String {
        var outs: String = ""

        if q.paragraph.count > 0 && !q.startup {
            //@f:0
            switch blockType {
                case .MarkDownTable:            outs = processTable(workers: q)
                case .HTMLTable:                outs = processHTMLTable(workers: q)
                case .DefList:                  outs = processDL(workers: q)
                case .CodeBlock, .Preformatted: outs = q.paragraph
                default:                        outs = processParagraph(workers: q)
            }
            //@f:1
        }

        blockType = .Normal
        return outs
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - q:
    ///   - paragraph:
    ///   - indent:
    ///   - prefix:
    ///   - btype:
    /// - Returns:
    ///
    private func closeParagraph(workers q: inout Workers, paragraph: String = "", indent: String = "", prefix: String = "", blockType btype: BlockType) -> String {
        var outs: String = ""

        if q.startup {
            q.startup = false
        }
        else {
            outs = processParagraph(workers: q)
        }

        blockType = btype
        q.paragraph = paragraph
        q.indent = indent
        q.prefix = prefix

        return outs
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameters:
    ///   - q:
    ///   - startup:
    ///   - paragraph:
    ///   - indent:
    ///   - prefix:
    ///
    private func resetBlock(workers q: inout Workers, startup: Bool = true, paragraph: String = "", indent: String = "", prefix: String = "") {
        blockType = .Normal
        q.paragraph = paragraph
        q.indent = indent
        q.prefix = prefix
        q.startup = startup
    }

    //=============================================================================================================================
    ///
    ///
    /// - Parameter str:
    /// - Returns:
    ///
    func doSimpleOnes(string str: String) -> String {
        rxFinal.stringByReplacingMatches(in: doSimpleOnes(string: doSimpleOnes(string: str, findReplace: findReplace), findReplace: NORMAL_FIND_REPLACE), withTemplate: "`")
    }

    //=============================================================================================================================
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

    //=============================================================================================================================
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
                    let r: NSRange = m.range
                    outs += data.getPreMatch(start: &indx, range: r) + processBlock(block: data.substr(range: r))
                }
            }

            return outs + data.substr(from: indx)
        }
        catch {
            throw DocFixerErrors.FileNotFound(description: "The file could not be found: \(filename)")
        }
    }
}
