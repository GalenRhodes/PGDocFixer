#!/usr/bin/env bash

xcodebuild -target PGDocFixer -configuration Release clean build || exit $?

rsync -av --delete-after ./build/Release/PGDocFixer.framework ~/Library/Frameworks/       || exit $?
rsync -av --delete-after ./build/Release/PGDocFixer.framework.dSYM ~/Library/Frameworks/  || exit $?

exit 0
