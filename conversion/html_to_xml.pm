#!/usr/bin/perl


package html_to_xml;

use strict;
use utf8;
use warnings;
use HTML::Parser ();

# always closing, end tags are ignored:
my @empty = ('base','br','col','hr','img','input','keygen','link','meta','param','source','track','wbr', 'frame', 'embed','startouttext','endouttext');

#my @block_html = ('html','body','h1','h2','h3','h4','h5','h6','div','p','ul','ol','table','tbody','tr','td','th','dl','pre','noscript','blockquote','object','applet','embed','map','form','fieldset','iframe');


my $result;
my @stack;
my $close_warning;


# This takes non-well-formed UTF-8 LC+HTML and returns well-formed but non-valid XML LC+XHTML.
sub html_to_xml {
  my($textref) = @_;
  $result = '';
  @stack = ();
  $close_warning = '';
  my $p = HTML::Parser->new( api_version => 3,
                          start_h => [\&start, "tagname, attr, attrseq"],
                          end_h   => [\&end,   "tagname"],
                          text_h  => [\&text, "dtext"],
                          comment_h  => [\&comment, "tokens"],
                          declaration_h  => [\&declaration, "tokens"],
                          process_h  => [\&process, "token0"],
                        );
  # NOTE: by default, the HTML parser turns all attribute and elements names to lowercase
  $p->empty_element_tags(1);
  $result .= "<?xml version='1.0' encoding='UTF-8'?>\n";
  $p->parse($$textref);
  for (my $i=scalar(@stack)-1; $i>=0; $i--) {
    if ($close_warning ne '') {
      $close_warning .= ', ';
    }
    $close_warning .= $stack[$i];
    $result .= '</'.$stack[$i].'>';
  }
  if ($close_warning ne '') {
    print "Warning: the parser had to add closing tags to understand the document ($close_warning)\n";
  }
  return \$result;
}

