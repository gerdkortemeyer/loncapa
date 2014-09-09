#!/bin/bash

# link resolution - $0 can be a symbolic link
PRG="$0"
progname=`basename "$0"`
while [ -h "$PRG" ] ; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`"/$link"
  fi
done
MY_HOME=`dirname "$PRG"`
# absolute path
MY_HOME=`cd "$MY_HOME" && pwd`

# create a name for the clean file
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

pretidytmp=$(mktemp)
tidycfg=$(mktemp)
perl $MY_HOME/pre_tidy.pl "$pathname" "$tidycfg" >"$pretidytmp"
if [ $? -ne 0 ]; then
  echo "pre_tidy error for $pathname"
  rm -f "$pretidytmp" "$tidycfg"
  exit
fi
posttidytmp=$(mktemp)
tidy -config "$tidycfg" -o "$posttidytmp" "$pretidytmp"
if [ $? -eq 2 ]; then
  echo "tidy error for $pathname"
  rm -f "$pretidytmp" "$tidycfg" "$posttidytmp"
  exit
fi

cat "$posttidytmp" | sed -e 's/ xmlns="http:\/\/www\.w3\.org\/1999\/xhtml"//' | perl $MY_HOME/post_tidy.pl > "$newpath"
if [ $? -ne 0 ]; then
  echo "post_tidy error for $pathname"
  rm -f "$pretidytmp" "$tidycfg" "$posttidytmp"
  exit
fi

# cleanup
rm -f "$pretidytmp" "$tidycfg" "$posttidytmp"
