#!/usr/bin/perl

use strict;
use utf8;
use warnings;

use File::Basename;
use Cwd 'abs_path';

use XML::LibXSLT;
use XML::LibXML;

no warnings 'recursion'; # yes, fix_paragraph is using heavy recursion, I know

my @block_elements = ('loncapa','parameter','location','answer','foil','image','polygon','rectangle','text','conceptgroup','itemgroup','item','label','data','function','numericalresponse','array','unit','answergroup','formularesponse','functionplotresponse','functionplotruleset','functionplotelements','functionplotcustomrule','stringresponse','essayresponse','externalresponse','hintgroup','hintpart','formulahint','numericalhint','reactionhint','organichint','optionhint','radiobuttonhint','stringhint','customhint','mathhint','imageresponse','foilgroup','datasubmission','customresponse','mathresponse','textfield','hiddensubmission','optionresponse','radiobuttonresponse','rankresponse','matchresponse','organicresponse','reactionresponse','import','script','window','block','library','notsolved','part','postanswerdate','preduedate','problem','problemtype','randomlabel','bgimg','labelgroup','randomlist','solved','while','gnuplot','curve','Task','IntroParagraph','ClosingParagraph','Question','QuestionText','Setup','Instance','InstanceText','Criteria','CriteriaText','GraderNote','languageblock','translated','lang','instructorcomment','dataresponse','togglebox','standalone','comment','drawimage','allow','displayduedate','displaytitle','responseparam','organicstructure','scriptlib','parserlib','drawoptionlist','spline','backgroundplot','plotobject','plotvector','drawvectorsum','functionplotrule','functionplotvectorrule','functionplotvectorsumrule','axis','key','xtics','ytics','title','xlabel','ylabel','hiddenline','htmlhead','htmlbody','lcmeta');
my @block_html = ('html','head','body','h1','h2','h3','h4','h5','h6','div','p','ul','ol','li','table','tbody','tr','td','th','dl','pre','noscript','hr','blockquote','object','applet','embed','map','form','fieldset','iframe','center');
my @all_block = (@block_elements, @block_html);
my @no_newline_inside = ('import','parserlib','scriptlib','data','function','label','xlabel','ylabel','tic','text','rectangle','image','title','h1','h2','h3','h4','h5','h6','li','td','p');
my @preserve_elements = ('script','answer','perl');

binmode(STDIN, ':encoding(UTF-8)');
binmode(STDOUT, ':encoding(UTF-8)');

my $dir = dirname(abs_path(__FILE__));

my $xslt = XML::LibXSLT->new();

open(my $in, "<-");

my $source = XML::LibXML->load_xml(IO => $in);

close($in);

remove_bad_fonts($source);

fix_paragraphs_inside($source->documentElement());

my $style_doc = XML::LibXML->load_xml(location=>$dir.'/post_xml.xsl', no_cdata=>1);

my $stylesheet = $xslt->parse_stylesheet($style_doc);

my $result_doc = $stylesheet->transform($source);
#my $result_doc = $source; # to disable the stylesheet
pretty($result_doc);

print $stylesheet->output_as_chars($result_doc);


# calls fix_paragraphs for all children
sub fix_paragraphs_inside {
  my ($node) = @_;
  # blocks in which paragrahs will be added:
  my @blocks_with_p = ('problem','foil','item','hintgroup','hintpart','part','problemtype','window','block','while','postanswerdate','preduedate','solved','notsolved','languageblock','translated','lang','instructorcomment','windowlink','togglebox','standalone','div');
  if (in_array(\@blocks_with_p, $node->nodeName)) {
    # add a paragraph containing everything inside, it will be fixed afterwards so that all inline nodes are
    # inside a paragraph
    my $doc = $node->ownerDocument;
    my $p = $doc->createElement('p');
    my $next;
    for (my $child=$node->firstChild; defined $child; $child=$next) {
      $next = $child->nextSibling;
      $node->removeChild($child);
      $p->appendChild($child);
    }
    $node->appendChild($p);
  }
  my $next;
  for (my $child=$node->firstChild; defined $child; $child=$next) {
    $next = $child->nextSibling;
    if ($child->nodeType == XML_ELEMENT_NODE && defined $child->firstChild) {
      if ($child->nodeName eq 'p') {
        fix_paragraph($child);
      } else {
        fix_paragraphs_inside($child);
      }
    }
  }
}

