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
    do {
        let params: DocFixerParams = try DocFixerParams(args: args, replacements: replacements)

        let docFixer:  PGDocFixer              = PGDocFixer(findAndReplace: params.replacements, docOutput: params.docOutput, lineLength: params.lineLength)
        let documents: SwiftSourceDocumentList = try loadDocuments(params: params)

        try archiveSources(documents, params)

        do {
            for document: SwiftSourceDocument in documents {
                document.fixDocComments(fixer: docFixer)
                try document.save()
            }

            switch params.generator {
                case .Jazzy(version: let version):
                    try executeJazzy(version: version)
                case .SwiftDoc(format: let format):
                    try executeSwiftDoc(format: format, project: "", dirs: params.paths)
            }

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
