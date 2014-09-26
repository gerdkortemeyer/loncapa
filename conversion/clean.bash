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

prexmltmp=$(mktemp)
perl $MY_HOME/pre_xml.pl "$pathname" >"$prexmltmp"
if [ $? -ne 0 ]; then
  echo "pre_xml error for $pathname"
  rm -f "$prexmltmp"
  exit
fi
postxmltmp=$(mktemp)
cat "$prexmltmp" | perl $MY_HOME/html_to_xml.pl >"$postxmltmp"
if [ $? -eq 2 ]; then
  echo "html_to_xml error for $pathname"
  rm -f "$prexmltmp" "$postxmltmp"
  exit
fi
cp "$prexmltmp" /tmp/prexml.txt
cp "$postxmltmp" /tmp/postxml.txt
cat "$postxmltmp" | perl $MY_HOME/post_xml.pl > "$newpath"
if [ $? -ne 0 ]; then
  echo "post_xml error for $pathname"
  rm -f "$prexmltmp" "$postxmltmp"
  exit
fi

# cleanup
rm -f "$prexmltmp" "$postxmltmp"
