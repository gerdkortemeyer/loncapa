#!/bin/bash

# this builds dist/LC_math_editor.min.js using google closure compiler with compressjs.
# It must be run in the math_editor directory.

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
        "initEditors": initEditors
    });
}();
%

NEWFILE="c`date +"%d%m%y"`.js"
/bin/sh ./compressjs.sh -strict $tmp
mv "$NEWFILE" ./dist/LC_math_editor.min.js
rm -f $tmp
