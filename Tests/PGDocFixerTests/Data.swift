/************************************************************************//**
 *     PROJECT: PGDocFixer
 *    FILENAME: Data.swift
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
import PGDocFixer

let OBJECTS:    String      = "Attr|CDATASection|Comment|DocumentType|DocumentFragment|Document(?! Object Model)|Element|EntityReference|Entity|Node|Notation|ProcessingInstruction|Text|CharacterData"
let NPW:        String      = "(?<!\\w)"
let NFW:        String      = "(?!\\w)"

//@f:0
let SIMPLEONES: [RegexRepl] = [
    RegexRepl(pattern: "\(NPW)(ATTRIBUTE_NODE)\(NFW)",                                   repl: "`PGDOMNodeType.Attribute`"),
    RegexRepl(pattern: "\(NPW)(CDATA_SECTION_NODE)\(NFW)",                               repl: "`PGDOMNodeType.CDataSection`"),
    RegexRepl(pattern: "\(NPW)(COMMENT_NODE)\(NFW)",                                     repl: "`PGDOMNodeType.Comment`"),
    RegexRepl(pattern: "\(NPW)(DOCUMENT_FRAGMENT_NODE)\(NFW)",                           repl: "`PGDOMNodeType.DocumentFragment`"),
    RegexRepl(pattern: "\(NPW)(DOCUMENT_NODE)\(NFW)",                                    repl: "`PGDOMNodeType.Document`"),
    RegexRepl(pattern: "\(NPW)(DOCUMENT_TYPE_NODE)\(NFW)",                               repl: "`PGDOMNodeType.DocumentType`"),
    RegexRepl(pattern: "\(NPW)(ELEMENT_NODE)\(NFW)",                                     repl: "`PGDOMNodeType.Element`"),
    RegexRepl(pattern: "\(NPW)(ENTITY_NODE)\(NFW)",                                      repl: "`PGDOMNodeType.Entity`"),
    RegexRepl(pattern: "\(NPW)(ENTITY_REFERENCE_NODE)\(NFW)",                            repl: "`PGDOMNodeType.EntityReference`"),
    RegexRepl(pattern: "\(NPW)(NOTATION_NODE)\(NFW)",                                    repl: "`PGDOMNodeType.Notation`"),
    RegexRepl(pattern: "\(NPW)(PROCESSING_INSTRUCTION_NODE)\(NFW)",                      repl: "`PGDOMNodeType.ProcessingInstruction`"),
    RegexRepl(pattern: "\(NPW)(TEXT_NODE)\(NFW)",                                        repl: "`PGDOMNodeType.Text`"),
    RegexRepl(pattern: "\(NPW)(DOMSTRING_SIZE_ERR)\(NFW)",                               repl: "`PGDOMError.DOMStringSizeError`"),
    RegexRepl(pattern: "\(NPW)(HIERARCHY_REQUEST_ERR)\(NFW)",                            repl: "`PGDOMError.HierarchyRequestError`"),
    RegexRepl(pattern: "\(NPW)(INDEX_SIZE_ERR)\(NFW)",                                   repl: "`PGDOMError.IndexSizeError`"),
    RegexRepl(pattern: "\(NPW)(INUSE_ATTRIBUTE_ERR)\(NFW)",                              repl: "`PGDOMError.InuseAttributeError`"),
    RegexRepl(pattern: "\(NPW)(INVALID_ACCESS_ERR)\(NFW)",                               repl: "`PGDOMError.InvalidAccessError`"),
    RegexRepl(pattern: "\(NPW)(INVALID_CHARACTER_ERR)\(NFW)",                            repl: "`PGDOMError.InvalidCharacterError`"),
    RegexRepl(pattern: "\(NPW)(INVALID_MODIFICATION_ERR)\(NFW)",                         repl: "`PGDOMError.InvalidModificationError`"),
    RegexRepl(pattern: "\(NPW)(INVALID_STATE_ERR)\(NFW)",                                repl: "`PGDOMError.InvalidStateError`"),
    RegexRepl(pattern: "\(NPW)(NAMESPACE_ERR)\(NFW)",                                    repl: "`PGDOMError.NamespaceError`"),
    RegexRepl(pattern: "\(NPW)(NO_DATA_ALLOWED_ERR)\(NFW)",                              repl: "`PGDOMError.NoDataAllowedError`"),
    RegexRepl(pattern: "\(NPW)(NO_MODIFICATION_ALLOWED_ERR)\(NFW)",                      repl: "`PGDOMError.NoModificationAllowedError`"),
    RegexRepl(pattern: "\(NPW)(NOT_FOUND_ERR)\(NFW)",                                    repl: "`PGDOMError.NotFoundError`"),
    RegexRepl(pattern: "\(NPW)(NOT_SUPPORTED_ERR)\(NFW)",                                repl: "`PGDOMError.NotSupportedError`"),
    RegexRepl(pattern: "\(NPW)(SYNTAX_ERR)\(NFW)",                                       repl: "`PGDOMError.SyntaxError`"),
    RegexRepl(pattern: "\(NPW)(TYPE_MISMATCH_ERR)\(NFW)",                                repl: "`PGDOMError.TypeMismatchError`"),
    RegexRepl(pattern: "\(NPW)(VALIDATION_ERR)\(NFW)",                                   repl: "`PGDOMError.ValidationError`"),
    RegexRepl(pattern: "\(NPW)(WRONG_DOCUMENT_ERR)\(NFW)",                               repl: "`PGDOMError.WrongDocumentError`"),
    RegexRepl(pattern: "(?<!\\w|\\- |\\.)(\(OBJECTS))\(NFW)((?:\\.\\w+)*(?:\\(\\))?)",   repl: "`PGDOM$1$2`"),
]
//@f:1

