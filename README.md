# PGDocFixer
This was a quick and dirty project that I threw together to fix up Swift code documentation.  I wanted it
to be configurable on a per-project basis. Documentation is pretty much non-existent as of right now but
if you want to see how it's used then check out the project that I wrote it for: PGSwiftDOM.

In PGSwiftDOM I was, more or less, porting the Java DOM model over to Swift and so I decided to simply
copy their documentation as well to save time on my end. But it needed cleaning up in areas such as changing
"null" to "nil", prefixing class names with "PGDOM" and making sure that lines were wrapped at 132 characters.
That way I could just copy and paste the documentation and not have to do any of the above manually after that.

