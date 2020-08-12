#!/usr/bin/env bash

xcodebuild -project PGDocFixer.xcodeproj -scheme PGDocFixer -configuration Release clean || exit $?
xcodebuild -project PGDocFixer.xcodeproj -scheme PGDocFixer -configuration Release DSTROOT=${HOME} SKIP_INSTALL=No install || exit $?

#rsync -av --delete-after ./build/Release/PGDocFixer.framework ~/Library/Frameworks/       || exit $?
#rsync -av --delete-after ./build/Release/PGDocFixer.framework.dSYM ~/Library/Frameworks/  || exit $?

exit 0
