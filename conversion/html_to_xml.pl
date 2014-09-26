#!/usr/bin/perl

# This takes non-well-formed UTF-8 LC+HTML from standard input and outputs well-formed but non-valid XML LC+XHTML.

use strict;
use utf8;
use warnings;
use HTML::Parser ();

my @empty = ('br','meta','hr'); # always closing, end tags are ignored
my @block_html = ('html','body','h1','h2','h3','h4','h5','h6','div','p','ul','ol','table','tbody','tr','td','th','dl','pre','noscript','blockquote','object','applet','embed','map','form','fieldset','iframe');


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
my @stack = ();
my $root_found = 0;
binmode(STDIN, ':encoding(UTF-8)');
binmode(STDOUT, ':encoding(UTF-8)');
print "<?xml version='1.0' encoding='UTF-8'?>\n";
open(my $in, '<-') || die "html_to_xml: can't open stdin";
$p->parse_file($in);
for (my $i=scalar(@stack)-1; $i>=0; $i--) {
  print '</'.$stack[$i].'>';
}


sub start {
  my($tagname, $attr, $attrseq) = @_;
  #$tagname = lc($tagname); this is done by default by the parser
  if ($tagname =~ /[<\+"'\/=\s]/) {
    print STDERR "bad start tag:'".$tagname."'";
    $tagname =~ s/[<\+"'\/=\s]//g;
  }
  if (scalar(@stack) == 0) {
    if ($root_found == 0) {
      $root_found = 1;
    } else {
      return; # after root: ignored
    }
  }
  if ($tagname eq 'li') {
    my $ind_li = last_index_of(\@stack, 'li');
    my $ind_ul = last_index_of(\@stack, 'ul');
    if ($ind_li != -1 && ($ind_ul == -1 || $ind_ul < $ind_li)) {
      # close the li
      end('li');
    }
  } elsif ($tagname eq 'td') {
    my $ind_td = last_index_of(\@stack, 'td');
    my $ind_tr = last_index_of(\@stack, 'tr');
    if ($ind_td != -1 && ($ind_tr == -1 || $ind_tr < $ind_td)) {
      # close the td
      end('td');
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
  print '<'.$tagname;
  foreach my $att_name (@$attrseq) {
    my $att_name_modified = $att_name;
    $att_name_modified =~ s/["'\/=\s]//g;
    $att_name_modified =~ s/^[0-9]*$//;
    if ($att_name_modified ne '') {
      my $att_value = $attr->{$att_name};
      $att_value =~ s/^[“”]|[“”]$//g;
      $att_value =~ s/&/&amp;/g;
      $att_value =~ s/</&lt;/g;
      $att_value =~ s/>/&gt;/g;
      $att_value =~ s/"/&quot;/g;
      print ' '.$att_name_modified.'="'.$att_value.'"';
    }
  }
  if (index_of(\@empty, $tagname) != -1) {
    print '/>';
  } else {
    print '>';
    push(@stack, $tagname);
  }
  # reopen the styles, if any
  #for (my $j=0; $j<scalar(@styles); $j++) {
  #  start($styles[$j], {}, ());
  #}
}

sub end {
  my($tagname) = @_;
  #$tagname = lc($tagname); this is done by default by the parser
  if (index_of(\@empty, $tagname) != -1) {
    return;
  }
  my $found = 0;
  for (my $i=scalar(@stack)-1; $i>=0; $i--) {
    if ($stack[$i] eq $tagname) {
      for (my $j=scalar(@stack)-1; $j>$i; $j--) {
        print '</'.$stack[$j].'>';
      }
      splice(@stack, $i, scalar(@stack)-$i);
      $found = 1;
      last;
    }
  }
  if ($found) {
    print '</'.$tagname.'>';
  } elsif ($tagname eq 'p') {
    print '<p/>';
  }
}

sub text {
  my($dtext) = @_;
  if (scalar(@stack) == 0 && $root_found == 1) {
    return; # after root: ignored
  }
  $dtext =~ s/&/&amp;/g;
  $dtext =~ s/</&lt;/g;
  $dtext =~ s/>/&gt;/g;
  $dtext =~ s/"/&quot;/g;
  print $dtext;
}

sub comment {
  my($tokens) = @_;
  for (@$tokens) {
    print '<!--'.$_.'-->';
  }
}

sub declaration {
  my($tokens) = @_;
  print '<!';
  print join(' ', @$tokens);
  print '>';
}

sub process {
  my($token0) = @_;
  print '<?'.$token0.'>';
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
