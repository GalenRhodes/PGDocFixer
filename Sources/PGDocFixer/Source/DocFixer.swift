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

/*===============================================================================================================================*/
///
///
class ParagraphInfo {
    var paragraph: String
    var prefix:    String
    var indent:    String
    var startup:   Bool

    init(paragraph: String, prefix: String, indent: String, startup: Bool) {
        self.paragraph = paragraph
        self.prefix = prefix
        self.indent = indent
        self.startup = startup
    }
}

/*===============================================================================================================================*/
/// The main guy.
///
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
    let docOutput:              CommentDocType

    /*===========================================================================================================================*/
    /// <code> and <pre> sections can extend across several blocks so we need to let the code that only knows about a single block
    /// know that it is in the middle of a possibly larger multi-block section. This field holds a flag to do just that by holding
    /// the type of section we're in.
    ///
    var paraType:               ParagraphType = .Normal

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - findAndReplace:
    ///   - lineLength:
    ///
    init(findAndReplace: [RegexRepl], tablesAsMarkdown: Bool = false, docOutput: CommentDocType = .Slashes, lineLength: Int = 132) {
        self.maxLineLength = lineLength
        self.twoThirdsMaxLineLength = ((lineLength * 2) / 3)
        self.findReplace = findAndReplace
        self.tablesAsMarkdown = tablesAsMarkdown
        self.docOutput = docOutput
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - indent:
    ///   - paragraph:
    /// - Returns:
    ///
    func adjustIndent(indent: String, paragraph: String) -> Int {
        if let m: NSTextCheckingResult = rx4.firstMatch(in: paragraph) {
            let ic: Int = paragraph.substr(nsRange: m.range).count
            return ((ic >= maxLineLength) ? indent.count : (ic >= twoThirdsMaxLineLength ? indent.count + 4 : ic))
        }
        return indent.count
    }

    /*===========================================================================================================================*/
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

    /*===========================================================================================================================*/
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

    /*===========================================================================================================================*/
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

    /*===========================================================================================================================*/
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

    /*===========================================================================================================================*/
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

    /*===========================================================================================================================*/
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

    /*===========================================================================================================================*/
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

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - elem:
    ///   - table:
    ///   - headerIndex:
    ///   - columnWidths:
    ///   - columnAligns:
    ///
    func parseHTMLTree(_ elem: HTMLElement, _ table: inout [[String]], _ headerIndex: inout Int, _ columnWidths: inout [Int], _ columnAligns: inout [Alignment]) {
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
                parseHTMLTree(e, &table, &headerIndex, &columnWidths, &columnAligns)
            }
        }
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - elem:
    ///   - prefix:
    /// - Returns:
    ///
    func renderHTMLTable2(elem: HTMLElement, prefix: String) -> String {
        var table:        [[String]]  = []
        var headerIndex:  Int         = -1
        var columnWidths: [Int]       = []
        var columnAligns: [Alignment] = []

        for e: HTMLElement in elem.children {
            parseHTMLTree(e, &table, &headerIndex, &columnWidths, &columnAligns)
        }

        return dumpTable(prefix, table, headerIndex, columnWidths, columnAligns)
    }

    /*===========================================================================================================================*/
    /// - Parameter info:
    /// - Returns:
    ///
    func renderHTMLTable(paragraphInfo info: ParagraphInfo) -> String {
        let pfx:  String = info.prefix
        let para: String = info.paragraph

        if let elem: HTMLElement = scanHTML(string: para), elem.name == "table" {
            return renderHTMLTable2(elem: elem, prefix: pfx)
        }
        else {
            return pfx + para
        }
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - elem:
    ///   - prefix:
    /// - Returns:
    ///
    func renderHTMLElement(elem: HTMLElement, prefix: String) -> String {
        var o: String   = "\(prefix)<\(elem.name)>"
        var x: String   = ""
        let p: String   = "\(prefix)    "
        let w: WordWrap = WordWrap(prefix1: "", prefix2: p, lineLength: maxLineLength)

        for child: HTMLElement in elem.children {
            switch child.name {
                case "dl":
                    o += ("\(w.wrap(str: x))\n\(renderDefList2(elem: child, prefix: p))\(prefix)")
                    x = ""
                case "ol", "ul":
                    o += ("\(w.wrap(str: x))\n\(renderList2(elem: child, prefix: p))\(prefix)")
                    x = ""
                case "table":
                    o += ("\(w.wrap(str: x))\n\(renderHTMLTable2(elem: child, prefix: p))\(prefix)")
                    x = ""
                default:
                    if child.isBlock {
                        if x.count > 0 { o += w.wrap(str: x) }
                        o += "\n\(renderHTMLElement(elem: child, prefix: p))\(prefix)"
                        x = ""
                    }
                    else {
                        x += child.html
                    }
            }
        }

        if x.count > 0 { o += w.wrap(str: x) }
        return "\(o)</\(elem.name)>\n"
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - elem:
    ///   - prefix:
    /// - Returns:
    ///
    func renderList2(elem: HTMLElement, prefix: String) -> String {
        var o: String = "\(prefix)<\(elem.name)>\n"

        for child: HTMLElement in elem.children {
            if child.name == "li" {
                o += renderHTMLElement(elem: child, prefix: prefix + "    ")
            }
        }

        return "\(o)\(prefix)</\(elem.name)>\n"
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - info:
    ///   - tagName:
    /// - Returns:
    ///
    func renderList(paragraphInfo info: ParagraphInfo, tagName: String) -> String {
        if let elem: HTMLElement = scanHTML(string: info.paragraph), elem.name == tagName {
            return renderList2(elem: elem, prefix: info.prefix + info.indent)
        }
        else {
            return info.prefix + info.indent + info.paragraph
        }
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - elem:
    ///   - pfx:
    /// - Returns:
    ///
    func renderDefList2(elem: HTMLElement, prefix: String) -> String {
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

        var outs: String = ""
        for i: DLItem in l { outs += i.getHTML(prefix: prefix, lineLength: maxLineLength) }
        return "\(prefix)<dl>\n\(outs)\(prefix)</dl>\n"
    }

    /*===========================================================================================================================*/
    /// - Parameter info:
    /// - Returns:
    ///
    func renderDefList(paragraphInfo info: ParagraphInfo) -> String {
        if let elem: HTMLElement = scanHTML(string: info.paragraph), elem.name == "dl" { return renderDefList2(elem: elem, prefix: info.prefix) }
        else { return info.prefix + info.paragraph }
    }

    /*===========================================================================================================================*/
    /// - Parameter info:
    /// - Returns:
    ///
    func renderTable(paragraphInfo info: ParagraphInfo) -> String {
        var table:        [[String]]  = []
        var idx01:        Int         = 0
        var maxColumns:   Int         = 0
        var headerIndex:  Int         = -1
        var columnWidths: [Int]       = []
        var columnAligns: [Alignment] = []
        let fixedStr:     String      = doSimpleOnes(string: info.paragraph)

        rx7.enumerateMatches(in: fixedStr) {
            (m: NSTextCheckingResult?, _, _) in
            if let m: NSTextCheckingResult = m {
                stripTableRow(fixedStr.getPreMatch(start: &idx01, range: m.range), &headerIndex, &maxColumns, &columnWidths, &columnAligns, &table)
            }
        }

        if idx01 < fixedStr.count { stripTableRow(fixedStr.substr(from: idx01), &headerIndex, &maxColumns, &columnWidths, &columnAligns, &table) }
        return dumpTable(info.prefix, table, headerIndex, columnWidths, columnAligns)
    }

    /*===========================================================================================================================*/
    /// - Parameter info:
    /// - Returns:
    ///
    func renderParagraph(paragraphInfo info: ParagraphInfo) -> String {
        let cleansed: String = doSimpleOnes(string: info.paragraph)

        if (info.prefix.count + cleansed.count) <= maxLineLength {
            return info.prefix + cleansed + CR
        }
        else {
            let pfx: String = info.prefix.padding(toLength: (info.prefix.count + adjustIndent(indent: info.indent, paragraph: cleansed)))
            return WordWrap(prefix1: info.prefix, prefix2: pfx, lineLength: maxLineLength).wrap(str: cleansed) + CR
        }
    }

    /*===========================================================================================================================*/
    ///    Range #0: `/// - Document: `PGDOMDocument``
    ///    Range #1: `/// `
    ///    Range #2: `- Document: `PGDOMDocument``
    ///    Range #3: `- `
    ///    Range #4: `-`
    ///    Range #5: `Document: `PGDOMDocument``
    ///
    /// - Parameter block: the string block.
    /// - Returns: a string
    ///
    func processBlock(block: String) -> String {
        let info: ParagraphInfo = ParagraphInfo(paragraph: "", prefix: "", indent: "", startup: (self.paraType == .Normal))
        var o:    String        = ""

        rx2.enumerateMatches(in: block) {
            (m: NSTextCheckingResult?, _, _) in
            if let m: NSTextCheckingResult = m { o += handleRawBlock(paragraphInfo: info, line: LineParts(match: m, block: block)) }
        }

        return o + closeBlock(paragraphInfo: info)
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - info:
    ///   - s:
    ///
    /// - Returns:
    ///
    func handleRawBlock(paragraphInfo info: ParagraphInfo, line: LineParts) -> String {
        //@f:0
        switch self.paraType {
            case .MarkDownTable: return handleMarkDownTableBlock(paragraphInfo: info, line: line)
            case .HTMLTable:     return handleHTMLTableBlock(paragraphInfo: info, line: line)
            case .DefList:       return handleDefListBlock(paragraphInfo: info, line: line)
            case .CodeBlock:     return handleCodeBlock(paragraphInfo: info, line: line)
            case .Preformatted:  return handlePreformattedBlock(paragraphInfo: info, line: line)
            case .OrderedList:   return handleListBlock(paragraphInfo: info, line: line, tagName: "ol")
            case .UnorderedList: return handleListBlock(paragraphInfo: info, line: line, tagName: "ul")
            default:             return handleNormal(paragraphInfo: info, line: line)
        }
        //@f:1
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - info:
    ///   - s:
    /// - Returns:
    ///
    func handleMarkDownTableBlock(paragraphInfo info: ParagraphInfo, line: LineParts) -> String {
        var o: String = ""

        if line.s4 == "|" {
            info.paragraph += CR + line.s5
        }
        else {
            o = renderTable(paragraphInfo: info)
            resetParagraph(paragraphInfo: info, startup: info.startup, paragraph: line.s2, indent: line.s3, prefix: line.s1)
        }

        return o
    }

    func handleListBlock(paragraphInfo info: ParagraphInfo, line: LineParts, tagName: String) -> String {
        var o: String = ""

        if line.s2.hasSuffix("</\(tagName)>") {
            o = renderList(paragraphInfo: info, tagName: tagName)
            resetParagraph(paragraphInfo: info)
        }
        else {
            info.paragraph += " " + line.s2
        }

        return o
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - info:
    ///   - s:
    /// - Returns:
    ///
    func handleHTMLTableBlock(paragraphInfo info: ParagraphInfo, line: LineParts) -> String {
        var o: String = ""

        if line.s2.hasSuffix("</table>") {
            o = renderHTMLTable(paragraphInfo: info)
            resetParagraph(paragraphInfo: info)
        }
        else {
            info.paragraph += " " + line.s2
        }

        return o
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - info:
    ///   - s:
    /// - Returns:
    ///
    func handleDefListBlock(paragraphInfo info: ParagraphInfo, line: LineParts) -> String {
        var o: String = ""

        if line.s2.hasSuffix("</dl>") {
            o = renderDefList(paragraphInfo: info)
            resetParagraph(paragraphInfo: info)
        }
        else {
            info.paragraph += " " + line.s2
        }

        return o
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - info:
    ///   - s:
    /// - Returns:
    ///
    func handleCodeBlock(paragraphInfo info: ParagraphInfo, line: LineParts) -> String {
        var o: String = ""

        if line.s2 == "```" || line.s2 == "~~~" {
            o = info.paragraph + line.s0
            resetParagraph(paragraphInfo: info)
        }
        else {
            info.paragraph += line.s0
        }

        return o
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - info:
    ///   - s:
    /// - Returns:
    ///
    func handlePreformattedBlock(paragraphInfo info: ParagraphInfo, line: LineParts) -> String {
        var o: String = ""

        if line.s2.hasSuffix("</pre>") {
            o = info.paragraph + line.s0
            resetParagraph(paragraphInfo: info)
        }
        else {
            info.paragraph += line.s0
        }

        return o
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - s:
    ///   - info:
    /// - Returns:
    ///
    private func handleNormal(paragraphInfo info: ParagraphInfo, line: LineParts) -> String {
        if line.s2.hasPrefix("<pre") {
            return closeParagraph(paragraphInfo: info, paragraph: line.s0, paraType: .Preformatted)
        }
        else if line.s2.hasPrefix("<ol") {
            return closeParagraph(paragraphInfo: info, paragraph: line.s2, prefix: line.s1, paraType: .OrderedList)
        }
        else if line.s2.hasPrefix("<ul") {
            return closeParagraph(paragraphInfo: info, paragraph: line.s2, prefix: line.s1, paraType: .UnorderedList)
        }
        else if line.s2 == "~~~" || line.s2 == "```" {
            return closeParagraph(paragraphInfo: info, paragraph: line.s0, paraType: .CodeBlock)
        }
        else if line.s2.hasPrefix("<dl") {
            return closeParagraph(paragraphInfo: info, paragraph: line.s2, indent: line.s3, prefix: line.s1, paraType: .DefList)
        }
        else if line.s2.hasPrefix("<table") {
            return closeParagraph(paragraphInfo: info, paragraph: line.s2, indent: line.s3, prefix: line.s1, paraType: .HTMLTable)
        }
        else if line.s4 == "|" {
            return closeParagraph(paragraphInfo: info, paragraph: line.s5, indent: line.s3, prefix: line.s1, paraType: .MarkDownTable)
        }
        else if line.s4 == "-" || line.s4 == "+" || line.s4 == "*" {
            return closeParagraph(paragraphInfo: info, paragraph: line.s2, indent: line.s3, prefix: line.s1, paraType: .Normal)
        }
        else if info.startup {
            resetParagraph(paragraphInfo: info, startup: false, paragraph: line.s2, indent: line.s3, prefix: line.s1)
        }
        else {
            info.paragraph += (SPC + line.s2)
        }
        return ""
    }

    /*===========================================================================================================================*/
    /// - Parameter info:
    /// - Returns:
    ///
    private func closeBlock(paragraphInfo info: ParagraphInfo) -> String {
        if info.paragraph.count > 0 && !info.startup {
            //@f:0
            switch self.paraType {
                case .CodeBlock, .Preformatted: return info.paragraph
                case .MarkDownTable:            return renderTable(paragraphInfo: info)
                case .HTMLTable:                return renderHTMLTable(paragraphInfo: info)
                case .DefList:                  return renderDefList(paragraphInfo: info)
                default:                        return renderParagraph(paragraphInfo: info)
            }
            //@f:1
        }
        return ""
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - info:
    ///   - paragraph:
    ///   - indent:
    ///   - prefix:
    ///   - btype:
    /// - Returns:
    ///
    private func closeParagraph(paragraphInfo info: ParagraphInfo, paragraph: String = "", indent: String = "", prefix: String = "", paraType: ParagraphType) -> String {
        var o: String = ""
        if !info.startup { o = renderParagraph(paragraphInfo: info) }
        resetParagraph(paragraphInfo: info, startup: false, paragraph: paragraph, indent: indent, prefix: prefix, paraType: paraType)
        return o
    }

    /*===========================================================================================================================*/
    /// - Parameters:
    ///   - info:
    ///   - startup:
    ///   - paragraph:
    ///   - indent:
    ///   - prefix:
    ///
    private func resetParagraph(paragraphInfo info: ParagraphInfo, startup: Bool = true, paragraph: String = "", indent: String = "", prefix: String = "", paraType: ParagraphType = .Normal) {
        self.paraType = paraType
        info.paragraph = paragraph
        info.prefix = prefix
        info.indent = indent
        info.startup = startup
    }

    /*===========================================================================================================================*/
    /// - Parameter str:
    /// - Returns:
    ///
    func doSimpleOnes(string str: String) -> String {
        rxFinal.stringByReplacingMatches(in: doSimpleOnes(string: doSimpleOnes(string: str, findReplace: findReplace), findReplace: addUrlsToFindAndReplace()), withTemplate: "`")
    }

    /*===========================================================================================================================*/
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

    /*===========================================================================================================================*/
    /// - Parameter filename:
    ///
    func processDocument(filename: String) throws -> String {
        do {
            let rx:   NSRegularExpression = try! regexML(pattern: #"^([ \t]*)//\*{20,}\R"#)
            let data: String              = convertCommentBlocks(data: rx.stringByReplacingMatches(in: try String(contentsOfFile: filename, encoding: String.Encoding.utf8), withTemplate: ""))
            let outs: String              = processDocument(data: data)
            return (docOutput == .Slashes ? outs : restoreCommentBlocks(data: outs, empty: (docOutput == .StarsEmpty)))
        }
        catch {
            throw DocFixerErrors.FileNotFound(description: "The file could not be found: \(filename)")
        }
    }

    /*===========================================================================================================================*/
    /// - Parameter data:
    /// - Returns:
    ///
    func processDocument(data: String) -> String {
        var indx: Int    = 0
        var outs: String = ""

        rx1.enumerateMatches(in: data) {
            (m: NSTextCheckingResult?, _, _) in
            if let m: NSTextCheckingResult = m {
                let r: NSRange = m.range
                outs += data.getPreMatch(start: &indx, range: r) + processBlock(block: data.substr(nsRange: r))
            }
        }

        return outs + data.substr(from: indx)
    }

    //=============================================================================================================================
    private func convertCommentBlocks(data: String) -> String {
        var indx: Int                 = 0
        var outs: String              = ""
        let rx:   NSRegularExpression = try! regexML(pattern: #"^([ \t]*)(?:/\*={20,}\*/(?:\R[ \t]*)?)?/\*\*\R((.*\R)*?)\1 \*/\R"#)

        rx.enumerateMatches(in: data) {
            (m: NSTextCheckingResult?, _, _) in
            if let m: NSTextCheckingResult = m {
                let indent:  String = data.substr(nsRange: m.range(at: 1))
                let subData: String = data.substr(nsRange: m.range(at: 2))

                outs += data.getPreMatch(start: &indx, range: m.range) + "\(indent)///\n"
                outs += convertCommentBlocks01(indent: indent, blockString: subData)
                outs += "\(indent)///\n"
            }
        }

        return outs + data.substr(from: indx)
    }

    //=============================================================================================================================
    private func convertCommentBlocks01(indent: String, blockString str: String) -> String {
        var outs: String              = ""
        let rx:   NSRegularExpression = try! regexML(pattern: "^(?:\(indent)(?:   (.+)| \\* (.+)| \\*))?$")

        rx.enumerateMatches(in: str) {
            (m: NSTextCheckingResult?, _, _) in
            if let m: NSTextCheckingResult = m {
                let r1:    NSRange = m.range(at: 1)
                let r2:    NSRange = m.range(at: 2)
                let r1Bad: Bool    = (r1.location == NSNotFound)
                let r2Bad: Bool    = (r2.location == NSNotFound)
                let s:     String  = ((r1Bad && r2Bad) ? "" : str.substr(nsRange: (r1Bad ? r2 : r1)))

                outs += "\(indent)/// \(s)\n"
            }
        }

        return outs
    }

    //=============================================================================================================================
    private func restoreCommentBlocks(data: String, empty: Bool = false) -> String {
        var indx: Int                 = 0
        var outs: String              = ""
        let rxz:  NSRegularExpression = try! regexML(pattern: "^(([ \\t]*)///).*\\R(\\1.*\\R)*")

        rxz.enumerateMatches(in: data) {
            (m: NSTextCheckingResult?, _, _) in
            if let m: NSTextCheckingResult = m {
                let r: NSRange = m.range
                outs += data.getPreMatch(start: &indx, range: r)
                outs += restoreCommentBlocks01(indent: data.substr(nsRange: m.range(at: 2)), blockString: data.substr(nsRange: r), empty: empty)
            }
        }

        return outs + data.substr(from: indx)
    }

    //=============================================================================================================================
    private func restoreCommentBlocks01(indent: String, blockString str: String, empty: Bool = false) -> String {
        let rxy:       NSRegularExpression = try! regexML(pattern: "^([ \\t]*)///[ \\t]?(.*)")
        var doLeading: Bool                = true
        var skipNext:  Bool                = false
        var lastLine:  String              = ""
        var _outs:     String              = ""
        let zzTop:     String              = "\(indent)/*".padding(toLength: 127, withPad: "==========")

        _outs += "\(zzTop)*//**\n"

        rxy.enumerateMatches(in: str) {
            (m2: NSTextCheckingResult?, _, _) in
            if let m2: NSTextCheckingResult = m2 {
                let content: String = str.substr(nsRange: m2.range(at: 2))

                if doLeading {
                    doLeading = false
                    if content != "" {
                        lastLine = content
                    }
                    else {
                        skipNext = true
                    }
                }
                else {
                    if skipNext {
                        skipNext = false
                    }
                    else if lastLine == "" {
                        _outs += empty ? "\n" : "\(indent) *\n"
                    }
                    else {
                        _outs += empty ? "\(indent)   \(lastLine)\n" : "\(indent) * \(lastLine)\n"
                    }
                    lastLine = content
                }
            }
        }

        if lastLine != "" {
            _outs += "\(indent)   \(lastLine)\n"
        }
        return _outs + "\(indent) */\n"
    }
}
