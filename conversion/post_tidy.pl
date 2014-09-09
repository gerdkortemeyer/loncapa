#!/usr/bin/perl

use strict;

use File::Basename;
use Cwd 'abs_path';

use XML::LibXSLT;
use XML::LibXML;

# this is just for pretty-print:
my @block_elements = ('loncapa','parameter','location','answer','foil','image','polygon','rectangle','text','conceptgroup','itemgroup','item','label','data','function','numericalresponse','array','unit','answergroup','formularesponse','functionplotresponse','functionplotruleset','functionplotelements','functionplotcustomrule','stringresponse','essayresponse','externalresponse','hintgroup','hintpart','formulahint','numericalhint','reactionhint','organichint','optionhint','radiobuttonhint','stringhint','customhint','mathhint','imageresponse','foilgroup','datasubmission','customresponse','mathresponse','textfield','hiddensubmission','optionresponse','radiobuttonresponse','rankresponse','matchresponse','organicresponse','reactionresponse','import','script','window','block','library','notsolved','part','postanswerdate','preduedate','problem','problemtype','randomlabel','bgimg','labelgroup','randomlist','solved','while','gnuplot','curve','Task','IntroParagraph','ClosingParagraph','Question','QuestionText','Setup','Instance','InstanceText','Criteria','CriteriaText','GraderNote','languageblock','translated','lang','instructorcomment','dataresponse','togglebox','standalone','comment','drawimage','allow','displayduedate','displaytitle','responseparam','organicstructure','scriptlib','parserlib','drawoptionlist','spline','backgroundplot','plotobject','plotvector','drawvectorsum','functionplotrule','functionplotvectorrule','functionplotvectorsumrule','axis','key','xtics','ytics','title','xlabel','ylabel','hiddenline','htmlhead','htmlbody');
my @block_html = ('html','body','h1','h2','h3','h4','h5','h6','div','p','ul','ol','li','table','tbody','tr','td','th','dl','pre','noscript','blockquote','object','applet','embed','map','form','fieldset','iframe');
my @all_block = (@block_elements, @block_html);
my @no_newline_inside = ('import','parserlib','scriptlib','data','function','label','xlabel','ylabel','tic','text','rectangle','image','title','h1','h2','h3','h4','h5','h6','li','td');
my @preserve_elements = ('script','answer');


my $dir = dirname(abs_path(__FILE__));

my $xslt = XML::LibXSLT->new();

my $in;

open(my $in, "<-");

my $source = XML::LibXML->load_xml(IO => $in);

close($in);

my $style_doc = XML::LibXML->load_xml(location=>$dir.'/post_tidy.xsl', no_cdata=>1);

my $stylesheet = $xslt->parse_stylesheet($style_doc);

my $result_doc = $stylesheet->transform($source);

pretty($result_doc);

print $stylesheet->output_as_bytes($result_doc);


# pretty-print using im-memory DOM tree
sub pretty {
  my ($node, $indent_level) = @_;
  $indent_level ||= 0;
  my $type = $node->nodeType;
  if ($type == XML_DOCUMENT_NODE) {
    my $root = $node->documentElement();
    pretty($root, $indent_level);
  } elsif ($type == XML_ELEMENT_NODE) {
    my $name = $node->nodeName;
    if (in_array(\@all_block, $name) && !in_array(\@preserve_elements, $name)) {
      # make sure there is a newline at the beginning and at the end if there is anything inside
      if (defined $node->firstChild && !in_array(\@no_newline_inside, $name)) {
        my $first = $node->firstChild;
        if ($first->nodeType == XML_TEXT_NODE) {
          my $text = $first->nodeValue;
          if ($text !~ /^ *\n/) {
            #$first->nodeValue = "\n" . $text; does not compile
            $node->replaceChild($result_doc->createTextNode("\n" . $text), $first);
          }
        } else {
          $node->insertBefore($result_doc->createTextNode("\n"), $first);
        }
        my $last = $node->lastChild;
        if ($last->nodeType == XML_TEXT_NODE) {
          my $text = $last->nodeValue;
          if ($text !~ /\n *$/) {
            $node->replaceChild($result_doc->createTextNode($text . "\n"), $last);
          }
        } else {
          $node->appendChild($result_doc->createTextNode("\n"));
        }
      }
      
      # indent and make sure there is a newline before and after a block element
      my $newline_indent = "\n".(' ' x (2*($indent_level + 1)));
      my $newline_indent_last = "\n".(' ' x (2*$indent_level));
      my $next;
      for (my $child=$node->firstChild; defined $child; $child=$next) {
        $next = $child->nextSibling;
        if ($child->nodeType == XML_ELEMENT_NODE) {
          if (in_array(\@all_block, $child->nodeName)) {
            # make sure there is a newline before and after a block element
            if (defined $child->previousSibling && $child->previousSibling->nodeType == XML_TEXT_NODE) {
              my $prev = $child->previousSibling;
              my $text = $prev->nodeValue;
              if ($text !~ /\n *$/) {
                $text = $text . $newline_indent;
                $node->replaceChild($result_doc->createTextNode($text), $prev);
              }
            } else {
              $node->insertBefore($result_doc->createTextNode($newline_indent), $child);
            }
            if (defined $next && $next->nodeType == XML_TEXT_NODE) {
              my $text = $next->nodeValue;
              if ($text !~ /^ *\n/) {
                $text = $newline_indent . $text;
                my $newnode = $result_doc->createTextNode($text);
                $node->replaceChild($newnode, $next);
                $next = $newnode;
              }
            } else {
              $node->insertAfter($result_doc->createTextNode($newline_indent), $child);
            }
          }
          pretty($child, $indent_level+1);
        } elsif ($child->nodeType == XML_TEXT_NODE) {
          my $text = $child->nodeValue;
          # collapse newlines
          $text =~ s/\n *\n/\n/g;
          # indent
          if (defined $next) {
            $text =~ s/\n */$newline_indent/ge;
          } else {
            $text =~ s/\n */$newline_indent/ge;
            $text =~ s/\n *$/$newline_indent_last/e;
          }
          $node->replaceChild($result_doc->createTextNode($text), $child);
        }
      }
    }
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

