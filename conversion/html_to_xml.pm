#!/usr/bin/perl


package html_to_xml;

use strict;
use utf8;
use warnings;
use HTML::Parser ();

# always closing, end tags are ignored:
my @empty = ('base','br','col','hr','img','input','keygen','link','meta','param','source','track','wbr');

#my @block_html = ('html','body','h1','h2','h3','h4','h5','h6','div','p','ul','ol','table','tbody','tr','td','th','dl','pre','noscript','blockquote','object','applet','embed','map','form','fieldset','iframe');


my $result;
my @stack;


# This takes non-well-formed UTF-8 LC+HTML and returns well-formed but non-valid XML LC+XHTML.
sub html_to_xml {
  my($textref) = @_;
  $result = '';
  @stack = ();
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
    $result .= '</'.$stack[$i].'>';
  }
  return \$result;
}

sub start {
  my($tagname, $attr, $attrseq) = @_;
  #$tagname = lc($tagname); this is done by default by the parser
  $tagname = fix_tag($tagname);
  if ($tagname eq 'li') {
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
  } elsif ($tagname eq 'td') {
    my $ind_td = last_index_of(\@stack, 'td');
    my $ind_tr = last_index_of(\@stack, 'tr');
    if ($ind_tr == -1) {
      start('tr');
      $ind_tr = last_index_of(\@stack, 'tr');
    }
    if ($ind_td != -1 && $ind_tr < $ind_td) {
      end('td');
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
      $result .= ' '.$att_name_modified.'="'.$att_value.'"';
    }
  }
  if (index_of(\@empty, $tagname) != -1) {
    $result .= '/>';
  } else {
    $result .= '>';
    push(@stack, $tagname);
  }
  # reopen the styles, if any
  #for (my $j=0; $j<scalar(@styles); $j++) {
  #  start($styles[$j], {}, ());
  #}
}

sub end {
  my($tagname) = @_;
  $tagname = fix_tag($tagname);
  if (index_of(\@empty, $tagname) != -1) {
    return;
  }
  my $found = 0;
  for (my $i=scalar(@stack)-1; $i>=0; $i--) {
    if ($stack[$i] eq $tagname) {
      for (my $j=scalar(@stack)-1; $j>$i; $j--) {
        $result .= '</'.$stack[$j].'>';
      }
      splice(@stack, $i, scalar(@stack)-$i);
      $found = 1;
      last;
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
  foreach my $comment (@$tokens) {
    $comment =~ s/--/- /g;
    $comment =~ s/^-|-$/ /g;
    $result .= '<!--'.$comment.'-->';
  }
}

sub declaration {
  my($tokens) = @_;
  $result .= '<!';
  $result .= join(' ', @$tokens);
  $result .= '>';
}

sub process {
  my($token0) = @_;
  $result .= '<?'.$token0.'>';
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
  if ($tag =~ /[<\+"'\/=\s,;:]/) {
    print "Warning: bad start tag:'".$tag."'";
    if ($tag =~ /<[a-zA-Z]/) {
      $tag =~ s/^[^<]*<//; # a<b -> b
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
    $tag =~ s/[<\+"'\/=\s,;:]//g;
    print " (converted to $tag)\n";
  }
  return($tag);
}

1;
__END__
