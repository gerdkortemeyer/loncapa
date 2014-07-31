#!/bin/bash

pathname="$1"
dir=$(dirname "$pathname")
filename=$(basename "$pathname")
if [[ "$filename" == *.* ]]; then
  ext=".${filename##*.}"
else
  ext=""
fi
namenoext="${filename%.*}"
newpath="$dir/${namenoext}_clean$ext"

perl pre_tidy.pl "$pathname" >/tmp/pretidy.txt
tidy -config /tmp/tidycfg.txt /tmp/pretidy.txt | perl post_tidy.pl > "$newpath"

