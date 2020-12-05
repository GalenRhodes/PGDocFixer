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

/*===============================================================================================================================*/
/// Get all of the Swift source files under the given directory `workPath`. Each file must be older than the file at the given path
/// `logFile`.
///
/// - Parameters:
///   - workPath2:
///   - logFile:
///
/// - Returns:
///
func getFileList(path: String, logFile: String) -> [String] {
    var list:       [String]         = []
    let fm:         FileManager      = FileManager.default
    let modDate:    FileAttributeKey = FileAttributeKey.modificationDate
    let searchPath: String           = fixFilename(filename: path)

    func testFilename(_ fileName: String) -> Bool {
        (fileName.hasSuffix(".swift") && !fileName.hasPrefix("."))
    }

    func fileList1(list: inout [String], dir: String, date date1: NSDate) {
        if let e: FileManager.DirectoryEnumerator = fm.enumerator(atPath: dir) {
            while let fn: String = e.nextObject() as? String {
                if let date2: NSDate = (e.fileAttributes?[modDate] as? NSDate), testFilename(fn) && date1.isLessThan(date2) {
                    list.append("\(searchPath)/\(fn)")
                }
            }
        }
    }

    func fileList2(list: inout [String], dir: String) {
        if let e: FileManager.DirectoryEnumerator = fm.enumerator(atPath: dir) {
            while let fn: String = e.nextObject() as? String {
                if testFilename(fn) {
                    list.append("\(searchPath)/\(fn)")
                }
            }
        }
    }

    if fm.fileExists(atPath: logFile), let attrs: [FileAttributeKey: Any] = try? fm.attributesOfItem(atPath: logFile), let date: NSDate = attrs[modDate] as? NSDate {
        fileList1(list: &list, dir: searchPath, date: date)
    }
    else {
        fileList2(list: &list, dir: searchPath)
    }

    for fn: String in list {
        print("Processing File: \(fn)")
    }

    return list
}

func unURLFilename(_ filename: String) -> String {
    if filename.hasPrefix("file://") {
        let idx: String.Index = filename.index(filename.startIndex, offsetBy: "file://".count)
        return String(filename[idx ..< filename.endIndex])
    }
    return filename
}

func removeLastSlash(_ filename: String) -> String {
    if filename.hasSuffix("/") {
        return String(filename[filename.startIndex ..< filename.index(before: filename.endIndex)])
    }
    return filename
}

func fixFilename(filename: String) -> String {
    if filename == "~" {
        return unURLFilename(removeLastSlash(FileManager.default.homeDirectoryForCurrentUser.absoluteString))
    }
    if filename.hasPrefix("~/") {
        let p: String = FileManager.default.homeDirectoryForCurrentUser.absoluteString
        return "\(removeLastSlash(unURLFilename(p)))/\(filename[filename.index(after: filename.index(after: filename.startIndex)) ..< filename.endIndex])"
    }
    return filename
}

/*===============================================================================================================================*/
/// - Parameter pattern:
/// - Returns:
/// - Throws:
///
func regexML(pattern: String) throws -> NSRegularExpression {
    try NSRegularExpression(pattern: pattern, options: [ NSRegularExpression.Options.anchorsMatchLines ])
}

func archiveSources(_ documents: SwiftSourceDocumentList, _ params: DocFixerParams) throws {
    let exec: String   = try which(prg: "tar")
    var args: [String] = [ "cvf", params.archive ]

    for source: SwiftSourceDocument in documents {
        args.append(source.filename)
    }

    if !execute(exec: exec, args: args) { throw DocFixerErrors.FailedArchive(description: "Failed to archive documents before fixing") }
}

func unarchiveSources(_ params: DocFixerParams) throws {
    let exec: String = try which(prg: "tar")
    if !execute(exec: exec, args: [ "xvf", params.archive ]) { throw DocFixerErrors.FailedArchive(description: "Failed to unarchive documents after error.") }

    do { try FileManager.default.removeItem(at: URL(fileURLWithPath: params.archive)) }
    catch let e { print("\(e)") }
}

