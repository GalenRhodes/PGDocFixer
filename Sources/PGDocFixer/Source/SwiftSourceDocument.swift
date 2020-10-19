/************************************************************************//**
 *     PROJECT: PGDocFixer
 *    FILENAME: SwiftSourceDocument.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/28/20
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

typealias SwiftSourceDocumentList = [SwiftSourceDocument]

internal class SwiftSourceDocument {
    private static let rx01: NSRegularExpression = try! regexML(pattern: #"^([ \t]*)(?:/\*={20,}\*/(?:\R[ \t]*)?)?/\*\*\R((.*\R)*?)\1 \*/\R"#)
    private static let rx02: NSRegularExpression = try! regexML(pattern: "^(([ \\t]*)///).*\\R(\\1.*\\R)*")
    private static let rx03: NSRegularExpression = try! regexML(pattern: #"^[ \t]*/\*={10,}\*/\R"#)
    private static let rx04: NSRegularExpression = try! regexML(pattern: #"^([ \t]*)/\*={10,}\*/(/\*)"#)

    var source:   String
    let filename: String
    let encoding: String.Encoding

    init(source: String, filename: String, encoding: String.Encoding = String.Encoding.utf8) {
        self.source = source
        self.filename = filename
        self.encoding = encoding
    }

    convenience init(filename: String, encoding: String.Encoding = String.Encoding.utf8) throws {
        do { self.init(source: try String(contentsOfFile: filename, encoding: encoding), filename: filename) }
        catch let e { throw DocFixerErrors.FailedLoad(description: "\(e)") }
    }

    func reload() throws {
        do { source = try String(contentsOfFile: filename, encoding: encoding) }
        catch let e { throw DocFixerErrors.FailedLoad(description: "\(e)") }
    }

    func save() throws {
        do { try source.write(toFile: filename, atomically: true, encoding: encoding) }
        catch let e { throw DocFixerErrors.FailedSave(description: "\(e)") }
    }

    func fixDocComments(fixer: PGDocFixer) {
        convertCommentDocs(to: .Slashes, lineLength: fixer.maxLineLength)
        source = fixer.processDocument(data: source)
    }

    private func acdc(str: String) -> String {
        var outs: String = ""
        var idx:  Int    = 0

        SwiftSourceDocument.rx03.enumerateMatches(in: str) {
            (m: NSTextCheckingResult?, _, _) in
            if let m: NSTextCheckingResult = m {
                outs += str.getPreMatch(start: &idx, range: m.range)
            }
        }
        outs += str.substr(from: idx)
        return outs
    }

    private func scorpions(str: String) -> String {
        var outs: String = ""
        var idx:  Int    = 0

        SwiftSourceDocument.rx04.enumerateMatches(in: str) {
            (m: NSTextCheckingResult?, _, _) in
            if let m: NSTextCheckingResult = m {
                let p1: String = str.getPreMatch(start: &idx, range: m.range)
                let p2: String = str.substr(nsRange: m.range(at: 1))
                let p3: String = str.substr(nsRange: m.range(at: 2))

                outs += p1
                outs += p2
                outs += p3
            }
        }
        outs += str.substr(from: idx)
        return outs
    }

    func convertCommentDocs(to commentDocType: CommentDocType = .Slashes, lineLength: Int = 132) {
        // This all might seem redundant but converting to the opposite before converting it
        // to the format we want causes a normalization to occur so that we get the right effect.
        source = acdc(str: source)
        source = scorpions(str: source)

        switch commentDocType {
            case .Slashes:
                convertCommentDocsToStars(empty: false, lineLength: lineLength)
                convertCommentDocsToSlashes(lineLength: lineLength)
            case .Stars:
                convertCommentDocsToSlashes(lineLength: lineLength)
                convertCommentDocsToStars(empty: false, lineLength: lineLength)
            case .StarsEmpty:
                convertCommentDocsToSlashes(lineLength: lineLength)
                convertCommentDocsToStars(empty: true, lineLength: lineLength)
        }
    }

    private func convertCommentDocsToSlashes(lineLength: Int = 132) {
        var indx: Int    = 0
        var outs: String = ""

        SwiftSourceDocument.rx01.enumerateMatches(in: source) {
            (m: NSTextCheckingResult?, _, _) in
            if let m: NSTextCheckingResult = m {
                let indent:  String = source.substr(nsRange: m.range(at: 1))
                let subData: String = source.substr(nsRange: m.range(at: 2))

                outs += (source.getPreMatch(start: &indx, range: m.range) + (("\(indent)/*".padding(toLength: lineLength - 3, withPad: "==========")) + "*/\n"))
                outs += convertCommentDocsToSlashes01(indent: indent, blockString: subData, lineLength: lineLength)
                outs += "\(indent)///\n"
            }
        }

        source = ((outs + source.substr(from: indx)).trimmed + "\n")
    }

    private func convertCommentDocsToSlashes01(indent: String, blockString str: String, lineLength: Int = 132) -> String {
        let rx:   NSRegularExpression = try! regexML(pattern: "^(?:\(indent)(?:   (.+)| \\* (.+)| \\*))?$")
        var outs: String              = ""

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

    private func convertCommentDocsToStars(empty: Bool = false, lineLength: Int = 132) {
        var indx: Int    = 0
        var outs: String = ""

        SwiftSourceDocument.rx02.enumerateMatches(in: source) {
            (m: NSTextCheckingResult?, _, _) in
            if let m: NSTextCheckingResult = m {
                let r:      NSRange = m.range
                let indent: String  = source.substr(nsRange: m.range(at: 2))
                let block:  String  = source.substr(nsRange: r)
                let pfx             = source.getPreMatch(start: &indx, range: r)

                outs += (pfx + convertCommentDocsToStars01(indent: indent, blockString: block, empty: empty, lineLength: lineLength))
            }
        }

        source = ((outs + source.substr(from: indx)).trimmed + "\n")
    }

    private func convertCommentDocsToStars01(indent: String, blockString str: String, empty: Bool = false, lineLength: Int = 132) -> String {
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
            _outs += empty ? "\(indent)   \(lastLine)\n" : "\(indent) * \(lastLine)\n"
        }
        return _outs + "\(indent) */\n"
    }
}
