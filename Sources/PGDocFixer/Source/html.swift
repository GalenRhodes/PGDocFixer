/************************************************************************//**
 *     PROJECT: PGDocFixer
 *    FILENAME: html.swift
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

let htmlRx1: NSRegularExpression = try! regexML(pattern: "<(/?)(\\w+)((?:\\s+\\w+=\"[^\"]*\")*)(?:\\s*(/))?>")
let htmlRx2: NSRegularExpression = try! regexML(pattern: "(\\w+)=\"([^\"]*)\"")
let htmlRx3: NSRegularExpression = try! regexML(pattern: #"([&<>"]|(?:\r\n?|\n)|[\u0000-\u001f\u0026\u003c\u003e\u007f\u00a0-\u00b6\u00b8-\u00ff\u0152-\u0153\u0160-\u0161\u0178\u0192\u02c6\u02dc\u0391-\u03a1\u03a3-\u03a9\u03b1-\u03c9\u03d1-\u03d2\u03d6\u2002-\u2003\u2009\u200c-\u200f\u2013-\u2014\u2018-\u201a\u201c-\u201e\u2020-\u2022\u2026\u2030\u2032-\u2033\u2039-\u203a\u203e\u20ac\u2122\u2190-\u2194\u21b5\u2200\u2202-\u2203\u2205\u2207-\u2209\u220b\u220f\u2211-\u2212\u2217\u221a\u221d-\u221e\u2220\u2227-\u222b\u2234\u223c\u2245\u2248\u2260-\u2261\u2264-\u2265\u2282-\u2284\u2286-\u2287\u2295\u2297\u22a5\u22c5\u2308-\u230b\u25ca\u2660\u2663\u2665-\u2666])"#)
let htmlRx4: NSRegularExpression = try! regexML(pattern: #"&(#([0-9]{1,3})|[^;]+);"#)

let htmlRx5: NSRegularExpression = try! regexML(pattern: "\\R")
let htmlRx6: NSRegularExpression = try! regexML(pattern: "\\s+(<\(BELEMS))(?=\\s|>)")
let htmlRx7: NSRegularExpression = try! regexML(pattern: "(</\(BELEMS)>)\\s+")

let htmlSymbols: [String: String] = [
    "lt": "<", "gt": ">", "amp": "&", "quot": "\"",
]

let blockElements: [String] = [
    "p", "div", "table", "dl", "ol", "ul", "h1", "h2", "h3", "h4", "h5", "h6", "pre", "dt", "dd", "li", "dir", "address", "article", "aside", "blockquote", "center", "del", "figure",
    "figcaption", "footer", "header", "hr", "ins", "main", "menu", "nav", "noscript", "section", "script"
]
// (p|div|table|dl|ol|ul|h1|h2|h3|h4|h5|h6|pre|dt|dd|li|dir|address|article|aside|blockquote|center|del|figure|figcaption|footer|header|hr|ins|main|menu|nav|noscript|section|script)
//=================================================================================================================================
///
/// HTML
///
class HTMLElement {

    let name:     String
    var attrs:    [String: String] = [:]
    var children: [HTMLElement]    = []
    weak var parent: HTMLElement? = nil

    init(name: String, attrStr: String) {
        self.name = name
        htmlRx2.enumerateMatches(in: attrStr) { (m: NSTextCheckingResult?, _, _) in if let m: NSTextCheckingResult = m { attrs[m.getSub(string: attrStr, at: 1)] = m.getSub(string: attrStr, at: 2) } }
    }

    var innerHtml: String {
        var s: String = ""
        for e2: HTMLElement in children { s += e2.html }
        return s
    }

    var html: String {
        if name == "code" {
            return "`\(innerHtml)`"
        }
        else {
            var s: String = "<\(name)"
            for (k, v): (String, String) in attrs { s += " \(k)=\"\(v)\"" }
            return s + ((children.count == 0) ? " />" : ">\(innerHtml)</\(name)>")
        }
    }

    var isBlock: Bool { blockElements.contains(name) }

    func addChild(child: HTMLElement) {
        children.append(child)
        child.parent = self
    }
}

//=================================================================================================================================
///
///
class HTMLText: HTMLElement {

    var content: String

    init(content: String) {
        self.content = content
        super.init(name: "", attrStr: "")
    }

    override var html:      String { innerHtml }
    override var innerHtml: String { content }
}

//=================================================================================================================================
///
///
/// - Parameter string:
/// - Returns:
///
func scanHTML(string str: String) -> HTMLElement? {
    var index:  Int           = 0
    var curr:   HTMLElement?  = nil
    var stack:  [HTMLElement] = []
    let string: String        = htmlRx7.stringByReplacingMatches(in: htmlRx6.stringByReplacingMatches(in: htmlRx5.stringByReplacingMatches(in: str, withTemplate: " "), withTemplate: "$1"),
                                                                 withTemplate: "$1")

    htmlRx1.enumerateMatches(in: string) {
        (m: NSTextCheckingResult?, _, _) in
        if let m: NSTextCheckingResult = m {
            let s1: String = m.getSub(string: string, at: 1)
            let s2: String = m.getSub(string: string, at: 2)
            let s3: String = m.getSub(string: string, at: 3)
            let s4: String = m.getSub(string: string, at: 4)
            let px: String = string.getPreMatch(start: &index, range: m.range)

            if let e: HTMLElement = curr, px.count > 0 {
                e.addChild(child: HTMLText(content: px))
            }
            if s1 == "/" {
                curr = stack.popLast()
            }
            else if s4 == "/" {
                if let e: HTMLElement = curr {
                    e.addChild(child: HTMLElement(name: s2, attrStr: s3))
                }
            }
            else {
                let c = HTMLElement(name: s2, attrStr: s3)

                if let e: HTMLElement = curr {
                    e.addChild(child: c)
                    stack.append(e)
                }

                curr = c
            }
        }
    }

    return ((stack.count == 0) ? curr : stack[0])
}

//=================================================================================================================================
///
///
/// - Parameter str:
/// - Returns:
///
public func unescapeHTML(string str: String) -> String {
    var outs: String = ""
    var idx:  Int    = 0

    htmlRx4.enumerateMatches(in: str) {
        (m: NSTextCheckingResult?, _, _) in
        if let m: NSTextCheckingResult = m {
            let r: NSRange = m.range(at: 1)
            let s: String  = str.substr(range: r)

            outs += str.getPreMatch(start: &idx, range: r)

            if s.hasPrefix("#") {
                let r2: NSRange = m.range(at: 2)
                if r2.location != NSNotFound, let ch: Int = Int(str.substr(range: r2)), let us: UnicodeScalar = UnicodeScalar(ch) {
                    outs.append(Character(us))
                }
            }
            else {
            }
        }
    }

    return outs
}

//=================================================================================================================================
///
///
/// - Parameters:
///   - str:
///   - forAttrs:
/// - Returns:
///
public func escapeHTML(string str: String, forAttrs: Bool = false) -> String {
    var outs: String = ""
    var idx:  Int    = 0

    htmlRx3.enumerateMatches(in: str) {
        (m: NSTextCheckingResult?, _, _) in
        if let m: NSTextCheckingResult = m {
            let r:     NSRange = m.range
            let chStr: String  = str.substr(range: r)

            outs += str.getPreMatch(start: &idx, range: r)
//@f:0
            switch chStr {
                case "\r":   outs += forAttrs ? "&#13;"      : "<br/>"
                case "\r\n": outs += forAttrs ? "&#13;&#10;" : "<br/>"
                case "\n":   outs += forAttrs ? "&#10;"      : "<br/>"
                case "&":    outs += "&amp;"
                case "<":    outs += "&lt;"
                case ">":    outs += "&gt;"
                case "\"":   outs += "&quot;"
                default:
                    if let i: Unicode.Scalar = Unicode.Scalar(String(chStr[String.Index(utf16Offset: 0, in: chStr)])) {
                        outs += "&#\(i.value);"
                    }
            }
//@f:1
        }
    }

    return outs + str.substr(from: idx)
}

let htmlEntities: [String: Character] = [
    "amp": Character(UnicodeScalar(38)!),
    "lt": Character(UnicodeScalar(60)!),
    "gt": Character(UnicodeScalar(62)!),
    "Agrave": Character(UnicodeScalar(192)!),
    "Aacute": Character(UnicodeScalar(193)!),
    "Acirc": Character(UnicodeScalar(194)!),
    "Atilde": Character(UnicodeScalar(195)!),
    "Auml": Character(UnicodeScalar(196)!),
    "Aring": Character(UnicodeScalar(197)!),
    "AElig": Character(UnicodeScalar(198)!),
    "Ccedil": Character(UnicodeScalar(199)!),
    "Egrave": Character(UnicodeScalar(200)!),
    "Eacute": Character(UnicodeScalar(201)!),
    "Ecirc": Character(UnicodeScalar(202)!),
    "Euml": Character(UnicodeScalar(203)!),
    "Igrave": Character(UnicodeScalar(204)!),
    "Iacute": Character(UnicodeScalar(205)!),
    "Icirc": Character(UnicodeScalar(206)!),
    "Iuml": Character(UnicodeScalar(207)!),
    "ETH": Character(UnicodeScalar(208)!),
    "Ntilde": Character(UnicodeScalar(209)!),
    "Ograve": Character(UnicodeScalar(210)!),
    "Oacute": Character(UnicodeScalar(211)!),
    "Ocirc": Character(UnicodeScalar(212)!),
    "Otilde": Character(UnicodeScalar(213)!),
    "Ouml": Character(UnicodeScalar(214)!),
    "Oslash": Character(UnicodeScalar(216)!),
    "Ugrave": Character(UnicodeScalar(217)!),
    "Uacute": Character(UnicodeScalar(218)!),
    "Ucirc": Character(UnicodeScalar(219)!),
    "Uuml": Character(UnicodeScalar(220)!),
    "Yacute": Character(UnicodeScalar(221)!),
    "THORN": Character(UnicodeScalar(222)!),
    "szlig": Character(UnicodeScalar(223)!),
    "agrave": Character(UnicodeScalar(224)!),
    "aacute": Character(UnicodeScalar(225)!),
    "acirc": Character(UnicodeScalar(226)!),
    "atilde": Character(UnicodeScalar(227)!),
    "auml": Character(UnicodeScalar(228)!),
    "aring": Character(UnicodeScalar(229)!),
    "aelig": Character(UnicodeScalar(230)!),
    "ccedil": Character(UnicodeScalar(231)!),
    "egrave": Character(UnicodeScalar(232)!),
    "eacute": Character(UnicodeScalar(233)!),
    "ecirc": Character(UnicodeScalar(234)!),
    "euml": Character(UnicodeScalar(235)!),
    "igrave": Character(UnicodeScalar(236)!),
    "iacute": Character(UnicodeScalar(237)!),
    "icirc": Character(UnicodeScalar(238)!),
    "iuml": Character(UnicodeScalar(239)!),
    "eth": Character(UnicodeScalar(240)!),
    "ntilde": Character(UnicodeScalar(241)!),
    "ograve": Character(UnicodeScalar(242)!),
    "oacute": Character(UnicodeScalar(243)!),
    "ocirc": Character(UnicodeScalar(244)!),
    "otilde": Character(UnicodeScalar(245)!),
    "ouml": Character(UnicodeScalar(246)!),
    "oslash": Character(UnicodeScalar(248)!),
    "ugrave": Character(UnicodeScalar(249)!),
    "uacute": Character(UnicodeScalar(250)!),
    "ucirc": Character(UnicodeScalar(251)!),
    "uuml": Character(UnicodeScalar(252)!),
    "yacute": Character(UnicodeScalar(253)!),
    "thorn": Character(UnicodeScalar(254)!),
    "yuml": Character(UnicodeScalar(255)!),
    "nbsp": Character(UnicodeScalar(160)!),
    "iexcl": Character(UnicodeScalar(161)!),
    "cent": Character(UnicodeScalar(162)!),
    "pound": Character(UnicodeScalar(163)!),
    "curren": Character(UnicodeScalar(164)!),
    "yen": Character(UnicodeScalar(165)!),
    "brvbar": Character(UnicodeScalar(166)!),
    "sect": Character(UnicodeScalar(167)!),
    "uml": Character(UnicodeScalar(168)!),
    "copy": Character(UnicodeScalar(169)!),
    "ordf": Character(UnicodeScalar(170)!),
    "laquo": Character(UnicodeScalar(171)!),
    "not": Character(UnicodeScalar(172)!),
    "shy": Character(UnicodeScalar(173)!),
    "reg": Character(UnicodeScalar(174)!),
    "macr": Character(UnicodeScalar(175)!),
    "deg": Character(UnicodeScalar(176)!),
    "plusmn": Character(UnicodeScalar(177)!),
    "sup2": Character(UnicodeScalar(178)!),
    "sup3": Character(UnicodeScalar(179)!),
    "acute": Character(UnicodeScalar(180)!),
    "micro": Character(UnicodeScalar(181)!),
    "para": Character(UnicodeScalar(182)!),
    "cedil": Character(UnicodeScalar(184)!),
    "sup1": Character(UnicodeScalar(185)!),
    "ordm": Character(UnicodeScalar(186)!),
    "raquo": Character(UnicodeScalar(187)!),
    "frac14": Character(UnicodeScalar(188)!),
    "frac12": Character(UnicodeScalar(189)!),
    "frac34": Character(UnicodeScalar(190)!),
    "iquest": Character(UnicodeScalar(191)!),
    "times": Character(UnicodeScalar(215)!),
    "divide": Character(UnicodeScalar(247)!),
    "forall": Character(UnicodeScalar(8704)!),
    "part": Character(UnicodeScalar(8706)!),
    "exist": Character(UnicodeScalar(8707)!),
    "empty": Character(UnicodeScalar(8709)!),
    "nabla": Character(UnicodeScalar(8711)!),
    "isin": Character(UnicodeScalar(8712)!),
    "notin": Character(UnicodeScalar(8713)!),
    "ni": Character(UnicodeScalar(8715)!),
    "prod": Character(UnicodeScalar(8719)!),
    "sum": Character(UnicodeScalar(8721)!),
    "minus": Character(UnicodeScalar(8722)!),
    "lowast": Character(UnicodeScalar(8727)!),
    "radic": Character(UnicodeScalar(8730)!),
    "prop": Character(UnicodeScalar(8733)!),
    "infin": Character(UnicodeScalar(8734)!),
    "ang": Character(UnicodeScalar(8736)!),
    "and": Character(UnicodeScalar(8743)!),
    "or": Character(UnicodeScalar(8744)!),
    "cap": Character(UnicodeScalar(8745)!),
    "cup": Character(UnicodeScalar(8746)!),
    "int": Character(UnicodeScalar(8747)!),
    "there4": Character(UnicodeScalar(8756)!),
    "sim": Character(UnicodeScalar(8764)!),
    "cong": Character(UnicodeScalar(8773)!),
    "asymp": Character(UnicodeScalar(8776)!),
    "ne": Character(UnicodeScalar(8800)!),
    "equiv": Character(UnicodeScalar(8801)!),
    "le": Character(UnicodeScalar(8804)!),
    "ge": Character(UnicodeScalar(8805)!),
    "sub": Character(UnicodeScalar(8834)!),
    "sup": Character(UnicodeScalar(8835)!),
    "nsub": Character(UnicodeScalar(8836)!),
    "sube": Character(UnicodeScalar(8838)!),
    "supe": Character(UnicodeScalar(8839)!),
    "oplus": Character(UnicodeScalar(8853)!),
    "otimes": Character(UnicodeScalar(8855)!),
    "perp": Character(UnicodeScalar(8869)!),
    "sdot": Character(UnicodeScalar(8901)!),
    "Alpha": Character(UnicodeScalar(913)!),
    "Beta": Character(UnicodeScalar(914)!),
    "Gamma": Character(UnicodeScalar(915)!),
    "Delta": Character(UnicodeScalar(916)!),
    "Epsilon": Character(UnicodeScalar(917)!),
    "Zeta": Character(UnicodeScalar(918)!),
    "Eta": Character(UnicodeScalar(919)!),
    "Theta": Character(UnicodeScalar(920)!),
    "Iota": Character(UnicodeScalar(921)!),
    "Kappa": Character(UnicodeScalar(922)!),
    "Lambda": Character(UnicodeScalar(923)!),
    "Mu": Character(UnicodeScalar(924)!),
    "Nu": Character(UnicodeScalar(925)!),
    "Xi": Character(UnicodeScalar(926)!),
    "Omicron": Character(UnicodeScalar(927)!),
    "Pi": Character(UnicodeScalar(928)!),
    "Rho": Character(UnicodeScalar(929)!),
    "Sigma": Character(UnicodeScalar(931)!),
    "Tau": Character(UnicodeScalar(932)!),
    "Upsilon": Character(UnicodeScalar(933)!),
    "Phi": Character(UnicodeScalar(934)!),
    "Chi": Character(UnicodeScalar(935)!),
    "Psi": Character(UnicodeScalar(936)!),
    "Omega": Character(UnicodeScalar(937)!),
    "alpha": Character(UnicodeScalar(945)!),
    "beta": Character(UnicodeScalar(946)!),
    "gamma": Character(UnicodeScalar(947)!),
    "delta": Character(UnicodeScalar(948)!),
    "epsilon": Character(UnicodeScalar(949)!),
    "zeta": Character(UnicodeScalar(950)!),
    "eta": Character(UnicodeScalar(951)!),
    "theta": Character(UnicodeScalar(952)!),
    "iota": Character(UnicodeScalar(953)!),
    "kappa": Character(UnicodeScalar(954)!),
    "lambda": Character(UnicodeScalar(955)!),
    "mu": Character(UnicodeScalar(956)!),
    "nu": Character(UnicodeScalar(957)!),
    "xi": Character(UnicodeScalar(958)!),
    "omicron": Character(UnicodeScalar(959)!),
    "pi": Character(UnicodeScalar(960)!),
    "rho": Character(UnicodeScalar(961)!),
    "sigmaf": Character(UnicodeScalar(962)!),
    "sigma": Character(UnicodeScalar(963)!),
    "tau": Character(UnicodeScalar(964)!),
    "upsilon": Character(UnicodeScalar(965)!),
    "phi": Character(UnicodeScalar(966)!),
    "chi": Character(UnicodeScalar(967)!),
    "psi": Character(UnicodeScalar(968)!),
    "omega": Character(UnicodeScalar(969)!),
    "thetasym": Character(UnicodeScalar(977)!),
    "upsih": Character(UnicodeScalar(978)!),
    "piv": Character(UnicodeScalar(982)!),
    "OElig": Character(UnicodeScalar(338)!),
    "oelig": Character(UnicodeScalar(339)!),
    "Scaron": Character(UnicodeScalar(352)!),
    "scaron": Character(UnicodeScalar(353)!),
    "Yuml": Character(UnicodeScalar(376)!),
    "fnof": Character(UnicodeScalar(402)!),
    "circ": Character(UnicodeScalar(710)!),
    "tilde": Character(UnicodeScalar(732)!),
    "ensp": Character(UnicodeScalar(8194)!),
    "emsp": Character(UnicodeScalar(8195)!),
    "thinsp": Character(UnicodeScalar(8201)!),
    "zwnj": Character(UnicodeScalar(8204)!),
    "zwj": Character(UnicodeScalar(8205)!),
    "lrm": Character(UnicodeScalar(8206)!),
    "rlm": Character(UnicodeScalar(8207)!),
    "ndash": Character(UnicodeScalar(8211)!),
    "mdash": Character(UnicodeScalar(8212)!),
    "lsquo": Character(UnicodeScalar(8216)!),
    "rsquo": Character(UnicodeScalar(8217)!),
    "sbquo": Character(UnicodeScalar(8218)!),
    "ldquo": Character(UnicodeScalar(8220)!),
    "rdquo": Character(UnicodeScalar(8221)!),
    "bdquo": Character(UnicodeScalar(8222)!),
    "dagger": Character(UnicodeScalar(8224)!),
    "Dagger": Character(UnicodeScalar(8225)!),
    "bull": Character(UnicodeScalar(8226)!),
    "hellip": Character(UnicodeScalar(8230)!),
    "permil": Character(UnicodeScalar(8240)!),
    "prime": Character(UnicodeScalar(8242)!),
    "Prime": Character(UnicodeScalar(8243)!),
    "lsaquo": Character(UnicodeScalar(8249)!),
    "rsaquo": Character(UnicodeScalar(8250)!),
    "oline": Character(UnicodeScalar(8254)!),
    "euro": Character(UnicodeScalar(8364)!),
    "trade": Character(UnicodeScalar(8482)!),
    "larr": Character(UnicodeScalar(8592)!),
    "uarr": Character(UnicodeScalar(8593)!),
    "rarr": Character(UnicodeScalar(8594)!),
    "darr": Character(UnicodeScalar(8595)!),
    "harr": Character(UnicodeScalar(8596)!),
    "crarr": Character(UnicodeScalar(8629)!),
    "lceil": Character(UnicodeScalar(8968)!),
    "rceil": Character(UnicodeScalar(8969)!),
    "lfloor": Character(UnicodeScalar(8970)!),
    "rfloor": Character(UnicodeScalar(8971)!),
    "loz": Character(UnicodeScalar(9674)!),
    "spades": Character(UnicodeScalar(9824)!),
    "clubs": Character(UnicodeScalar(9827)!),
    "hearts": Character(UnicodeScalar(9829)!),
    "diams": Character(UnicodeScalar(9830)!),
]

let htmlUnentities: [String: String] = [
    String(Character(UnicodeScalar(38)!)): "amp",
    String(Character(UnicodeScalar(60)!)): "lt",
    String(Character(UnicodeScalar(62)!)): "gt",
    String(Character(UnicodeScalar(192)!)): "Agrave",
    String(Character(UnicodeScalar(193)!)): "Aacute",
    String(Character(UnicodeScalar(194)!)): "Acirc",
    String(Character(UnicodeScalar(195)!)): "Atilde",
    String(Character(UnicodeScalar(196)!)): "Auml",
    String(Character(UnicodeScalar(197)!)): "Aring",
    String(Character(UnicodeScalar(198)!)): "AElig",
    String(Character(UnicodeScalar(199)!)): "Ccedil",
    String(Character(UnicodeScalar(200)!)): "Egrave",
    String(Character(UnicodeScalar(201)!)): "Eacute",
    String(Character(UnicodeScalar(202)!)): "Ecirc",
    String(Character(UnicodeScalar(203)!)): "Euml",
    String(Character(UnicodeScalar(204)!)): "Igrave",
    String(Character(UnicodeScalar(205)!)): "Iacute",
    String(Character(UnicodeScalar(206)!)): "Icirc",
    String(Character(UnicodeScalar(207)!)): "Iuml",
    String(Character(UnicodeScalar(208)!)): "ETH",
    String(Character(UnicodeScalar(209)!)): "Ntilde",
    String(Character(UnicodeScalar(210)!)): "Ograve",
    String(Character(UnicodeScalar(211)!)): "Oacute",
    String(Character(UnicodeScalar(212)!)): "Ocirc",
    String(Character(UnicodeScalar(213)!)): "Otilde",
    String(Character(UnicodeScalar(214)!)): "Ouml",
    String(Character(UnicodeScalar(216)!)): "Oslash",
    String(Character(UnicodeScalar(217)!)): "Ugrave",
    String(Character(UnicodeScalar(218)!)): "Uacute",
    String(Character(UnicodeScalar(219)!)): "Ucirc",
    String(Character(UnicodeScalar(220)!)): "Uuml",
    String(Character(UnicodeScalar(221)!)): "Yacute",
    String(Character(UnicodeScalar(222)!)): "THORN",
    String(Character(UnicodeScalar(223)!)): "szlig",
    String(Character(UnicodeScalar(224)!)): "agrave",
    String(Character(UnicodeScalar(225)!)): "aacute",
    String(Character(UnicodeScalar(226)!)): "acirc",
    String(Character(UnicodeScalar(227)!)): "atilde",
    String(Character(UnicodeScalar(228)!)): "auml",
    String(Character(UnicodeScalar(229)!)): "aring",
    String(Character(UnicodeScalar(230)!)): "aelig",
    String(Character(UnicodeScalar(231)!)): "ccedil",
    String(Character(UnicodeScalar(232)!)): "egrave",
    String(Character(UnicodeScalar(233)!)): "eacute",
    String(Character(UnicodeScalar(234)!)): "ecirc",
    String(Character(UnicodeScalar(235)!)): "euml",
    String(Character(UnicodeScalar(236)!)): "igrave",
    String(Character(UnicodeScalar(237)!)): "iacute",
    String(Character(UnicodeScalar(238)!)): "icirc",
    String(Character(UnicodeScalar(239)!)): "iuml",
    String(Character(UnicodeScalar(240)!)): "eth",
    String(Character(UnicodeScalar(241)!)): "ntilde",
    String(Character(UnicodeScalar(242)!)): "ograve",
    String(Character(UnicodeScalar(243)!)): "oacute",
    String(Character(UnicodeScalar(244)!)): "ocirc",
    String(Character(UnicodeScalar(245)!)): "otilde",
    String(Character(UnicodeScalar(246)!)): "ouml",
    String(Character(UnicodeScalar(248)!)): "oslash",
    String(Character(UnicodeScalar(249)!)): "ugrave",
    String(Character(UnicodeScalar(250)!)): "uacute",
    String(Character(UnicodeScalar(251)!)): "ucirc",
    String(Character(UnicodeScalar(252)!)): "uuml",
    String(Character(UnicodeScalar(253)!)): "yacute",
    String(Character(UnicodeScalar(254)!)): "thorn",
    String(Character(UnicodeScalar(255)!)): "yuml",
    String(Character(UnicodeScalar(160)!)): "nbsp",
    String(Character(UnicodeScalar(161)!)): "iexcl",
    String(Character(UnicodeScalar(162)!)): "cent",
    String(Character(UnicodeScalar(163)!)): "pound",
    String(Character(UnicodeScalar(164)!)): "curren",
    String(Character(UnicodeScalar(165)!)): "yen",
    String(Character(UnicodeScalar(166)!)): "brvbar",
    String(Character(UnicodeScalar(167)!)): "sect",
    String(Character(UnicodeScalar(168)!)): "uml",
    String(Character(UnicodeScalar(169)!)): "copy",
    String(Character(UnicodeScalar(170)!)): "ordf",
    String(Character(UnicodeScalar(171)!)): "laquo",
    String(Character(UnicodeScalar(172)!)): "not",
    String(Character(UnicodeScalar(173)!)): "shy",
    String(Character(UnicodeScalar(174)!)): "reg",
    String(Character(UnicodeScalar(175)!)): "macr",
    String(Character(UnicodeScalar(176)!)): "deg",
    String(Character(UnicodeScalar(177)!)): "plusmn",
    String(Character(UnicodeScalar(178)!)): "sup2",
    String(Character(UnicodeScalar(179)!)): "sup3",
    String(Character(UnicodeScalar(180)!)): "acute",
    String(Character(UnicodeScalar(181)!)): "micro",
    String(Character(UnicodeScalar(182)!)): "para",
    String(Character(UnicodeScalar(184)!)): "cedil",
    String(Character(UnicodeScalar(185)!)): "sup1",
    String(Character(UnicodeScalar(186)!)): "ordm",
    String(Character(UnicodeScalar(187)!)): "raquo",
    String(Character(UnicodeScalar(188)!)): "frac14",
    String(Character(UnicodeScalar(189)!)): "frac12",
    String(Character(UnicodeScalar(190)!)): "frac34",
    String(Character(UnicodeScalar(191)!)): "iquest",
    String(Character(UnicodeScalar(215)!)): "times",
    String(Character(UnicodeScalar(247)!)): "divide",
    String(Character(UnicodeScalar(8704)!)): "forall",
    String(Character(UnicodeScalar(8706)!)): "part",
    String(Character(UnicodeScalar(8707)!)): "exist",
    String(Character(UnicodeScalar(8709)!)): "empty",
    String(Character(UnicodeScalar(8711)!)): "nabla",
    String(Character(UnicodeScalar(8712)!)): "isin",
    String(Character(UnicodeScalar(8713)!)): "notin",
    String(Character(UnicodeScalar(8715)!)): "ni",
    String(Character(UnicodeScalar(8719)!)): "prod",
    String(Character(UnicodeScalar(8721)!)): "sum",
    String(Character(UnicodeScalar(8722)!)): "minus",
    String(Character(UnicodeScalar(8727)!)): "lowast",
    String(Character(UnicodeScalar(8730)!)): "radic",
    String(Character(UnicodeScalar(8733)!)): "prop",
    String(Character(UnicodeScalar(8734)!)): "infin",
    String(Character(UnicodeScalar(8736)!)): "ang",
    String(Character(UnicodeScalar(8743)!)): "and",
    String(Character(UnicodeScalar(8744)!)): "or",
    String(Character(UnicodeScalar(8745)!)): "cap",
    String(Character(UnicodeScalar(8746)!)): "cup",
    String(Character(UnicodeScalar(8747)!)): "int",
    String(Character(UnicodeScalar(8756)!)): "there4",
    String(Character(UnicodeScalar(8764)!)): "sim",
    String(Character(UnicodeScalar(8773)!)): "cong",
    String(Character(UnicodeScalar(8776)!)): "asymp",
    String(Character(UnicodeScalar(8800)!)): "ne",
    String(Character(UnicodeScalar(8801)!)): "equiv",
    String(Character(UnicodeScalar(8804)!)): "le",
    String(Character(UnicodeScalar(8805)!)): "ge",
    String(Character(UnicodeScalar(8834)!)): "sub",
    String(Character(UnicodeScalar(8835)!)): "sup",
    String(Character(UnicodeScalar(8836)!)): "nsub",
    String(Character(UnicodeScalar(8838)!)): "sube",
    String(Character(UnicodeScalar(8839)!)): "supe",
    String(Character(UnicodeScalar(8853)!)): "oplus",
    String(Character(UnicodeScalar(8855)!)): "otimes",
    String(Character(UnicodeScalar(8869)!)): "perp",
    String(Character(UnicodeScalar(8901)!)): "sdot",
    String(Character(UnicodeScalar(913)!)): "Alpha",
    String(Character(UnicodeScalar(914)!)): "Beta",
    String(Character(UnicodeScalar(915)!)): "Gamma",
    String(Character(UnicodeScalar(916)!)): "Delta",
    String(Character(UnicodeScalar(917)!)): "Epsilon",
    String(Character(UnicodeScalar(918)!)): "Zeta",
    String(Character(UnicodeScalar(919)!)): "Eta",
    String(Character(UnicodeScalar(920)!)): "Theta",
    String(Character(UnicodeScalar(921)!)): "Iota",
    String(Character(UnicodeScalar(922)!)): "Kappa",
    String(Character(UnicodeScalar(923)!)): "Lambda",
    String(Character(UnicodeScalar(924)!)): "Mu",
    String(Character(UnicodeScalar(925)!)): "Nu",
    String(Character(UnicodeScalar(926)!)): "Xi",
    String(Character(UnicodeScalar(927)!)): "Omicron",
    String(Character(UnicodeScalar(928)!)): "Pi",
    String(Character(UnicodeScalar(929)!)): "Rho",
    String(Character(UnicodeScalar(931)!)): "Sigma",
    String(Character(UnicodeScalar(932)!)): "Tau",
    String(Character(UnicodeScalar(933)!)): "Upsilon",
    String(Character(UnicodeScalar(934)!)): "Phi",
    String(Character(UnicodeScalar(935)!)): "Chi",
    String(Character(UnicodeScalar(936)!)): "Psi",
    String(Character(UnicodeScalar(937)!)): "Omega",
    String(Character(UnicodeScalar(945)!)): "alpha",
    String(Character(UnicodeScalar(946)!)): "beta",
    String(Character(UnicodeScalar(947)!)): "gamma",
    String(Character(UnicodeScalar(948)!)): "delta",
    String(Character(UnicodeScalar(949)!)): "epsilon",
    String(Character(UnicodeScalar(950)!)): "zeta",
    String(Character(UnicodeScalar(951)!)): "eta",
    String(Character(UnicodeScalar(952)!)): "theta",
    String(Character(UnicodeScalar(953)!)): "iota",
    String(Character(UnicodeScalar(954)!)): "kappa",
    String(Character(UnicodeScalar(955)!)): "lambda",
    String(Character(UnicodeScalar(956)!)): "mu",
    String(Character(UnicodeScalar(957)!)): "nu",
    String(Character(UnicodeScalar(958)!)): "xi",
    String(Character(UnicodeScalar(959)!)): "omicron",
    String(Character(UnicodeScalar(960)!)): "pi",
    String(Character(UnicodeScalar(961)!)): "rho",
    String(Character(UnicodeScalar(962)!)): "sigmaf",
    String(Character(UnicodeScalar(963)!)): "sigma",
    String(Character(UnicodeScalar(964)!)): "tau",
    String(Character(UnicodeScalar(965)!)): "upsilon",
    String(Character(UnicodeScalar(966)!)): "phi",
    String(Character(UnicodeScalar(967)!)): "chi",
    String(Character(UnicodeScalar(968)!)): "psi",
    String(Character(UnicodeScalar(969)!)): "omega",
    String(Character(UnicodeScalar(977)!)): "thetasym",
    String(Character(UnicodeScalar(978)!)): "upsih",
    String(Character(UnicodeScalar(982)!)): "piv",
    String(Character(UnicodeScalar(338)!)): "OElig",
    String(Character(UnicodeScalar(339)!)): "oelig",
    String(Character(UnicodeScalar(352)!)): "Scaron",
    String(Character(UnicodeScalar(353)!)): "scaron",
    String(Character(UnicodeScalar(376)!)): "Yuml",
    String(Character(UnicodeScalar(402)!)): "fnof",
    String(Character(UnicodeScalar(710)!)): "circ",
    String(Character(UnicodeScalar(732)!)): "tilde",
    String(Character(UnicodeScalar(8194)!)): "ensp",
    String(Character(UnicodeScalar(8195)!)): "emsp",
    String(Character(UnicodeScalar(8201)!)): "thinsp",
    String(Character(UnicodeScalar(8204)!)): "zwnj",
    String(Character(UnicodeScalar(8205)!)): "zwj",
    String(Character(UnicodeScalar(8206)!)): "lrm",
    String(Character(UnicodeScalar(8207)!)): "rlm",
    String(Character(UnicodeScalar(8211)!)): "ndash",
    String(Character(UnicodeScalar(8212)!)): "mdash",
    String(Character(UnicodeScalar(8216)!)): "lsquo",
    String(Character(UnicodeScalar(8217)!)): "rsquo",
    String(Character(UnicodeScalar(8218)!)): "sbquo",
    String(Character(UnicodeScalar(8220)!)): "ldquo",
    String(Character(UnicodeScalar(8221)!)): "rdquo",
    String(Character(UnicodeScalar(8222)!)): "bdquo",
    String(Character(UnicodeScalar(8224)!)): "dagger",
    String(Character(UnicodeScalar(8225)!)): "Dagger",
    String(Character(UnicodeScalar(8226)!)): "bull",
    String(Character(UnicodeScalar(8230)!)): "hellip",
    String(Character(UnicodeScalar(8240)!)): "permil",
    String(Character(UnicodeScalar(8242)!)): "prime",
    String(Character(UnicodeScalar(8243)!)): "Prime",
    String(Character(UnicodeScalar(8249)!)): "lsaquo",
    String(Character(UnicodeScalar(8250)!)): "rsaquo",
    String(Character(UnicodeScalar(8254)!)): "oline",
    String(Character(UnicodeScalar(8364)!)): "euro",
    String(Character(UnicodeScalar(8482)!)): "trade",
    String(Character(UnicodeScalar(8592)!)): "larr",
    String(Character(UnicodeScalar(8593)!)): "uarr",
    String(Character(UnicodeScalar(8594)!)): "rarr",
    String(Character(UnicodeScalar(8595)!)): "darr",
    String(Character(UnicodeScalar(8596)!)): "harr",
    String(Character(UnicodeScalar(8629)!)): "crarr",
    String(Character(UnicodeScalar(8968)!)): "lceil",
    String(Character(UnicodeScalar(8969)!)): "rceil",
    String(Character(UnicodeScalar(8970)!)): "lfloor",
    String(Character(UnicodeScalar(8971)!)): "rfloor",
    String(Character(UnicodeScalar(9674)!)): "loz",
    String(Character(UnicodeScalar(9824)!)): "spades",
    String(Character(UnicodeScalar(9827)!)): "clubs",
    String(Character(UnicodeScalar(9829)!)): "hearts",
    String(Character(UnicodeScalar(9830)!)): "diams",
]
