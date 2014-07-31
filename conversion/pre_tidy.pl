#!/usr/bin/perl

use strict;

my @block_elements = ('answer','foil','image','polygon','rectangle','text','conceptgroup','itemgroup','item','label','data','function','numericalresponse','answergroup','formularesponse','functionplotresponse','functionplotruleset','functionplotelements','functionplotcustomrule','stringresponse','essayresponse','externalresponse','hintgroup','hintpart','formulahint','numericalhint','reactionhint','organichint','optionhint','radiobuttonhint','stringhint','customhint','mathhint','imageresponse','foilgroup','datasubmission','customresponse','mathresponse','textfield','hiddensubmission','optionresponse','radiobuttonresponse','rankresponse','matchresponse','organicresponse','reactionresponse','import','script','window','block','library','notsolved','part','postanswerdate','preduedate','problem','problemtype','randomlabel','bgimg','labelgroup','randomlist','solved','while','gnuplot','curve','Task','IntroParagraph','ClosingParagraph','Question','QuestionText','Setup','Instance','InstanceText','Criteria','CriteriaText','GraderNote','languageblock','translated','lang','instructorcomment','dataresponse','togglebox','standalone','comment','drawimage','allow','displayduedate','displaytitle','responseparam','organicstructure','scriptlib','parserlib','drawoptionlist','spline','backgroundplot','plotobject','plotvector','drawvectorsum','functionplotrule','functionplotvectorrule','functionplotvectorsumrule','axis','key','xtics','ytics','title','xlabel','ylabel','hiddenline','html','body','div','p','ul','ol','table','dl','pre','noscript','blockquote','map','form','fieldset');

my @lines = <STDIN>; # we need to lead the whole file to test if font is a block or inline element

for (my $i=0; $i<scalar(@lines); $i++) {
  my $line = $lines[$i];
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
    ($tag, $type, $i2, $j2) = next_tag($i2, $j2+1);
    while ($tag ne '') {
      if (($tag eq 'font' || $tag eq 'FONT') && $type eq 'end') {
        if ($depth > 0) {
          $depth--;
        } else {
          last;
        }
      } elsif (($tag eq 'font' || $tag eq 'FONT') && $type eq 'start') {
        $depth++;
      } elsif ($tag ~~ @block_elements) {
        $is_block = 1;
      }
      ($tag, $type, $i2, $j2) = next_tag($i2, $j2+1);
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
        $lines[$i2] = substr($lines[$i2], 0, $j2).'</'.$newname.'>'.substr($lines[$i2], $j2+7);
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
    $lines[$i] = $line; # we need that because next_tag is using @lines
  }
  print $line;
}

##
# Returns information about the next tag, starting at line number and char number.
# Assumes the markup is well-formed and there is no CDATA,
# which is not always true (like inside script), so results might be wrong sometimes.
# @param {int} line_number
# @param {int} char_number
# @returns (tag, type, line_number, char_number)
##
sub next_tag {
  my( $i, $j ) = @_;
  my $i2 = $i;
  my $j2 = $j;
  while ($i2 < scalar(@lines)) {
    my $line = $lines[$i2];
    $j2 = index($line, '<', $j2);
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
