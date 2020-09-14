/************************************************************************//**
 *     PROJECT: PGDocFixer
 *    FILENAME: DLItem.swift
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

struct DLItem {
    static let rx1: NSRegularExpression = try! regexML(pattern: "^<b>(.+?)</b>$")
    static let rx2: NSRegularExpression = try! regexML(pattern: "\\s+")

    let dt: String
    let dd: String
    let p1: String = "    <dt>"
    let p2: String = "    <dd>"
    let p3: String = "        "

    init(dt: String, dd: String) {
        self.dd = dd

        if let m: NSTextCheckingResult = DLItem.rx1.firstMatch(in: dt) {
            self.dt = m.getSub(string: dt, at: 1)
        }
        else {
            self.dt = dt
        }
    }

    func getHTML(prefix: String, lineLength: Int = 132) -> String {
        return "\(prefix)\(p1)<b>\(dt)</b></dt>\(CR)\(WordWrap(prefix1: "\(prefix)\(p2)", prefix2: "\(prefix)\(p3)", lineLength: lineLength).wrap(str: dd))</dd>\(CR)"
    }
}