# fixes paragraphs inside paragraphs (without a block in-between)
sub fix_paragraph {
  my ($p) = @_;
  # inline elements that can be split in half if there is a paragraph inside:
  my @splitable_inline = ('span', 'a', 'strong', 'em' , 'b', 'i', 'sup', 'sub', 'code', 'kbd', 'samp', 'tt', 'ins', 'del', 'var', 'small', 'big', 'font', 'u');
  my $block = find_first_block($p);
  if (defined $block) {
    my $trees = clone_ancestor_around_node($p, $block);
    my $doc = $p->ownerDocument;
    my $replacement = $doc->createDocumentFragment();
    my $left = $trees->{'left'};
    my $middle = $trees->{'middle'};
    my $right = $trees->{'right'};
    if (defined $left) {
      $replacement->appendChild($left);
    }
    my $n = $middle->firstChild;
    while (defined $n) {
      if ($n->nodeType == XML_ELEMENT_NODE && (in_array(\@all_block, $n->nodeName) || $n->nodeName eq 'br')) {
        if ($n->nodeName eq 'p') {
          my $parent = $n->parentNode;
          # first apply recursion
          fix_paragraph($n);
          # now the p might have been replaced by several nodes, which should replace the initial p
          my $next_block;
          for (my $block=$parent->firstChild; defined $block; $block=$next_block) {
            $next_block = $block->nextSibling;
            if ($block->nodeName eq 'p') {
              $parent->removeChild($block);
              # for each parent before $middle, clone in-between the p and its children (to preserve the styles)
              if (defined $block->firstChild) {
                for (my $p=$parent; $p!=$middle; $p=$p->parentNode) {
                  my $newp = $p->cloneNode(0);
                  my $next;
                  for (my $child=$block->firstChild; defined $child; $child=$next) {
                    $next = $child->nextSibling;
                    $block->removeChild($child);
                    $newp->appendChild($child);
                  }
                  $block->appendChild($newp);
                }
              }
            }
            $replacement->appendChild($block);
          }
        } else {
          # replace the whole p by this block, forgetting about intermediate inline elements
          $n->parentNode->removeChild($n);
          if ($n->nodeName eq 'br') {
            # replace a br by a p
            $n = $doc->createElement('p');
          } else {
            fix_paragraphs_inside($n);
          }
          $replacement->appendChild($n);
        }
        last;
      }
      $n = $n->firstChild;
      if (defined $n && defined $n->nextSibling) {
        print STDERR "Error in post_xml.fix_paragraph: block not found\n";
        exit(-1);
        last;
      }
    }
    if (defined $right) {
      if ($block->nodeName eq 'p') {
        # remove attributes on the right paragraph
        my @attributelist = $right->attributes();
        foreach my $att (@attributelist) {
          $right->removeAttribute($att->nodeName);
        }
      }
      if ($right->firstChild->nodeType == XML_TEXT_NODE && $right->firstChild->nodeValue =~ /^\s*$/) {
        # remove the first text node with whitespace only from the p, it should not trigger the creation of a p
        my $first = $right->firstChild;
        $right->removeChild($first);
        $replacement->appendChild($first);
      }
      if (defined $right->firstChild) {
        $replacement->appendChild($right);
        fix_paragraph($right);
      }
    }
    $p->parentNode->replaceChild($replacement, $p);
  }
}

sub find_first_block {
  my ($node) = @_;
  for (my $child=$node->firstChild; defined $child; $child=$child->nextSibling) {
    if ($child->nodeType == XML_ELEMENT_NODE) {
      if (in_array(\@all_block, $child->nodeName) || $child->nodeName eq 'br') {
        return($child);
      }
      my $block = find_first_block($child);
      if (defined $block) {
        return($block);
      }
    }
  }
  return(undef);
}