sub start {
  my($tagname, $attr, $attrseq) = @_;
  
  # NOTE: we could do things more like web browsers, but I'm nore sure the result would be better with LON-CAPA files
  # (in problem files there are not so many missing tags)
  # See http://www.w3.org/TR/html5/syntax.html#an-introduction-to-error-handling-and-strange-cases-in-the-parser
  
  if ($tagname eq 'o:p') {
    return;
  }
  
  if ($tagname =~ /@.*\.[a-z]{2,3}$/) { # email <name@hostname>
    $result .= "&lt;$tagname&gt;";
    return;
  }
  
  #$tagname = lc($tagname); this is done by default by the parser
  $tagname = fix_tag($tagname);
  if (scalar(@stack) > 0 && $stack[scalar(@stack)-1] eq 'tr' && $tagname ne 'tr' && $tagname ne 'td' && $tagname ne 'th' &&
      !string_in_array(['part','block','comment','endouttext','problemtype','standalone','startouttext','tex','translated','web','while'], $tagname)) {
    # NOTE: a 'part' or 'block' element between tr and td will not be valid, but changing tag order would make things worse
    print "Warning: a <td> tag was added because a $tagname element was directly under a tr\n";
    start('td');
  }
  if ($tagname eq 'p' && scalar(@stack) > 0 && $stack[scalar(@stack)-1] eq 'p') {
    end('p');
  } elsif ($tagname eq 'li') {
    my $ind_li = last_index_of(\@stack, 'li');
    my $ind_ul = last_index_of(\@stack, 'ul');
    my $ind_ol = last_index_of(\@stack, 'ol');
    if ($ind_li != -1 && ($ind_ul == -1 || $ind_ul < $ind_li) && ($ind_ol == -1 || $ind_ol < $ind_li)) {
      end('li');
    }
  } elsif ($tagname eq 'tr') {
    my $ind_table = last_index_of(\@stack, 'table');
    my $ind_tr = last_index_of(\@stack, 'tr');
    if ($ind_tr != -1 && ($ind_table == -1 || $ind_table < $ind_tr)) {
      end('tr');
    }
  } elsif ($tagname eq 'td' || $tagname eq 'th') {
    my $ind_table = last_index_of(\@stack, 'table');
    my $ind_td = last_index_of(\@stack, 'td');
    my $ind_th = last_index_of(\@stack, 'th');
    my $ind_tr = last_index_of(\@stack, 'tr');
    if ($ind_tr == -1 || ($ind_table != -1 && $ind_table > $ind_tr)) {
      start('tr');
      $ind_tr = last_index_of(\@stack, 'tr');
    }
    if ($ind_td != -1 && $ind_tr < $ind_td) {
      end('td');
    } elsif ($ind_th != -1 && $ind_tr < $ind_th) {
      end('th');
    }
  } elsif ($tagname eq 'dd' || $tagname eq 'dt') {
    my $ind_dd = last_index_of(\@stack, 'dd');
    my $ind_dt = last_index_of(\@stack, 'dt');
    my $ind_dl = last_index_of(\@stack, 'dl');
    if ($ind_dl == -1) {
      start('dl');
      $ind_dl = last_index_of(\@stack, 'dl');
    }
    if ($ind_dd != -1 && ($ind_dl == -1 || $ind_dl < $ind_dd)) {
      end('dd');
    } elsif ($ind_dt != -1 && ($ind_dl == -1 || $ind_dl < $ind_dt)) {
      end('dt');
    }
  } elsif ($tagname eq 'option') {
    my $ind_option = last_index_of(\@stack, 'option');
    if ($ind_option != -1) {
      end('option');
    }
  } elsif ($tagname eq 'area') {
    my $ind_area = last_index_of(\@stack, 'area');
    if ($ind_area != -1) {
      end('area');
    }
  } elsif ($tagname eq 'a') {
    my $ind_a = last_index_of(\@stack, 'a');
    if ($ind_a != -1) {
      end('a');
    }
  } elsif ($tagname eq 'num') {
    my $ind_num = last_index_of(\@stack, 'num');
    if ($ind_num != -1) {
      end('num');
    }
  }

# HTML interpretation of non-closing elements and style is too complex (and error-prone, anyway).
# Since LON-CAPA elements are all supposed to be closed, this interpretation is SGML-like instead.
# Paragraphs inside paragraphs will be fixed later.

#   my @styles = ();
#   if ($tagname eq 'p') {
#     for (my $i=scalar(@stack)-1; $i>=0; $i--) {
#       if ($stack[$i] eq 'p') {
#         # save the styles
#         for (my $j=$i+1; $j<scalar(@stack); $j++) {
#           if (index_of(['b','i','em','strong','sub','sup'], $stack[$j]) != -1) {
#             push(@styles, $stack[$j]);
#           }
#         }
#         # close the p
#         end('p');
#         last;
#       } elsif (index_of(\@block_html, $stack[$i]) != -1) {
#         # stop looking
#         last;
#       }
#     }
#   }
  $result .= '<'.$tagname;
  my %seen = ();
  foreach my $att_name (@$attrseq) {
    my $att_name_modified = $att_name;
    $att_name_modified =~ s/[^\-a-zA-Z0-9_:.]//g;
    $att_name_modified =~ s/^[\-.0-9]*//;
    if ($att_name_modified ne '' && index($att_name_modified, ':') == -1) {
      if ($seen{$att_name_modified}) {
        print "Warning: Ignoring duplicate attribute: $att_name\n";
        next;
      }
      $seen{$att_name_modified}++;
      my $att_value = $attr->{$att_name};
      $att_value =~ s/^[“”]|[“”]$//g;
      $att_value =~ s/&/&amp;/g;
      $att_value =~ s/</&lt;/g;
      $att_value =~ s/>/&gt;/g;
      $att_value =~ s/"/&quot;/g;
      if ($tagname eq 'embed' && $att_name_modified eq 'script') {
        # newlines are encoded to preserve Protein Explorer scripts in embed script attributes:
        $att_value =~ s/\x0A/&#xA;/g;
        $att_value =~ s/\x0D/&#xD;/g;
      }
      if ($att_name_modified eq 'xmlns' && ($att_value eq 'http://www.w3.org/1999/xhtml' ||
          $att_value eq 'http://www.w3.org/TR/REC-html40')) {
        next;
      }
      $result .= ' '.$att_name_modified.'="'.$att_value.'"';
    }
  }
  if (index_of(\@empty, $tagname) != -1) {
    $result .= '/>';
  } else {
    $result .= '>';
    push(@stack, $tagname);
    if (scalar(@stack) > 500) {
      die "This document has a crazy depth - I'm out !";
    }
  }
  # reopen the styles, if any
  #for (my $j=0; $j<scalar(@styles); $j++) {
  #  start($styles[$j], {}, ());
  #}
}

