/************************************************************************//**
 *     PROJECT: PGDocFixer
 *    FILENAME: LineParts.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/4/20
 *
 * Copyright © 2020 Galen Rhodes. All rights reserved.
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
struct LineParts {
    let s0: String
    let s1: String
    let s2: String
    let s3: String
    let s4: String
    let s5: String

    init(match m: NSTextCheckingResult, block: String) {
        s0 = m.getSub(string: block, at: 0)
        s1 = m.getSub(string: block, at: 1)
        s2 = m.getSub(string: block, at: 2)
        s3 = m.getSub(string: block, at: 3)
        s4 = m.getSub(string: block, at: 4)
        s5 = m.getSub(string: block, at: 5)
    }
}