# Creates clones of the ancestor containing the descendants before the node, at the node, and after the node.
# returns a hash with: left, middle, right (left and right can be undef)
sub clone_ancestor_around_node {
  my ($ancestor, $node) = @_;
  my $middle_node;
  my ($left, $middle, $right);
  for (my $child=$ancestor->firstChild; defined $child; $child=$child->nextSibling) {
    if ($child == $node || is_ancestor_of($child, $node)) {
      $middle_node = $child;
      last;
    }
  }
  if (!defined $middle_node) {
    print STDERR "error in split_ancestor_around_node: middle not found\n";
    exit(-1);
  }
  if (defined $middle_node->previousSibling) {
    $left = $ancestor->cloneNode(0);
    for (my $child=$ancestor->firstChild; $child != $middle_node; $child=$child->nextSibling) {
      $left->appendChild($child->cloneNode(1));
    }
  }
  $middle = $ancestor->cloneNode(0);
  if ($middle_node == $node) {
    $middle->appendChild($middle_node->cloneNode(1));
  } else {
    my $subres = clone_ancestor_around_node($middle_node, $node);
    my $subleft = $subres->{'left'};
    if (defined $subleft) {
      if (!defined $left) {
        $left = $ancestor->cloneNode(0);
      }
      $left->appendChild($subleft);
    }
    $middle->appendChild($subres->{'middle'});
    my $subright = $subres->{'right'};
    if (defined $subright) {
      $right = $ancestor->cloneNode(0);
      $right->appendChild($subright);
    }
  }
  if (defined $middle_node->nextSibling) {
    if (!defined $right) {
      $right = $ancestor->cloneNode(0);
    }
    for (my $child=$middle_node->nextSibling; defined $child; $child=$child->nextSibling) {
      $right->appendChild($child->cloneNode(1));
    }
  }
  my %result = ();
  $result{'left'} = $left;
  $result{'middle'} = $middle;
  $result{'right'} = $right;
  return(\%result);
}

sub is_ancestor_of {
  my ($n1, $n2) = @_;
  my $n = $n2->parentNode;
  while (defined $n) {
    if ($n == $n1) {
      return(1);
    }
    $n = $n->parentNode;
  }
  return(0);
}

# removes empty font elements and font elements that contain at least one block element
sub remove_bad_fonts {
  my ($node) = @_;
  my $type = $node->nodeType;
  if ($type == XML_DOCUMENT_NODE) {
    my $root = $node->documentElement();
    remove_bad_fonts($root);
  } elsif ($type == XML_ELEMENT_NODE) {
    my $nextChild;
    for (my $child=$node->firstChild; defined $child; $child=$nextChild) {
      $nextChild = $child->nextSibling;
      remove_bad_fonts($child);
    }
    my $name = $node->nodeName;
    if ($name eq 'font') {
      my $block = 0;
      for (my $child=$node->firstChild; defined $child; $child=$child->nextSibling) {
        if (in_array(\@all_block, $child->nodeName)) {
          $block = 1;
          last;
        }
      }
      if (!defined $node->firstChild || $block) {
        # replace this node by its content
        my $parent = $node->parentNode;
        my $next = $node->nextSibling;
        $node->parentNode->removeChild($node);
        for (my $child=$node->firstChild; defined $child; $child=$nextChild) {
          $nextChild = $child->nextSibling;
          if (defined $next) {
            $parent->insertBefore($child, $next);
          } else {
            $parent->appendChild($child);
          }
        }
      }
    }
  }
}

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
          $text =~ s/\n( *\n)+/\n/g;
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
      
      # removes whitespace at the beginning and end of paragraphs
      if ($name eq 'p' && defined $node->firstChild && $node->firstChild->nodeType == XML_TEXT_NODE) {
        my $text = $node->firstChild->nodeValue;
        $text =~ s/^\s*//;
        if ($text eq '') {
          $node->removeChild($node->firstChild);
        } else {
          $node->replaceChild($result_doc->createTextNode($text), $node->firstChild);
        }
      }
      if ($name eq 'p' && defined $node->lastChild && $node->lastChild->nodeType == XML_TEXT_NODE) {
        my $text = $node->lastChild->nodeValue;
        $text =~ s/\s*$//;
        if ($text eq '') {
          $node->removeChild($node->lastChild);
        } else {
          $node->replaceChild($result_doc->createTextNode($text), $node->lastChild);
        }
      }
    } elsif (in_array(\@preserve_elements, $name)) {
      # collapse newlines at the beginning and the end of scripts
      if (defined $node->firstChild && $node->firstChild->nodeType == XML_TEXT_NODE) {
        my $text = $node->firstChild->nodeValue;
        $text =~ s/^\n( *\n)+/\n/;
        if ($text eq '') {
          $node->removeChild($node->firstChild);
        } else {
          $node->replaceChild($result_doc->createTextNode($text), $node->firstChild);
        }
      }
      if (defined $node->lastChild && $node->lastChild->nodeType == XML_TEXT_NODE) {
        my $text = $node->lastChild->nodeValue;
        $text =~ s/\n( *\n)+$/\n/;
        if ($text eq '') {
          $node->removeChild($node->lastChild);
        } else {
          $node->replaceChild($result_doc->createTextNode($text), $node->lastChild);
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

