/************************************************************************//**
 *     PROJECT: PGDocFixer
 *    FILENAME: Functions.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/14/20
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

public func doDocFixer(args: [String], replacements: [RegexRepl]) -> Int {
    var params:   DocFixerParams = DocFixerParams(replacements: replacements)
    var idx:      Int            = 1
    var noIgnore: Bool           = true

    while idx < args.count {
        let p: String = args[idx]
        idx += 1
        if noIgnore && p.hasPrefix("--") {
            switch p {
                case "--":
                    noIgnore = false
                case "--jazzy-version":
                    if idx < args.count {
                        params.jazzyVersion = "_\(args[idx])_"
                        idx += 1
                    }
                    else {
                        return printUsage(exitCode: err("Missing value for parameter: \"\(p)\""))
                    }
                case "--remote-host":
                    if idx < args.count {
                        params.remoteHost = args[idx]
                        idx += 1
                    }
                    else {
                        return printUsage(exitCode: err("Missing value for parameter: \"\(p)\""))
                    }
                case "--remote-user":
                    if idx < args.count {
                        params.remoteUser = args[idx]
                        idx += 1
                    }
                    else {
                        return printUsage(exitCode: err("Missing value for parameter: \"\(p)\""))
                    }
                case "--remote-path":
                    if idx < args.count {
                        params.remotePath = args[idx]
                        idx += 1
                    }
                    else {
                        return printUsage(exitCode: err("Missing value for parameter: \"\(p)\""))
                    }
                case "--log-file":
                    if idx < args.count {
                        params.logFile = args[idx]
                        idx += 1
                    }
                    else {
                        return printUsage(exitCode: err("Missing value for parameter: \"\(p)\""))
                    }
                case "--archive-file":
                    if idx < args.count {
                        params.archive = args[idx]
                        idx += 1
                    }
                    else {
                        return printUsage(exitCode: err("Missing value for parameter: \"\(p)\""))
                    }
                case "--comment-type":
                    if idx < args.count {
                        let ct: String = args[idx]
                        idx += 1
                        switch ct {
                            case "slashes": params.docOutput = .Slashes
                            case "stars": params.docOutput = .Stars
                            default: return err("Invalid document comment type: \"\(ct)\"")
                        }
                    }
                    else {
                        return printUsage(exitCode: err("Missing value for parameter: \"\(p)\""))
                    }
                case "--line-length":
                    if idx < args.count {
                        idx += 1
                        if let lineLength = Int(args[idx - 1]) {
                            params.lineLength = lineLength
                        }
                        else {
                            return printUsage(exitCode: err("Invalid line length: \"\(args[idx - 1])\""))
                        }
                    }
                    else {
                        return printUsage(exitCode: err("Missing value for parameter: \"\(p)\""))
                    }
                case "--help", "-h":
                    return printUsage()
                default:
                    return printUsage()
            }
        }
        else {
            params.paths.append(p)
        }
    }

    if params.paths.count == 0 { return printUsage(exitCode: err("No path(s) given")) }

    do {
        let docFixer:  PGDocFixer              = PGDocFixer(findAndReplace: params.replacements, docOutput: params.docOutput, lineLength: params.lineLength)
        let documents: SwiftSourceDocumentList = try loadDocuments(params: params)

        try archiveSources(documents, params)

        do {
            for document: SwiftSourceDocument in documents {
                document.fixDocComments(fixer: docFixer)
                try document.save()
            }

            try executeJazzy(params: params)

            for document: SwiftSourceDocument in documents {
                document.convertCommentDocs(to: params.docOutput, lineLength: params.lineLength)
                try document.save()
            }

            try? FileManager.default.removeItem(at: URL(fileURLWithPath: params.archive))
        }
        catch let e {
            try unarchiveSources(params)
            return err("\(e)")
        }
        try executeRsync(params: params)

        return 0
    }
    catch let error {
        return err("\(error)")
    }
}
