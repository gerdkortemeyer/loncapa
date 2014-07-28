#!/usr/bin/perl

use strict;

while (my $line = <>) {
  $line =~ s/<font([^>]*)\/>/<emptyfont\1\/>/g;
  $line =~ s/<font([^>]*>[^<]*)<\/font>/<inlinefont\1<\/inlinefont>/g;
  $line =~ s/<font/<blockfont/g; # might actually be inline if it encloses inline elements
  $line =~ s/<\/font/<\/blockfont/g;
  print $line;
}
