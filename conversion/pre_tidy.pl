#!/usr/bin/perl

use strict;
use utf8;

use File::Basename;
use HTML::TokeParser;
use Env qw(RES_DIR); # path of res directory parent (without the / at the end)
use Encode;
use Encode::Byte;
use Encode::Guess;

my @block_elements = ('answer','foil','image','polygon','rectangle','text','conceptgroup','itemgroup','item','label','data','function','numericalresponse','array','unit','answergroup','formularesponse','functionplotresponse','functionplotruleset','functionplotelements','functionplotcustomrule','stringresponse','essayresponse','externalresponse','hintgroup','hintpart','formulahint','numericalhint','reactionhint','organichint','optionhint','radiobuttonhint','stringhint','customhint','mathhint','imageresponse','foilgroup','datasubmission','customresponse','mathresponse','textfield','hiddensubmission','optionresponse','radiobuttonresponse','rankresponse','matchresponse','organicresponse','reactionresponse','import','script','window','block','library','notsolved','part','postanswerdate','preduedate','problem','problemtype','randomlabel','bgimg','labelgroup','randomlist','solved','while','gnuplot','curve','Task','IntroParagraph','ClosingParagraph','Question','QuestionText','Setup','Instance','InstanceText','Criteria','CriteriaText','GraderNote','languageblock','translated','lang','instructorcomment','dataresponse','togglebox','standalone','comment','drawimage','allow','displayduedate','displaytitle','responseparam','organicstructure','scriptlib','parserlib','drawoptionlist','spline','backgroundplot','plotobject','plotvector','drawvectorsum','functionplotrule','functionplotvectorrule','functionplotvectorsumrule','axis','key','xtics','ytics','title','xlabel','ylabel','hiddenline');

my @block_html = ('html','body','h1','h2','h3','h4','h5','h6','div','p','ul','ol','table','dl','pre','noscript','blockquote','object','applet','embed','map','form','fieldset','iframe');

my @all_block = (@block_elements, @block_html);

my @inline_elements = ('vector','value','location','parameter','textline','display','img','meta','startpartmarker','endpartmarker','startouttext','endouttext','tex','web','windowlink','m','chem','num','parse','algebra','displayweight','displaystudentphoto','inlinefont');

# list of empty elements, which must also appear either in block or inline
my @empty_elements = ('drawoptionlist','location','parameter','spline','backgroundplot','plotobject','plotvector','drawvectorsum','functionplotrule','functionplotvectorrule','functionplotvectorsumrule','textline','displayduedate','displaytitle','organicstructure','responseparam','img','meta','startpartmarker','endpartmarker','allow','startouttext','endouttext','axis','key','xtics','ytics','displayweight','displaystudentphoto','emptyfont');

# list of elements inside which < and > might not be turned into entities
# unfortunately, answer can sometimes contain the elements vector and value...
my @cdata_elements = ('answer', 'm'); # FIXME: script is encoded later by tidy, so it would be encoded twice if it was added here, but not adding it here can also cause problems in pre_tidy...


if (!defined $RES_DIR) {
  die "The environement variable RES_DIR must be defined (path of res directory parent without the / at the end)";
}

my $lines = guess_encoding_and_read($ARGV[0]);

binmode(STDOUT, ":utf8");

fix_cdata_elements($lines);

fix_html_entities($lines);

fix_font($lines);

foreach my $line (@{$lines}) {
  print $line;
}

create_tidycfg();


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
    print STDERR "Warning: encoding is not UTF-8 for $fn\n";
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
    } else {
      $decoded = $decoded_mac;
    }
  }
  my @lines = split(/^/m, $decoded);
  return \@lines;
}


