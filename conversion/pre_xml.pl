#!/usr/bin/perl

use strict;
use utf8;

use Encode;
use Encode::Byte;
use Encode::Guess;


# list of elements inside which < and > might not be turned into entities
# unfortunately, answer can sometimes contain the elements vector and value...
my @cdata_elements = ('script', 'answer', 'm');


my $lines = guess_encoding_and_read($ARGV[0]);

my $tidycfg = $ARGV[1];

binmode(STDOUT, ":utf8");

fix_cdata_elements($lines);

fix_html_entities($lines);

foreach my $line (@{$lines}) {
  print $line;
}



##
# Tries to guess the character encoding, and returns the lines as decoded text.
# Requires Encode::Byte.
##
sub guess_encoding_and_read {
  my ($fn) = @_;
  local $/ = undef;
  open(my $fh, "<", $fn) or die "cannot read $fn: $!";
  binmode $fh;
  my $data = <$fh>; # we need to read the whole file to test if font is a block or inline element
  # NOTE: this list is too ambigous, Encode::Guess refuses to even try a guess
  #Encode::Guess->set_suspects(qw/ascii UTF-8 iso-8859-1 MacRoman cp1252/);
  my $decoder = Encode::Guess->guess($data); # ascii, utf8 and UTF-16/32 with BOM
  my $decoded;
  if (ref($decoder)) {
    $decoded = $decoder->decode($data);
  } else {
    print STDERR "Warning: encoding is not UTF-8 for $fn";
    # NOTE: cp1252 is identical to iso-8859-1 but with additionnal characters in range 128-159
    # instead of control codes. We can assume that these control codes are not used, so there
    # is no need to test for iso-8859-1.
    # The main problem here is to distinguish between cp1252 and MacRoman.
    # see http://www.alanwood.net/demos/charsetdiffs.html#f
    my $decoded_windows = decode('cp1252', $data);
    my $decoded_mac = decode('MacRoman', $data);
    # try to use frequent non-ASCII characters to distinguish the encodings (mostly German, Spanish, Portuguese)
    my $score_windows = $decoded_windows =~ tr/ßáàäâãçéèêëíñóöôõúüÄÉÑÖÜ¿¡’“”//;
    my $score_mac = $decoded_mac =~ tr/ßáàäâãçéèêëíñóöôõúüÄÉÑÖÜ¿¡’“”//;
    if ($score_windows >= $score_mac) {
      $decoded = $decoded_windows;
      print STDERR "; guess=cp1252 ($score_windows cp1252 >= $score_mac MacRoman)\n";
    } else {
      print STDERR "; guess=MacRoman ($score_mac MacRoman > $score_windows cp1252)\n";
      $decoded = $decoded_mac;
    }
  }
  my @lines = split(/^/m, $decoded);
  return \@lines;
}


##
# Replaces < and > characters by &lt; and &gt; in cdata elements (listed in @cdata_elements).
# EXCEPT for answer when it's inside numericalresponse or formularesponse.
# @param {Array<string>} lines
##
sub fix_cdata_elements {
  my ($lines) = @_;
  my $i = 0;
  my $j = 0;
  my $tag = '';
  my $type;
  my $in_numericalresponse = 0;
  my $in_formularesponse = 0;
  ($tag, $type, $i, $j) = next_tag($lines, $i, $j);
  while ($tag ne '') {
    if ($tag eq 'numericalresponse') {
      if ($type eq 'start') {
        $in_numericalresponse = 1;
      } else {
        $in_numericalresponse = 0;
      }
    } elsif ($tag eq 'formularesponse') {
      if ($type eq 'start') {
        $in_formularesponse = 1;
      } else {
        $in_formularesponse = 0;
      }
    }
    if ($type eq 'start' && in_array_ignore_case(\@cdata_elements, $tag) &&
        ($tag ne 'answer' || (!$in_numericalresponse && !$in_formularesponse))) {
      my $cde = $tag;
      my $line = $lines->[$i];
      $j = index($line, '>', $j+1) + 1;
      my $stop = 0;
      while (!$stop && $i < scalar(@{$lines})) {
        my $indinf = index($line, '<', $j);
        if ($indinf != -1 && index($line, '<![CDATA[', $indinf) == $indinf) {
          $i++;
          $line = $lines->[$i];
          $j = 0;
          last;
        }
        my $indsup = index($line, '>', $j);
        if ($indinf != -1 && $indsup != -1 && $indinf < $indsup) {
          my $test = substr($line, $indinf + 1, $indsup - ($indinf + 1));
          $test =~ s/^\s+|\s+$//g ;
          if ($test eq '/'.$cde) {
            $stop = 1;
            $j = $indsup + 1;
          } elsif ($test =~ /^[a-zA-Z\/]$/) {
            $j = $indsup + 1;
          } else {
            $line = substr($line, 0, $indinf).'&lt;'.substr($line, $indinf+1);
            $lines->[$i] = $line;
          }
        } elsif ($indinf != -1 && $indsup == -1) {
          $line = substr($line, 0, $indinf).'&lt;'.substr($line, $indinf+1);
          $lines->[$i] = $line;
        } elsif ($indsup != -1 && ($indinf == -1 || $indsup < $indinf)) {
          $line = substr($line, 0, $indsup).'&gt;'.substr($line, $indsup+1);
          $lines->[$i] = $line;
        } else {
          $i++;
          $line = $lines->[$i];
          $j = 0;
        }
      }
    }
    $j++;
    ($tag, $type, $i, $j) = next_tag($lines, $i, $j);
  }
}


