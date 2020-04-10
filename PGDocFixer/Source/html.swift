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

class HTMLElement {

    var name:       String
    var attributes: [String: String] = [:]
    var children:   [HTMLElement]    = []
    weak var parent: HTMLElement? = nil

    init(name: String, attrStr: String) {
        self.name = name

        htmlRx2.enumerateMatches(in: attrStr) {
            (m: NSTextCheckingResult?, _, _) in
            if let m: NSTextCheckingResult = m {
                let key: String = m.getSub(string: attrStr, at: 1)
                let val: String = m.getSub(string: attrStr, at: 2)
                attributes[key] = val
            }
        }
    }

    var innerDescription: String {
        var s: String = ""
        for e2: HTMLElement in children { s += e2.description }
        return s
    }

    var description: String {
        if name == "code" {
            return "`\(innerDescription)`"
        }
        else {
            var s: String = "<\(name)"

            for (k, v): (String, String) in attributes {
                s += " \(k)=\"\(v)\""
            }

            if children.count == 0 {
                s += "/>"
            }
            else {
                s += ">\(innerDescription)</\(name)>"
            }

            return s
        }
    }

    func addAttribute(name: String, value: String) {
        attributes[name] = value
    }

    func addChild(child: HTMLElement) {
        children.append(child)
        child.parent = self
    }
}

class HTMLText: HTMLElement {

    var content: String

    init(content: String) {
        self.content = content
        super.init(name: "", attrStr: "")
    }

    override var description:      String { content }
    override var innerDescription: String { content }
}

func scanHTML(string: String) -> HTMLElement? {
    var index: Int           = 0
    var curr:  HTMLElement?  = nil
    var stack: [HTMLElement] = []

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
