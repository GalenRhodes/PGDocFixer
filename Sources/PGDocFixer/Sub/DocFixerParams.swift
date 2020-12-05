/************************************************************************//**
 *     PROJECT: PGDocFixer
 *    FILENAME: DocFixerParams.swift
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

struct DocFixerParams {
    var paths:        [String]        = []
    var project:      String!         = nil
    var remoteHost:   String?         = nil
    var remoteUser:   String?         = nil
    var remotePath:   String?         = nil
    var logFile:      String          = "./docs/index.html"
    var archive:      String          = "./DocumentArchive.tar"
    var generator:    DocGenerator    = .Jazzy()
    var docOutput:    CommentDocType  = .Slashes
    var lineLength:   Int             = 180
    let encoding:     String.Encoding = String.Encoding.utf8
    let replacements: [RegexRepl]

    init(args: [String], replacements: [RegexRepl]) throws {
        var idx:      Int  = 1
        var noIgnore: Bool = true

        for s in args {
            print("\(s) ", terminator: "")
        }
        print("")
        print("")

        self.replacements = replacements

        while idx < args.count {
            let p: String = args[idx]
            idx += 1
            if noIgnore && p.hasPrefix("--") {
                switch p {
                    case "--":
                        noIgnore = false
                    case "--project":
                        if idx < args.count {
                            project = args[idx]
                            idx += 1
                        }
                        else {
                            throw DocFixerErrors.Usage(exitCode: printUsage(exitCode: err("Missing project name value for parameter: \"\(p)\"")))
                        }
                    case "--swift-doc-format":
                        if idx < args.count {
                            let q = args[idx]
                            idx += 1
                            switch q.lowercased() {
                                case "html":
                                    generator = .SwiftDoc(format: .HTML)
                                case "markdown":
                                    generator = .SwiftDoc(format: .MarkDown)
                                default:
                                    throw DocFixerErrors.Usage(exitCode: printUsage(exitCode: err("Expected \"HTML\" or \"Markdown\" but got \"\(q)\" instead.")))
                            }
                        }
                        else {
                            throw DocFixerErrors.Usage(exitCode: printUsage(exitCode: err("Missing value \"HTML\" or \"Markdown\" for parameter: \"\(p)\"")))
                        }
                    case "--jazzy-version":
                        if idx < args.count {
                            generator = .Jazzy(version: args[idx])
                            idx += 1
                        }
                        else {
                            throw DocFixerErrors.Usage(exitCode: printUsage(exitCode: err("Missing version number for parameter: \"\(p)\"")))
                        }
                    case "--remote-host":
                        if idx < args.count {
                            remoteHost = args[idx]
                            idx += 1
                        }
                        else {
                            throw DocFixerErrors.Usage(exitCode: printUsage(exitCode: err("Missing value for parameter: \"\(p)\"")))
                        }
                    case "--remote-user":
                        if idx < args.count {
                            remoteUser = args[idx]
                            idx += 1
                        }
                        else {
                            throw DocFixerErrors.Usage(exitCode: printUsage(exitCode: err("Missing value for parameter: \"\(p)\"")))
                        }
                    case "--remote-path":
                        if idx < args.count {
                            remotePath = args[idx]
                            idx += 1
                        }
                        else {
                            throw DocFixerErrors.Usage(exitCode: printUsage(exitCode: err("Missing value for parameter: \"\(p)\"")))
                        }
                    case "--log-file":
                        if idx < args.count {
                            logFile = args[idx]
                            idx += 1
                        }
                        else {
                            throw DocFixerErrors.Usage(exitCode: printUsage(exitCode: err("Missing value for parameter: \"\(p)\"")))
                        }
                    case "--archive-file":
                        if idx < args.count {
                            archive = args[idx]
                            idx += 1
                        }
                        else {
                            throw DocFixerErrors.Usage(exitCode: printUsage(exitCode: err("Missing value for parameter: \"\(p)\"")))
                        }
                    case "--comment-type":
                        if idx < args.count {
                            let ct: String = args[idx]
                            idx += 1
                            switch ct {
                                case "slashes": docOutput = .Slashes
                                case "stars": docOutput = .Stars
                                default: throw DocFixerErrors.Usage(exitCode: err("Invalid document comment type: \"\(ct)\""))
                            }
                        }
                        else {
                            throw DocFixerErrors.Usage(exitCode: printUsage(exitCode: err("Missing value for parameter: \"\(p)\"")))
                        }
                    case "--line-length":
                        if idx < args.count {
                            idx += 1
                            if let lineLength = Int(args[idx - 1]) {
                                self.lineLength = lineLength
                            }
                            else {
                                throw DocFixerErrors.Usage(exitCode: printUsage(exitCode: err("Invalid line length: \"\(args[idx - 1])\"")))
                            }
                        }
                        else {
                            throw DocFixerErrors.Usage(exitCode: printUsage(exitCode: err("Missing value for parameter: \"\(p)\"")))
                        }
                    case "--help", "-h":
                        throw DocFixerErrors.Usage(exitCode: printUsage())
                    default:
                        throw DocFixerErrors.Usage(exitCode: printUsage())
                }
            }
            else {
                paths.append(p)
            }
        }

        guard paths.count > 0 else { throw DocFixerErrors.Usage(exitCode: printUsage(exitCode: err("No path(s) given"))) }

        if project == nil {
            project = paths[0].replacingOccurrences(of: "Sources/", with: "")
            if project.hasSuffix("/") || project.hasSuffix("\\") { project.removeLast(1) }
        }
    }
}