func executeRsync(params: DocFixerParams) throws {
    if let rhost: String = params.remoteHost, let rpath: String = params.remotePath {
        let rsync: String   = try which(prg: "rsync")
        var rargs: [String] = [ "-avz", "--delete-after", "docs/" ]

        if let ruser: String = params.remoteUser {
            rargs.append("\(ruser)@\(rhost):\"\(rpath)/\"")
        }
        else {
            rargs.append("\(rhost):\"\(rpath)/\"")
        }

        guard execute(exec: rsync, args: rargs) else { throw DocFixerErrors.FailedProc(description: "Failed to execute rsync") }
    }
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
        print("Executing: \(exec)", terminator: "")
        for a: String in args { print(" \(a)", terminator: "") }
        print("")
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

func executeJazzy(version: String) throws {
    let jazzy:   String   = try which(prg: "jazzy")
    let cparams: [String] = [ "_\(version)_", "--swift-version", "5.3", "--swift-build-tool", "spm" ]
    guard execute(exec: jazzy, args: cparams) else { throw DocFixerErrors.FailedProc(description: "Failed to execute Jazzy") }
}

func executeSwiftDoc(format: SwiftDocFormat, project: String, dirs: [String]) throws {
    let swiftDoc: String   = try which(prg: "swift-doc")
    var cparams:  [String] = [ "generate", "--module-name", project, "--format", format.rawValue, "--base-url", "/\(project)/" ]
    cparams.insert(contentsOf: dirs, at: 1)
    guard execute(exec: swiftDoc, args: cparams) else { throw DocFixerErrors.FailedProc(description: "Failed to execute SwiftDoc") }
}

@inlinable func err(_ msg: String) -> Int {
    print("ERROR: \(msg)", to: &errorLog)
    return 1
}

func loadDocuments(params: DocFixerParams) throws -> SwiftSourceDocumentList {
    var documents: SwiftSourceDocumentList = []

    for path: String in params.paths {
        let list: [String] = getFileList(path: path, logFile: params.logFile)
        for filename: String in list {
            documents.append(try SwiftSourceDocument(filename: filename))
        }
    }
    return documents
}

func printUsage(exitCode: Int = 0) -> Int {
    if exitCode != 0 { print("") }
    //    *--------1---------2---------3---------4---------5---------6---------7---------8---------9---------0
    print("""
          USAGE:

          docFixer [--remote-host <hostname>] [--remote-user <username>]
                   [--remote-path <pathname>] [--log-file <log filename>]
                   [--archive-file <archive filename>] [--comment-type {slashes | stars}]
                   [--line-length <integer number>]
                   [{--jazzy-version <version of jazzy to use>} | {--swift-doc-format {HTML} | {Markdown}}]
                   [--] <pathname> [<pathname> ...]

          Everything after "--" is assumed to be a pathname. That way you can list
          a path that begins with "--".

          If "--remote-host" and "--remote-path" are given then the documentation files
          will be rsync'd to that host at that path. If you give a username with
          "--remote-user" then you will not be asked for a password. You can learn how
          to setup an authorized_keys file here:

               https://www.google.com/search?q=authorized_keys

          DEFAULTS:
          The following are the default values for parameters if they are omitted.

          --log-file         ./docs/index.html
          --archive-file     ./DocumentArchive.tar
          --comment-type     slashes
          --line-length      132
          --jazzy-verion     <the latest installed version>

          """)
    return exitCode
}

func addUrlsToFindAndReplace() -> [RegexRepl] {
    var list: [RegexRepl]         = NORMAL_FIND_REPLACE
    let rx:   NSRegularExpression = try! NSRegularExpression(pattern: "\\.")
    let keys: [String] = URL_REPLACEMENTS.keys.sorted { (s1: String, s2: String) in s1.count > s2.count }

    for name in keys {
        let patt: String = "\(a)\(NSRegularExpression.escapedPattern(for: name))\(b)"

        if let i: Int = URL_REPLACEMENTS[name] {
            let pfx: String = URL_PREFIX[i]
            let sfx: String = rx.stringByReplacingMatches(in: name.lowercased(), withTemplate: "/")
            let rep: String = NSRegularExpression.escapedTemplate(for: "<code>[\(name)](\(pfx)\(sfx)/)</code>")

            list.append(RegexRepl(pattern: patt, repl: rep))
        }
    }

    return list
}
