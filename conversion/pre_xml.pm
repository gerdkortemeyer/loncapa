#!/usr/bin/perl

package pre_xml;

use strict;
use utf8;

use Encode;
use Encode::Byte;
use Encode::Guess;

# list of elements inside which < and > might not be turned into entities
# unfortunately, answer can sometimes contain the elements vector and value...
my @cdata_elements = ('answer', 'm', 'display', 'parse'); # not script because the HTML parser will handle it


# Reads a LON-CAPA 2 file, guesses the encoding, fixes characters in cdata_elements, fixes HTML entities,
# and returns the converted text.
sub pre_xml {
  my ($filepath) = @_;
  
  my $lines = guess_encoding_and_read($filepath);

  remove_control_characters($lines);
  
  replace_display_web_and_tex($lines);
  
  warning_xmlparse($lines);
  
  fix_cdata_elements($lines);

  fix_html_entities($lines);
  
  fix_missing_quotes($lines);
  
  fix_empty_li($lines);
  
  remove_doctype($lines);
  
  add_root($lines);
  
  return(\join('', @$lines));
}


##
# Tries to guess the character encoding, and returns the lines as decoded text.
# Requires Encode::Byte.
##
sub guess_encoding_and_read {
  my ($fn) = @_;
  no warnings "utf8";
  local $/ = undef;
  open(my $fh, "<", $fn) or die "cannot read $fn: $!";
  binmode $fh;
  my $data = <$fh>; # we need to read the whole file to test if font is a block or inline element
  close $fh;
  
  if (index($data, '<') == -1) {
    die "This file has no markup !";
  }
  
  # try to get a charset from a meta at the beginning of the file
  my $beginning = substr($data, 0, 1024); # to avoid a full match; hopefully we won't cut the charset in half
  if ($beginning =~ /<meta[^>]*charset\s?=\s?([^\n>"';]*)/i) {
    my $meta_charset = $1;
    if ($meta_charset ne '') {
      if ($meta_charset =~ /iso-?8859-?1/i) {
        # usually a lie
        $meta_charset = 'cp1252';
      }
      # now try to decode using that encoding
      my $decoder = guess_encoding($data, ($meta_charset));
      if (ref($decoder)) {
        my $decoded = $decoder->decode($data);
        my @lines = split(/^/m, $decoded);
        return \@lines;
      } else {
        print "Warning: decoding did not work with the charset defined by the meta ($meta_charset)\n";
      }
    }
  }
  
  my $decoded;
  if (length($data) > 0) {
    # NOTE: this list is too ambigous, Encode::Guess refuses to even try a guess
    #Encode::Guess->set_suspects(qw/ascii UTF-8 iso-8859-1 MacRoman cp1252/);
    # by default Encode::Guess uses ascii, utf8 and UTF-16/32 with BOM
    my $decoder = Encode::Guess->guess($data);
    if (ref($decoder)) {
      $decoded = $decoder->decode($data);
      # NOTE: this seems to accept binary files sometimes (conversion will fail later because it is not really UTF-8)
    } else {
      print "Warning: encoding is not UTF-8 for $fn";
      
      # let's try iso-2022-jp first
      $decoder = Encode::Guess->guess($data, 'iso-2022-jp');
      if (ref($decoder)) {
        $decoded = $decoder->decode($data);
        print "; using iso-2022-jp\n";
      } else {
        # NOTE: cp1252 is identical to iso-8859-1 but with additionnal characters in range 128-159
        # instead of control codes. We can assume that these control codes are not used, so there
        # is no need to test for iso-8859-1.
        # The main problem here is to distinguish between cp1252 and MacRoman.
        # see http://www.alanwood.net/demos/charsetdiffs.html#f
        my $decoded_windows = decode('cp1252', $data);
        my $decoded_mac = decode('MacRoman', $data);
        # try to use frequent non-ASCII characters to distinguish the encodings (languages: mostly German, Spanish, Portuguese)
        # í has been removed because it conflicts with ’ and ’ is more frequent
        # ± has been removed because it is, suprisingly, the same code in both encodings !
        my $score_windows = $decoded_windows =~ tr/ßáàäâãçéèêëñóöôõúüÄÉÑÖÜ¿¡‘’“” °½–—…§//;
        my $score_mac = $decoded_mac =~ tr/ßáàäâãçéèêëñóöôõúüÄÉÑÖÜ¿¡‘’“” °½–—…§//;
        # check newlines too (\r on MacOS < X, \r\n on Windows)
        my $ind_cr = index($data, "\r");
        if ($ind_cr != -1) {
          if (substr($data, $ind_cr + 1, 1) eq "\n") {
            $score_windows++;
          } else {
            $score_mac++;
          }
        }
        if ($score_windows >= $score_mac) {
          $decoded = $decoded_windows;
          print "; guess=cp1252 ($score_windows cp1252 >= $score_mac MacRoman)\n";
        } else {
          print "; guess=MacRoman ($score_mac MacRoman > $score_windows cp1252)\n";
          $decoded = $decoded_mac;
        }
      }
    }
  } else {
    $decoded = '';
  }
  my @lines = split(/^/m, $decoded);
  return \@lines;
}


##
# Removes some control characters
# @param {Array<string>} lines
##
sub remove_control_characters {
  my ($lines) = @_;
  foreach my $line (@{$lines}) {
    $line =~ s/[\x00-\x07\x0B\x0C\x0E-\x1F]//g;
    $line =~ s/&#[0-7];//g;
    $line =~ s/&#1[4-9];//g;
    $line =~ s/&#2[0-9];//g;
  }
}

# replaces <display>&web()</display> and <display>&tex()</display> whenever possible
# (this way we don't have to parse more HTML in post_xml)
# see post_xml->replace_tex_and_web and replace_web_and_tex_subs for explanations
sub replace_display_web_and_tex {
  my ($lines) = @_;
  foreach my $line (@{$lines}) {
    # we are not using /i here to avoid warnings for non-Unicode characters
    $line =~ s/<display>\&web\('[^']*' ?, ?'\s*(\$[^\$']+\$)\s*' ?, ?'[^']*<[iI][mM][gG][^']* ?\/?>[^']*'\)<\/display>/$1/g;
    $line =~ s/<display>\&web\(['"][^'"]*['"] ?, ?['"](?![^'"]*\.[eE][pP][sS])[^'"]*['"] ?, ?['"]([^'"]+)['"]\)<\/display>/$1/g;
    $line =~ s/<display>\&tex\(['"][^'"]*['"] ?, ?['"]([^'"]*<(?![tT][dDrR])[a-zA-Z]+[^'"]*)['"]\)<\/display>/$1/g;
    $line =~ s/<display>\&tex\(['"](\$[^\$'"]+\$)['"] ?, ?['"][^'"]*['"]\)<\/display>/$1/g;
    # added this one which is not in post_xml:
    # removing <display>&tex('\vskip .0[0-9]*in','')</display>
    $line =~ s/<display>\&tex\(['"]\\vskip \.0[0-9]*in['"] ?, ?''\)<\/display>//g;
  }
}

##
# Prints a warning if a line contains '<parse[ >]' or 'xmlparse'
# @param {Array<string>} lines
##
sub warning_xmlparse {
  my ($lines) = @_;
  my $parse_warning = 0;
  my $xmlparse_warning = 0;
  foreach my $line (@{$lines}) {
    if (!$parse_warning && $line =~ /<parse[ >]/) {
      print "Warning: <parse> is used, dynamic content will not be converted\n";
      $parse_warning = 1;
      if ($xmlparse_warning) {
        last;
      }
    }
    if (!$xmlparse_warning && index($line, 'xmlparse') != -1) {
      print "Warning: &xmlparse() is used, dynamic content will not be converted\n";
      $xmlparse_warning = 1;
      if ($parse_warning) {
        last;
      }
    }
  }
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
  my $in_script = 0;
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
    } elsif ($tag eq 'script') {
      if ($type eq 'start') {
        $in_script = 1;
      } else {
        $in_script = 0;
      }
    }
    if ($type eq 'start' && in_array_ignore_case(\@cdata_elements, $tag) && !$in_script &&
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
            $j = $indsup;
          # this is commented because of markup like <display>&web(' ','','<p>')</display>
          #} elsif ($test =~ /^[a-zA-Z\/]$/) {
          #  $j = $indsup + 1;
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
    # html_to_xml is converting named entities before 255 (see HTML parser dtext)
    # Assuming Windows encoding (Unicode entities are not before 160 and are the same between 160 and 255):
    $line =~ s/&#128;|&#x80;/€/g;
    $line =~ s/&#130;|&#x82;/‚/g;
    $line =~ s/&#132;|&#x84;/„/g;
    $line =~ s/&#133;|&#x85;/…/g;
    $line =~ s/&#134;|&#x86;/†/g;
    $line =~ s/&#135;|&#x87;/‡/g;
    $line =~ s/&#136;|&#x88;/ˆ/g;
    $line =~ s/&#137;|&#x89;/‰/g;
    $line =~ s/&#139;|&#x8B;/‹/g;
    $line =~ s/&#145;|&#x91;/‘/g;
    $line =~ s/&#146;|&#x92;/’/g;
    $line =~ s/&#147;|&#x93;/“/g;
    $line =~ s/&#148;|&#x94;/”/g;
    $line =~ s/&#149;|&#x95;/•/g;
    $line =~ s/&#150;|&#x96;/–/g;
    $line =~ s/&#151;|&#x97;/—/g;
    $line =~ s/&#152;|&#x98;/˜/g;
    $line =~ s/&#153;|&#x99;/™/g;
    $line =~ s/&#155;|&#x9B;/›/g;
    $line =~ s/&#156;|&#x9C;/œ/g;
  }
}


# Tries to fix things like <font color="#990000" face="Verdana,>
# without breaking <a b="c>d">
# This is only fixing tags when there is a single tag in a line (it is impossible to fix in the general case).
# Also transforms <a b="c> <d e=" into <a b="c"><d e=" ,
# and (no markup before)<a b="c> (no quote after) into <a b="c"> .
sub fix_missing_quotes {
  my ($lines) = @_;
  foreach my $line (@{$lines}) {
    my $n_inf = $line =~ tr/<//;
    my $n_sup = $line =~ tr/>//;
    if ($n_inf == 1 && $n_sup == 1) {
      my $ind_inf = index($line, '<');
      my $ind_sup = index($line, '>');
      if ($ind_inf != -1 && $ind_sup != -1 && $ind_inf < $ind_sup) {
        my $n_quotes = substr($line, $ind_inf, $ind_sup) =~ tr/"//;
        if ($n_quotes % 2 != 0) {
          # add a quote before > when there is an odd number of quotes inside <>
          $line =~ s/>/">/;
        }
      }
    }
    $line =~ s/(<[a-zA-Z]+ [a-zA-Z]+="[^"<>\s]+)(>\s*<[a-zA-Z]+ [a-zA-Z]+=")/$1"$2/;
    $line =~ s/^([^"<>]*<[a-zA-Z]+ [a-zA-Z]+="[^"<>\s]+)(>[^"]*)$/$1"$2/;
  }
}


# Replaces <li/> by <li> (the end tag will be added in html_to_xml
sub fix_empty_li {
  my ($lines) = @_;
  foreach my $line (@{$lines}) {
    $line =~ s/<li\s?\/>/<li>/;
  }
}


# remove doctypes, without assuming they are at the beginning
sub remove_doctype {
  my ($lines) = @_;
  foreach my $line (@{$lines}) {
    $line =~ s/<!DOCTYPE[^>]*>//;
  }
}


# Adds a <loncapa> root element, enclosing things outside of the problem element.
sub add_root {
  my ($lines) = @_;
  my $line1 = $lines->[0];
  $line1 =~ s/<\?.*\?>//; # remove any PI, it would cause problems later anyway
  $line1 = '<loncapa>'.$line1;
  $lines->[0] = $line1;
  $lines->[scalar(@$lines)-1] = $lines->[scalar(@$lines)-1]."</loncapa>";
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

1;
__END__