sub end {
  my($tagname) = @_;
  
  if ($tagname eq 'o:p') {
    return;
  }
  
  $tagname = fix_tag($tagname);
  if (index_of(\@empty, $tagname) != -1) {
    return;
  }
  if ($tagname eq 'td' && scalar(@stack) > 0 && $stack[scalar(@stack)-1] eq 'th') {
    # handle <th>text</td> as if it was <th>text</th>
    $tagname = 'th';
  } elsif ($tagname eq 'th' && scalar(@stack) > 0 && $stack[scalar(@stack)-1] eq 'td') {
    # handle <td>text</th> as if it was <td>text</td>
    $tagname = 'td';
  }
  my $found = 0;
  for (my $i=scalar(@stack)-1; $i>=0; $i--) {
    if ($stack[$i] eq $tagname) {
      for (my $j=scalar(@stack)-1; $j>$i; $j--) {
        if ($close_warning ne '') {
          $close_warning .= ', ';
        }
        $close_warning .= $stack[$j];
        $result .= '</'.$stack[$j].'>';
      }
      splice(@stack, $i, scalar(@stack)-$i);
      $found = 1;
      last;
    } elsif (index_of(\@stack, 'web') != -1) {
      die "There is a web element with missing end tags inside - it has to be fixed by hand";
    }
  }
  if ($found) {
    $result .= '</'.$tagname.'>';
  } elsif ($tagname eq 'p') {
    $result .= '<p/>';
  }
}

sub text {
  my($dtext) = @_;
  $dtext =~ s/&/&amp;/g;
  $dtext =~ s/</&lt;/g;
  $dtext =~ s/>/&gt;/g;
  $dtext =~ s/"/&quot;/g;
  $result .= $dtext;
}

sub comment {
  my($tokens) = @_;
  # NOTE: the HTML parser thinks this is a comment: </ br>
  # and LON-CAPA has sometimes turned that into <![CDATA[</ br>]]>
  foreach my $comment (@$tokens) {
    $comment =~ s/--/- /g;
    $comment =~ s/^-|-$/ /g;
    $result .= '<!--'.$comment.'-->';
  }
}

sub declaration {
  my($tokens) = @_;
  # ignore them
  #$result .= '<!';
  #$result .= join(' ', @$tokens);
  #$result .= '>';
}

sub process {
  my($token0) = @_;
  if ($token0 ne '') {
    $result .= '<?'.$token0.'>';
  }
}

sub index_of {
  my ($array, $value) = @_;
  for (my $i=0; $i<scalar(@{$array}); $i++) {
    if ($array->[$i] eq $value) {
      return $i;
    }
  }
  return -1;
}

sub last_index_of {
  my ($array, $value) = @_;
  for (my $i=scalar(@{$array})-1; $i>=0; $i--) {
    if ($array->[$i] eq $value) {
      return $i;
    }
  }
  return -1;
}

sub fix_tag {
  my ($tag) = @_;
  #$tag = lc($tag); this is done by default by the parser
  if ($tag !~ /^[a-zA-Z_][a-zA-Z0-9_\-\.]*$/) {
    print "Warning: bad start tag:'".$tag."'";
    if ($tag =~ /<[a-zA-Z]/) {
      $tag =~ s/^[^<]*<//; # a<b -> b
    }
    if ($tag =~ /[a-zA-Z]=/) {
      $tag =~ s/=.*$//; # a=b -> a
    }
    if ($tag =~ /[a-zA-Z]\//) {
      $tag =~ s/\/.*$//; # a/b -> a
    }
    if ($tag =~ /:/) {
      # a:b -> b except when : at the end
      if ($tag =~ /^[^:]*:$/) {
        $tag =~ s/://;
      } else {
        $tag =~ s/^.*://;
      }
    }
    $tag =~ s/^[0-9\-\.]+//;
    $tag =~ s/[^a-zA-Z0-9_\-\.]//g;
    print " (converted to $tag)\n";
  }
  return($tag);
}


##
# Tests if a string is in an array (using eq) (to avoid Smartmatch warnings with $value ~~ @array)
# @param {Array<string>} array - reference to the array of strings
# @param {string} value - the string to look for
# @returns 1 if found, 0 otherwise
##
sub string_in_array {
  my ($array, $value) = @_;
  foreach my $v (@{$array}) {
    if ($v eq $value) {
      return 1;
    }
  }
  return 0;
}


1;
__END__
