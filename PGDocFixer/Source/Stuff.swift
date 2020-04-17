/************************************************************************//**
 *     PROJECT: PGDocFixer
 *    FILENAME: Stuff.swift
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

//=================================================================================================================================
///
/// Get all of the Swift source files under the given directory `workPath`.  Each file must be older than the file at the given
/// path `logFile`.
///
/// - Parameters:
///   - workPath:
///   - logFile:
///
/// - Returns:
///
func getFileList(path workPath: String, logFile: String) -> [String] {
    var list:    [String]         = []
    let fm:      FileManager      = FileManager.default
    let modDate: FileAttributeKey = FileAttributeKey.modificationDate

    func testFilename(_ fileName: String) -> Bool {
        (fileName.hasSuffix(".swift") && !fileName.hasPrefix("."))
    }

    func fileList1(list: inout [String], dir: String, date date1: NSDate) {
        if let e: FileManager.DirectoryEnumerator = fm.enumerator(atPath: dir) {
            while let fn: String = e.nextObject() as? String {
                if let date2: NSDate = (e.fileAttributes?[modDate] as? NSDate), testFilename(fn) && date1.isLessThan(date2) {
                    list.append("\(workPath)/\(fn)")
                }
            }
        }
    }

    func fileList2(list: inout [String], dir: String) {
        if let e: FileManager.DirectoryEnumerator = fm.enumerator(atPath: dir) {
            while let fn: String = e.nextObject() as? String {
                if testFilename(fn) {
                    list.append("\(workPath)/\(fn)")
                }
            }
        }
    }

    if fm.fileExists(atPath: logFile), let attrs: [FileAttributeKey: Any] = try? fm.attributesOfItem(atPath: logFile), let date: NSDate = attrs[modDate] as? NSDate {
        fileList1(list: &list, dir: workPath, date: date)
    }
    else {
        fileList2(list: &list, dir: workPath)
    }

    for fn: String in list {
        print("Processing File: \(fn)")
    }

    return list
}

//==========================================================================================================================================
///
///
/// - Parameter pattern:
/// - Returns:
/// - Throws:
///
func regexML(pattern: String) throws -> NSRegularExpression {
    try NSRegularExpression(pattern: pattern, options: [ NSRegularExpression.Options.anchorsMatchLines ])
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
    try processDocument(filenames: [ filename ], findsAndReplacements: findsAndReplacements, lineLength: lineLength)[0]
}

//==========================================================================================================================================
///
///
/// - Parameters:
///   - path:
///   - matchAndReplace:
///   - lineLength:
/// - Throws: `DocFixerErrors.FileNotFound(description:)` if the file was not found or could not be loaded.
///
public func docFixer(path: String, matchAndReplace: [RegexRepl] = [], lineLength: Int = 132) throws {
    let logFile:  String          = "./runlog.txt"
    let encoding: String.Encoding = String.Encoding.utf8
    let list:     [String]        = getFileList(path: path, logFile: logFile)
    let results:  [String]        = try processDocument(filenames: list, findsAndReplacements: matchAndReplace, lineLength: lineLength)

    for (i, str): (Int, String) in results.enumerated() { try str.write(toFile: list[i], atomically: true, encoding: encoding) }
    try "\(NSDate())".write(toFile: logFile, atomically: true, encoding: encoding)
}
