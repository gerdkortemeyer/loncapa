#!/bin/bash

# this builds dist/LC_math_editor.min.js using google closure compiler.
# It must be run in the math_editor directory.

cd "$(dirname "$0")"
mkdir -p dist
tmp=$(mktemp)
cat <<% >$tmp
"use strict";
var LCMATH = function () {
%
cat src/*.js >>$tmp
cat <<% >>$tmp
    return({
        "Definitions": Definitions,
        "ENode": ENode,
        "Operator": Operator,
        "ParseException": ParseException,
        "Parser": Parser,
        "initEditors": initEditors,
        "updateMathSpanAndDiv": updateMathSpanAndDiv
    });
}();
%

# use the local application if Java is available
if hash java 2>/dev/null; then
    java -jar lib/compiler.jar --language_in=ECMASCRIPT5_STRICT --compilation_level=SIMPLE_OPTIMIZATIONS $tmp >dist/LC_math_editor.min.js
    exit 0
fi

# otherwise use the web service with compressjs.sh
NEWFILE="c`date +"%d%m%y"`.js"
/bin/sh ./compressjs.sh -strict $tmp
mv "$NEWFILE" ./dist/LC_math_editor.min.js
rm -f $tmp
