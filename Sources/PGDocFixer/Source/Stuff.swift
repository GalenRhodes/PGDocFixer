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

public enum CommentDocType {
    case Slashes
    case Stars
    case StarsEmpty
}

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

func archiveSources(documents: SwiftSourceDocumentList, archive: String = "./DocumentArchive.tar") throws {
    let exec: String   = try which(prg: "tar")
    var args: [String] = [ "cvf", archive ]

    for source: SwiftSourceDocument in documents {
        args.append(source.filename)
    }

    if !execute(exec: exec, args: args) { throw DocFixerErrors.FailedArchive(description: "Failed to archive documents before fixing") }
}

func unarchiveSources(archive: String = "./DocumentArchive.tar") throws {
    let exec: String = try which(prg: "tar")
    if !execute(exec: exec, args: [ "xvf", archive ]) { throw DocFixerErrors.FailedArchive(description: "Failed to unarchive documents after error.") }

    do { try FileManager.default.removeItem(at: URL(fileURLWithPath: archive)) }
    catch let e { print("\(e)") }
}

func execute(exec: String, args: [String], stderr: inout String, stdout: inout String) -> Bool {
    stderr = ""
    stdout = ""

    let proc: Process = Process()
    proc.executableURL = URL(fileURLWithPath: exec)
    proc.arguments = args
    proc.standardError = Pipe()
    proc.standardOutput = Pipe()

    do {
        try proc.run()
    }
    catch let e {
        stderr = "\(e)"
        return false
    }

    proc.waitUntilExit()

    stderr = String(data: (proc.standardError! as! Pipe).fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8) ?? ""
    stdout = String(data: (proc.standardOutput! as! Pipe).fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8) ?? ""

    return (proc.terminationStatus == 0)
}

func execute(exec: String, args: [String]) -> Bool {
    let proc: Process = Process()
    proc.executableURL = URL(fileURLWithPath: exec)
    proc.arguments = args
    proc.standardError = FileHandle.standardError
    proc.standardOutput = FileHandle.standardOutput

    do {
        try proc.run()
    }
    catch let e {
        try? "\(e)".write(toFile: "/dev/stderr", atomically: false, encoding: String.Encoding.utf8)
        return false
    }

    proc.waitUntilExit()

    return (proc.terminationStatus == 0)
}

func dumpOutput(stdout: String, stderr: String) {
    print(stdout)
    try? stderr.write(toFile: "/dev/stderr", atomically: false, encoding: String.Encoding.utf8)
}

func which(prg: String) throws -> String {
    var stdout: String = ""
    var stderr: String = ""
    if !execute(exec: "/bin/bash", args: [ "-c", "which \(prg)" ], stderr: &stderr, stdout: &stdout) { throw DocFixerErrors.FailedProc(description: "Failed to locate \"\(prg)\": \(stderr)") }
    return stdout.trimmed
}

func executeJazzy() throws {
    let jazzy: String = try which(prg: "jazzy")
    print("Executing: \(jazzy)")
    guard execute(exec: jazzy, args: []) else { throw DocFixerErrors.FailedProc(description: "Failed to execute Jazzy") }
}

public func docFixer(path: String,
                     matchAndReplace: [RegexRepl] = [],
                     encoding: String.Encoding = String.Encoding.utf8,
                     logFile: String = "./docs/index.html",
                     archive: String = "./DocumentArchive.tar",
                     docOutput: CommentDocType = .Slashes,
                     lineLength: Int = 132) throws {
    let list: [String] = getFileList(path: path, logFile: logFile)

    if list.count > 0 {
        var documents: SwiftSourceDocumentList = []

        for filename: String in list {
            documents.append(try SwiftSourceDocument(filename: filename))
        }

        try archiveSources(documents: documents)

        do {
            let docFixer: PGDocFixer = PGDocFixer(findAndReplace: matchAndReplace, docOutput: docOutput, lineLength: lineLength)

            for document: SwiftSourceDocument in documents {
                document.fixDocComments(fixer: docFixer)
                try document.save()
            }

            try executeJazzy()

            for document: SwiftSourceDocument in documents {
                document.convertCommentDocs(to: docOutput, lineLength: lineLength)
                try document.save()
            }
        }
        catch let e as DocFixerErrors {
            try unarchiveSources()
            throw e
        }
        catch let e {
            try unarchiveSources()
            throw DocFixerErrors.UnknownError(description: "\(e)")
        }

        // try? "\(NSDate())\n".write(toFile: logFile, atomically: true, encoding: encoding)
        try? FileManager.default.removeItem(at: URL(fileURLWithPath: archive))
    }
}
