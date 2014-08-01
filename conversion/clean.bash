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


perl $MY_HOME/pre_tidy.pl "$pathname" >/tmp/pretidy.txt
if [ $? -ne 0 ]; then
  echo "Error for $pathname\n"
  exit
fi
# warning: using constant temp file names here prevents running several instances at the same time
tidy -config /tmp/tidycfg.txt /tmp/pretidy.txt | perl $MY_HOME/post_tidy.pl > "$newpath"
if [ $? -ne 0 ]; then
  echo "Error for $pathname\n"
  exit
fi

