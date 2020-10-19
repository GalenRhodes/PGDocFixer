/************************************************************************//**
 *     PROJECT: PGDocFixer
 *    FILENAME: Alignment.swift
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

/*===============================================================================================================================*/
/// - Left:
/// - Center:
/// - Right:
///
enum Alignment {
    static let rx6: NSRegularExpression = try! regexML(pattern: "^(?:(\\:\\-{3,}\\:)|(\\-{3,}\\:)|(\\:?\\-{3,}))$")

    case Left
    case Center
    case Right

    /*===========================================================================================================================*/
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

    /*===========================================================================================================================*/
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
