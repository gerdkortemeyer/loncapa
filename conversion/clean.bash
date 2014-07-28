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

cat "$pathname" | perl pre_tidy.pl | tidy -config tidycfg.txt | perl post_tidy.pl > "$newpath"
