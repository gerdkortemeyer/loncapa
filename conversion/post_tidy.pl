#!/usr/bin/perl

use strict;

while (my $line = <>) {
  $line =~ s/<emptyfont/<font/g;
  $line =~ s/<inlinefont/<font/g;
  $line =~ s/<\/inlinefont/<font/g;
  $line =~ s/<blockfont/<font/g;
  $line =~ s/<\/blockfont/<font/g;
  print $line;
}