##
# Replaces HTML entities (they are not XML unless a DTD is used, which is no longer recommanded for XHTML).
# @param {Array<string>} lines
##
sub fix_html_entities {
  my ($lines) = @_;
  foreach my $line (@{$lines}) {
    $line =~ s/\&nbsp;/&#xA0;/g;
  }
}


##
# Returns information about the next tag, starting at line number and char number.
# Assumes the markup is well-formed and there is no CDATA,
# which is not always true (like inside script), so results might be wrong sometimes.
# It is however useful to avoid unnecessary changes in the document (using a parser to
# do read/write for the whole document would mess up non well-formed documents).
# @param {Array<string>} lines
# @param {int} line_number - line number to start at
# @param {int} char_number - char number to start at on the line
# @returns (tag, type, line_number, char_number)
##
sub next_tag {
  my ($lines, $i, $j ) = @_;
  my $i2 = $i;
  my $j2 = $j;
  while ($i2 < scalar(@{$lines})) {
    my $line = $lines->[$i2];
    $j2 = index($line, '<', $j2);
    #TODO: handle comments
    while ($j2 != -1) {
      my $ind_slash = index($line, '/', $j2);
      my $ind_sup = index($line, '>', $j2);
      my $ind_space = index($line, ' ', $j2);
      my $type;
      my $tag;
      if ($ind_slash == $j2 + 1 && $ind_sup != -1) {
        $type = 'end';
        $tag = substr($line, $j2 + 2, $ind_sup - ($j2 + 2));
      } elsif ($ind_slash != -1 && $ind_sup != -1 && $ind_slash == $ind_sup - 1) {
        $type = 'empty';
        if ($ind_space != -1 && $ind_space < $ind_sup) {
          $tag = substr($line, $j2 + 1, $ind_space - ($j2 + 1));
        } else {
          $tag = substr($line, $j2 + 1, $ind_slash - ($j2 + 1));
        }
      } elsif ($ind_sup != -1) {
        $type = 'start';
        if ($ind_space != -1 && $ind_space < $ind_sup) {
          $tag = substr($line, $j2 + 1, $ind_space - ($j2 + 1));
        } else {
          $tag = substr($line, $j2 + 1, $ind_sup - ($j2 + 1));
        }
      } else {
        $tag = ''
      }
      if ($tag ne '') {
        return ($tag, $type, $i2, $j2);
      }
      $j2 = index($line, '<', $j2 + 1);
    }
    $i2++;
    $j2 = 0;
  }
  return ('', '', 0, 0);
}

##
# Tests if a string is in an array, ignoring case
##
sub in_array_ignore_case {
  my ($array, $value) = @_;
  my $lcvalue = lc($value);
  foreach my $v (@{$array}) {
    if (lc($v) eq $lcvalue) {
      return 1;
    }
  }
  return 0;
}