##
# Replaces < and > characters by &lt; and &gt; in cdata elements (listed in @cdata_elements).
# @param {Array<string>} lines
##
sub fix_cdata_elements {
  my ($lines) = @_;
  my $i = 0;
  my $j = 0;
  my $tag = '';
  my $type;
  ($tag, $type, $i, $j) = next_tag($lines, $i, $j);
  while ($tag ne '') {
    if (in_array_ignore_case(\@cdata_elements, $tag)) {
      my $cde = $tag;
      my $line = $lines->[$i];
      $j = index($line, '>', $j+1) + 1;
      my $stop = 0;
      while (!$stop && $i < scalar(@{$lines})) {
        my $indinf = index($line, '<', $j);
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
# Transforms $ARGV[0] into stdout by replacing the font element by either epmtyfont, blockfont or inlinefont.
# @param {Array<string>} lines
#
sub fix_font {
  my ($lines) = @_;
  
  for (my $i=0; $i<scalar(@{$lines}); $i++) {
    my $line = $lines->[$i];
    # replace empty font elements on the line
    $line =~ s/<font([^>]*)\/>/<emptyfont\1\/>/g;
    $line =~ s/<FONT([^>]*)\/>/<emptyfont\1\/>/g;
    # look for the first font start on the line
    my $j = index($line, '<font');
    my $ju = index($line, '<FONT');
    if ($j == -1 || ($ju != -1 && $ju < $j)) {
      $j = $ju;
    }
    while ($j != -1) {
      # check if there is a block element inside font
      my $i2 = $i;
      my $j2 = $j;
      my $tag;
      my $type;
      my $is_block = 0;
      my $depth = 0;
      ($tag, $type, $i2, $j2) = next_tag($lines, $i2, $j2+1);
      while ($tag ne '') {
        if (($tag eq 'font' || $tag eq 'FONT') && $type eq 'end') {
          if ($depth > 0) {
            $depth--;
          } else {
            last;
          }
        } elsif (($tag eq 'font' || $tag eq 'FONT') && $type eq 'start') {
          $depth++;
        } elsif (in_array(\@all_block, $tag)) {
          $is_block = 1;
        }
        ($tag, $type, $i2, $j2) = next_tag($lines, $i2, $j2+1);
      }
      my $newname;
      if ($is_block) {
        $newname = 'blockfont';
      } else {
        $newname = 'inlinefont';
      }
      # change end tag if we found it (otherwise tidy will add it later)
      if ($tag ne '') {
        if ($i2 == $i) {
          $line = substr($line, 0, $j2).'</'.$newname.'>'.substr($line, $j2+7);
        } else {
          $lines->[$i2] = substr($lines->[$i2], 0, $j2).'</'.$newname.'>'.substr($lines->[$i2], $j2+7);
        }
      }
      # change start tag
      $line = substr($line, 0, $j).'<'.$newname.substr($line, $j+5);
      $j++;
      my $j1 = $j;
      $j = index($line, '<font', $j1);
      $ju = index($line, '<FONT', $j1);
      if ($j == -1 || ($ju != -1 && $ju < $j)) {
        $j = $ju;
      }
      $lines->[$i] = $line;
    }
    $lines->[$i] = $line;
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
# Creates the tidy configuration file in /tmp/tidycfg.txt based on sty imports.
##
sub create_tidycfg {
  my @blocks = @block_elements; # updated list of block elements
  my @inlines = @inline_elements; # updated list of inline elements
  my $fn = $ARGV[0];
  my ($name, $path, $suffix) = fileparse($fn);
  my $libs = extract_libs($fn);
  foreach my $sty (@{$libs}) {
    if (substr($sty, 0, 1) eq '/') {
      $sty = $RES_DIR.$sty;
    } else {
      $sty = $path.$sty;
    }
    my $new_elements = parse_sty($sty);
    better_guess($fn, $new_elements);
    my $new_blocks = $new_elements->{'block'};
    my $new_inlines = $new_elements->{'inline'};
    push(@blocks, @{$new_blocks});
    push(@inlines, @{$new_inlines});
  }
  push(@blocks, ('blockfont', 'emptyfont'));
  push(@inlines, 'inlinefont');
  my @empties = @empty_elements;
  push(@empties, 'emptyfont');
  open(my $fh, ">", '/tmp/tidycfg.txt') or die "cannot write in /tmp/tidycfg.txt: $!";
  print $fh "new-blocklevel-tags:";
  print $fh join(',', @blocks);
  print $fh "\n";
  print $fh "new-empty-tags:";
  print $fh join(',', @empties);
  print $fh "\n";
  print $fh "new-inline-tags:";
  print $fh join(',', @inlines);
  print $fh "\n";
  print $fh <<END

new-pre-tags: answer

add-xml-decl: yes

output-xhtml: yes

show-body-only: auto

wrap: 0

newline: LF

indent: auto

show-warnings: no

quiet: yes

char-encoding: utf8

numeric-entities: yes

END
;
  close $fh;
}

##
# Parses the input file to extract the links to .sty files.
##
sub extract_libs {
  my ($fn) = @_;
  my $p = HTML::TokeParser->new($fn);
  $p->empty_element_tags(1);
  my @libs = ();
  my $lib = '';
  my $in_lib = 0;
  while (my $token = $p->get_token) {
    if ($token->[0] eq 'S' && lc($token->[1]) eq 'parserlib') {
      $lib = '';
      $in_lib = 1;
    } elsif ($token->[0] eq 'E' && lc($token->[1]) eq 'parserlib') {
      push(@libs, $lib);
      $in_lib = 0;
    } elsif ($token->[0] eq 'T') {
      $lib .= $token->[1];
    }
  }
  return(\@libs);
}

##
# Parses a sty file and returns lists of block and inline elements for tidy.
# @param {string} fn - the file path
##
sub parse_sty {
  my ($fn) = @_;
  my @blocks = ();
  my @inlines = ();
  my $p = HTML::TokeParser->new($fn);
  if (! $p) {
    die "Error reading $fn\n";
    #return {'block'=>\@blocks, 'inline'=>\@inlines};
  }
  $p->empty_element_tags(1);
  my $in_definetag = 0;
  my $in_render = 0;
  my %newtags = ();
  my $newtag = '';
  my $is_block = 0;
  while (my $token = $p->get_token) {
    if ($token->[0] eq 'S') {
      my $tag = lc($token->[1]);
      if ($tag eq 'definetag') {
        $in_definetag = 1;
        $is_block = 0;
        my $attributes = $token->[2];
        $newtag = $attributes->{'name'};
        if (substr($newtag, 0, 1) eq '/') {
          $newtag = substr($newtag, 1);
        }
      } elsif ($in_definetag && $tag eq 'render') {
        $in_render = 1;
        $is_block = 0;
      } elsif ($in_render) {
        if (in_array_ignore_case(\@all_block, $tag)) {
          $is_block = 1;
        }
      }
    } elsif ($token->[0] eq 'E') {
      my $tag = lc($token->[1]);
      if ($tag eq 'definetag') {
        $in_definetag = 0;
        if (defined $newtags{$newtag}) {
          $newtags{$newtag} = $newtags{$newtag} || $is_block;
        } else {
          $newtags{$newtag} = $is_block;
        }
      } elsif ($in_definetag && $tag eq 'render') {
        $in_render = 0;
      }
    }
  }
  foreach $newtag (keys(%newtags)) {
    if ($newtags{$newtag} == 1) {
      push(@blocks, $newtag);
    } else {
      push(@inlines, $newtag);
    }
  }
  return {'block'=>\@blocks, 'inline'=>\@inlines};
}

##
# Parses the input file and marks as block the elements that contain block elements
# @param {string} fn - the file path
# @param {Hash<string,Array>} new_elements - contains arrays in 'block' and 'inline'
##
sub better_guess {
  my ($fn, $new_elements) = @_;
  my $new_blocks = $new_elements->{'block'};
  my $new_inlines = $new_elements->{'inline'};
  my $p = HTML::TokeParser->new($fn);
  if (! $p) {
    die "Error reading $fn\n";
  }
  $p->empty_element_tags(1);
  my %opencount = ();
  my @change = (); # change these elements from inline to block
  foreach my $tag (@{$new_inlines}) {
    $opencount{$tag} = 0;
  }
  while (my $token = $p->get_token) {
    if ($token->[0] eq 'S') {
      my $tag = $token->[1];
      if (defined $opencount{$tag}) {
        $opencount{$tag}++;
      } else {
        if (in_array_ignore_case(\@all_block, $tag) || in_array_ignore_case($new_blocks, $tag)) {
          foreach my $inline (@{$new_inlines}) {
            if ($opencount{$inline} > 0) {
              if (!in_array(\@change, $inline)) {
                push(@change, $inline);
              }
            }
          }
        }
      }
    } elsif ($token->[0] eq 'E') {
      my $tag = $token->[1];
      if (defined $opencount{$tag}) {
        $opencount{$tag}--;
      }
    }
  }
  foreach my $inline (@change) {
    my $index = 0;
    $index++ until $new_inlines->[$index] eq $inline;
    splice(@{$new_inlines}, $index, 1);
    push(@{$new_blocks}, $inline);
  }
}

##
# Tests if a string is in an array (to avoid Smartmatch warnings with $value ~~ @array)
##
sub in_array {
  my ($array, $value) = @_;
  foreach my $v (@{$array}) {
    if ($v eq $value) {
      return 1;
    }
  }
  return 0;
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

