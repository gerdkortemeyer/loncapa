#!/bin/sh
# NOTE: dart2js is in dart-sdk/bin, which should be on the PATH
dart2js --minify --out=loncapa_daxe.min.dart.js web/loncapa_daxe.dart
dart2js --output-type=dart --minify --out=loncapa_daxe.min.dart web/loncapa_daxe.dart
rm *.js.map *.deps
