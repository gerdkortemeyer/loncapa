#!/usr/bin/perl

use strict;
use utf8;
use warnings;

use File::Basename;
use Cwd 'abs_path';

use XML::LibXSLT;
use XML::LibXML;

no warnings 'recursion'; # yes, fix_paragraph is using heavy recursion, I know

my @block_elements = ('loncapa','parameter','location','answer','foil','image','polygon','rectangle','text','conceptgroup','itemgroup','item','label','data','function','numericalresponse','array','unit','answergroup','formularesponse','functionplotresponse','functionplotruleset','functionplotelements','functionplotcustomrule','stringresponse','essayresponse','externalresponse','hintgroup','hintpart','formulahint','numericalhint','reactionhint','organichint','optionhint','radiobuttonhint','stringhint','customhint','mathhint','imageresponse','foilgroup','datasubmission','customresponse','mathresponse','textfield','hiddensubmission','optionresponse','radiobuttonresponse','rankresponse','matchresponse','organicresponse','reactionresponse','import','script','window','block','library','notsolved','part','postanswerdate','preduedate','problem','problemtype','randomlabel','bgimg','labelgroup','randomlist','solved','while','gnuplot','curve','Task','IntroParagraph','ClosingParagraph','Question','QuestionText','Setup','Instance','InstanceText','Criteria','CriteriaText','GraderNote','languageblock','translated','lang','instructorcomment','dataresponse','togglebox','standalone','comment','drawimage','allow','displayduedate','displaytitle','responseparam','organicstructure','scriptlib','parserlib','drawoptionlist','spline','backgroundplot','plotobject','plotvector','drawvectorsum','functionplotrule','functionplotvectorrule','functionplotvectorsumrule','axis','key','xtics','ytics','title','xlabel','ylabel','hiddenline','htmlhead','htmlbody','lcmeta','perl');
my @block_html = ('html','head','body','h1','h2','h3','h4','h5','h6','div','p','ul','ol','li','table','tbody','tr','td','th','dl','pre','noscript','hr','blockquote','object','applet','embed','map','form','fieldset','iframe','center');
my @all_block = (@block_elements, @block_html);
my @no_newline_inside = ('import','parserlib','scriptlib','data','function','label','xlabel','ylabel','tic','text','rectangle','image','title','h1','h2','h3','h4','h5','h6','li','td','p');
my @preserve_elements = ('script','answer','perl');

binmode(STDIN, ':encoding(UTF-8)');

my $dir = dirname(abs_path(__FILE__));

my $xslt = XML::LibXSLT->new();

open(my $in, "<-");

my $dom_doc = XML::LibXML->load_xml(IO => $in);

close($in);

my $root = create_new_structure($dom_doc);

remove_elements($root, ['startouttext','endouttext','startpartmarker','endpartmarker','displayweight','displaystudentphoto','basefont','displaytitle','displayduedate','allow']);

# TODO: something with styles containing block elements

fix_fonts($root);

replace_script_by_perl($root);

remove_bad_cdata_sections($root);

fix_tables($root);

replace_center($root); # note: this must come after fix_tables

fix_paragraphs_inside($root);

remove_empty_style($root);

pretty($root);

print $dom_doc->toString();


sub create_new_structure {
  my ($doc) = @_;
  # move everything in the document under a new 'loncapa' root element
  my $root = $dom_doc->createElement('loncapa');
  my $next;
  for (my $child=$doc->firstChild; defined $child; $child=$next) {
    $next = $child->nextSibling;
    $doc->removeChild($child);
    $root->appendChild($child);
  }
  $dom_doc->setDocumentElement($root);
  # replace html elements by the content
  my @htmls = $dom_doc->getElementsByTagName('html');
  foreach my $html (@htmls) {
    replace_by_children($html);
  }
  # replace head by htmlhead
  my $current_node = undef;
  my @heads = $dom_doc->getElementsByTagName('head');
  if (scalar(@heads) > 0) {
    my $htmlhead = $doc->createElement('htmlhead');
    foreach my $head (@heads) {
      my $next;
      for (my $child=$head->firstChild; defined $child; $child=$next) {
        $next = $child->nextSibling;
        $head->removeChild($child);
        $htmlhead->appendChild($child);
      }
      $head->parentNode->removeChild($head);
    }
    insert_after_or_first($root, $htmlhead, $current_node);
    $current_node = $htmlhead;
  }
  # replace a body with attributes by an empty htmlbody with the same attributes
  my $htmlbody = undef;
  my @bodies = $dom_doc->getElementsByTagName('body');
  if (scalar(@bodies) > 0) {
    my @attributes = ();
    foreach my $body (@bodies) {
      if ($body->hasAttributes()) {
        push(@attributes, $body->attributes());
      }
      replace_by_children($body);
    }
    if (scalar(@attributes) > 0) {
      my $htmlbody = $doc->createElement('htmlbody');
      foreach my $att (@attributes) {
        $htmlbody->setAttribute($att->nodeName, $att->nodeValue);
      }
      insert_after_or_first($root, $htmlbody, $current_node);
      $current_node = $htmlbody;
    }
  }
  # add all the meta elements afterwards when they are LON-CAPA meta. Remove all HTML meta.
  my @meta_names = ('abstract','author','authorspace','avetries','avetries_list','clear','comefrom','comefrom_list','copyright','correct','count','course','course_list','courserestricted','creationdate','dependencies','depth','difficulty','difficulty_list','disc','disc_list','domain','end','field','firstname','generation','goto','goto_list','groupname','helpful','highestgradelevel','hostname','id','keynum','keywords','language','lastname','lastrevisiondate','lowestgradelevel','middlename','mime','modifyinguser','notes','owner','permanentemail','scope','sequsage','sequsage_list','standards','start','stdno','stdno_list','subject','technical','title','url','username','value','version');
  my @metas = $dom_doc->getElementsByTagName('meta');
  foreach my $meta (@metas) {
    $meta->parentNode->removeChild($meta);
    my $name = $meta->getAttribute('name');
    my $content = $meta->getAttribute('content');
    if (defined $name && defined $content && in_array(\@meta_names, lc($name))) {
      my $lcmeta = $dom_doc->createElement('lcmeta');
      $lcmeta->setAttribute('name', lc($name));
      $lcmeta->setAttribute('content', $content);
      insert_after_or_first($root, $lcmeta, $current_node);
      $current_node = $lcmeta;
    }
  }
  return($root);
}

# insert the new child under parent after the reference child, or as the first child if the reference child is not defined
sub insert_after_or_first {
  my ($parent, $newchild, $refchild) = @_;
  if (defined $refchild) {
    $parent->insertAfter($newchild, $refchild);
  } elsif (defined $parent->firstChild) {
    $parent->insertBefore($newchild, $parent->firstChild);
  } else {
    $parent->appendChild($newchild);
  }
}

# removes all elements with given names inside the node
sub remove_elements {
  my ($node, $to_remove) = @_;
  my $nextChild;
  for (my $child=$node->firstChild; defined $child; $child=$nextChild) {
    $nextChild = $child->nextSibling;
    my $type = $node->nodeType;
    if ($type == XML_ELEMENT_NODE) {
      if (in_array($to_remove, $child->nodeName)) {
        $node->removeChild($child);
      } else {
        remove_elements($child, $to_remove);
      }
    }
  }
}

# removes empty font elements and font elements that contain at least one block element
# replaces other font elements by equivalent span
sub fix_fonts {
  my ($root) = @_;
  my @fonts = $dom_doc->getElementsByTagName('font');
  foreach my $font (@fonts) {
    my $block = 0;
    for (my $child=$font->firstChild; defined $child; $child=$child->nextSibling) {
      if (in_array(\@all_block, $child->nodeName)) {
        $block = 1;
        last;
      }
    }
    if (!defined $font->firstChild || $block) {
      # empty font or font containing block elements
      # replace this node by its content
      replace_by_children($font);
    } else {
      # replace by equivalent span
      my $color = get_non_empty_attribute($font, 'color');
      my $size = get_non_empty_attribute($font, 'size');
      my $face = get_non_empty_attribute($font, 'face');
      if (!defined $color && !defined $size && !defined $face) {
        # useless font element: replace this node by its content
        replace_by_children($font);
        next;
      }
      my $replacement;
      if (!defined $color && !defined $size && defined $face && lc($face) eq 'symbol') {
        $replacement = $dom_doc->createDocumentFragment();
      } else {
        $replacement = $dom_doc->createElement('span');
        my $css = '';
        if (defined $color) {
          $color =~ s/^x//;
          $css .= 'color:'.$color.';';
        }
        if (defined $size) {
          my %hash = (
            '1' => 'x-small',
            '2' => 'small',
            '3' => 'medium',
            '4' => 'large',
            '5' => 'x-large',
            '6' => 'xx-large',
            '7' => '300%',
            '-1' => 'small',
            '-2' => 'x-small',
            '+1' => 'large',
            '+2' => 'x-large',
            '+3' => 'xx-large',
            '+4' => '300%',
          );
          my $value = $hash{$size};
          if (!defined $value) {
            $value = 'medium';
          }
          $css .= 'font-size:'.$value.';';
        }
        if (defined $face) {
          if (lc($face) ne 'symbol') {
            $css .= 'font-family:'.$face.';';
          }
        }
        $replacement->setAttribute('style', $css);
      }
      if (defined $face && lc($face) eq 'symbol') {
        # convert all content to unicode
        my $next;
        for (my $child=$font->firstChild; defined $child; $child=$next) {
          $next = $child->nextSibling;
          if ($child->nodeType == XML_TEXT_NODE) {
            $child->setData($child->nodeValue =~ tr/ABGDEZHQIKLMNXOPRSTUFCYWabgdezhqiklmnxoprVstufcywJjv¡/ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθικλμνξοπρςστυφχψωϑϕϖϒ/);
          }
        }
      }
      # move all font children inside the replacement (span or fragment)
      my $next;
      for (my $child=$font->firstChild; defined $child; $child=$next) {
        $next = $child->nextSibling;
        $font->removeChild($child);
        $replacement->appendChild($child);
      }
      # replace the font node
      $font->parentNode->replaceChild($replacement, $font);
    }
  }
  $root->normalize();
}

# replaces all script[@type='loncapa/perl'] by a perl element
sub replace_script_by_perl {
  my ($root) = @_;
  my @scripts = $dom_doc->getElementsByTagName('script');
  foreach my $script (@scripts) {
    my $type = $script->getAttribute('type');
    if (defined $type && $type eq 'loncapa/perl') {
      my $perl = $dom_doc->createElement('perl');
      my $next;
      for (my $child=$script->firstChild; defined $child; $child=$next) {
        $next = $child->nextSibling;
        $script->removeChild($child);
        $perl->appendChild($child);
      }
      $script->parentNode->replaceChild($perl, $script);
    }
  }
}

# removes CDATA sections tags that have not been parsed correcty by the HTML parser
# also removes bad comments in script elements
sub remove_bad_cdata_sections {
  my ($root) = @_;
  foreach my $name (@preserve_elements) {
    my @nodes = $dom_doc->getElementsByTagName($name);
    foreach my $node (@nodes) {
      if (defined $node->firstChild && $node->firstChild->nodeType == XML_TEXT_NODE) {
        my $value = $node->firstChild->nodeValue;
        $value =~ s/^\s+|\s+$//g;
        if (index($value, '<![CDATA[') == 0) {
          $value = substr($value, length('<![CDATA['));
        }
        if (index($value, '<!--') == 0) {
          $value = substr($value, length('<!--'));
        }
        if (index($value, ']]>') == length($value) - length(']]>')) {
          $value = substr($value, 0, length($value) - length(']]>'));
        }
        if (index($value, '//-->') == length($value) - length('//-->')) {
          $value = substr($value, 0, length($value) - length('//-->'));
        }
        $value = "\n".$value."\n";
        $node->firstChild->setData($value);
      }
    }
  }
}

# try to fix table attributes
sub fix_tables {
  my ($root) = @_;
  my @tables = $dom_doc->getElementsByTagName('table');
  foreach my $table (@tables) {
    my $style = get_non_empty_attribute($table, 'style');
    my $align = get_non_empty_attribute($table, 'align');
    my $width = get_non_empty_attribute($table, 'width');
    my $height = get_non_empty_attribute($table, 'height');
    my $bgcolor = get_non_empty_attribute($table, 'bgcolor');
    $table->removeAttribute('align');
    $table->removeAttribute('width');
    $table->removeAttribute('height'); # no replacement for height
    $table->removeAttribute('bgcolor');
    my $css;
    if (defined $style) {
      $style =~ s/;$//;
      $css = $style.'; ';
    } else {
      $css = '';
    }
    if ($table->parentNode->nodeName eq 'center' || (defined $align && lc($align) eq 'center')) {
      $css .= 'margin-left:auto; margin-right:auto; ';
    }
    if (defined $align && (lc($align) eq 'left' || lc($align) eq 'right')) {
      $css .= 'float:'.lc($align).';';
    }
    if (defined $width) {
      $css .= 'width:';
      if ($width =~ /%/) {
        $css .= $width.'; ';
      } else {
        $css .= $width.'px; ';
      }
    }
    if (defined $bgcolor) {
      $css .= 'background-color:';
      if ($bgcolor =~ /^x/) {
        $css .= substr($bgcolor, 1).'; ';
      } else {
        $css .= $bgcolor.'; ';
      }
    }
    if ($css ne '') {
      $table->setAttribute('style', $css);
    }
  }
}

# replace center by a div or remove it if there is a table inside
sub replace_center {
  my ($root) = @_;
  my @centers = $dom_doc->getElementsByTagName('center');
  foreach my $center (@centers) {
    if ($center->getChildrenByTagName('table')->size() > 0) { # note: getChildrenByTagName is not DOM (LibXML specific)
      replace_by_children($center);
    } else {
      my $div = $dom_doc->createElement('div');
      $div->setAttribute('style', 'text-align: center; margin: 0 auto');
      my $next;
      for (my $child=$center->firstChild; defined $child; $child=$next) {
        $next = $child->nextSibling;
        $center->removeChild($child);
        $div->appendChild($child);
      }
      $center->parentNode->replaceChild($div, $center);
    }
  }
}

# calls fix_paragraphs for all children
sub fix_paragraphs_inside {
  my ($node) = @_;
  # blocks in which paragrahs will be added:
  my @blocks_with_p = ('problem','foil','item','hintgroup','hintpart','part','problemtype','window','block','while','postanswerdate','preduedate','solved','notsolved','languageblock','translated','lang','instructorcomment','windowlink','togglebox','standalone','div');
  if (in_array(\@blocks_with_p, $node->nodeName)) {
    # add a paragraph containing everything inside, paragraphs inside paragraphs will be fixed afterwards
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
  # now fix the paragraphs everywhere, so that all inline nodes are inside a paragraph, and block nodes are outside
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
  # inline elements that can be split in half if there is a paragraph inside (currently all HTML):
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
      if (!defined $left->firstChild->nextSibling &&
          $left->firstChild->nodeType == XML_TEXT_NODE && $left->firstChild->nodeValue =~ /^\s*$/) {
        # this was just blank text, it should not create a new paragraph
        my $first = $left->firstChild;
        $left->removeChild($first);
        $replacement->appendChild($first);
      } else {
        $replacement->appendChild($left);
      }
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

# removes empty style elements and replaces the ones with only whitespaces inside by their content
sub remove_empty_style {
  my ($root) = @_;
  # actually, preserve some elements like ins when they have whitespace, only remove if they are empty
  my @remove_if_empty = ('span', 'a', 'strong', 'em' , 'b', 'i', 'sup', 'sub', 'code', 'kbd', 'samp', 'tt', 'ins', 'del', 'var', 'small', 'big', 'font', 'u');
  my @remove_if_blank = ('span', 'strong', 'em' , 'b', 'i', 'sup', 'sub', 'var', 'small', 'big', 'font', 'u');
  foreach my $name (@remove_if_empty) {
    my @nodes = $dom_doc->getElementsByTagName($name);
    foreach my $node (@nodes) {
      if (!defined $node->firstChild) {
        $node->parentNode->removeChild($node);
      }
    }
  }
  foreach my $name (@remove_if_blank) {
    my @nodes = $dom_doc->getElementsByTagName($name);
    foreach my $node (@nodes) {
      if (defined $node->firstChild && !defined $node->firstChild->nextSibling && $node->firstChild->nodeType == XML_TEXT_NODE) {
        if ($node->firstChild->nodeValue =~ /^\s*$/) {
          replace_by_children($node);
        }
      }
    }
  }
  $root->normalize();
}

# pretty-print using im-memory DOM tree
sub pretty {
  my ($node, $indent_level) = @_;
  $indent_level ||= 0;
  my $type = $node->nodeType;
  if ($type == XML_ELEMENT_NODE) {
    my $name = $node->nodeName;
    if (in_array(\@all_block, $name) && !in_array(\@preserve_elements, $name)) {
      # make sure there is a newline at the beginning and at the end if there is anything inside
      if (defined $node->firstChild && !in_array(\@no_newline_inside, $name)) {
        my $first = $node->firstChild;
        if ($first->nodeType == XML_TEXT_NODE) {
          my $text = $first->nodeValue;
          if ($text !~ /^ *\n/) {
            $first->setData("\n" . $text);
          }
        } else {
          $node->insertBefore($dom_doc->createTextNode("\n"), $first);
        }
        my $last = $node->lastChild;
        if ($last->nodeType == XML_TEXT_NODE) {
          my $text = $last->nodeValue;
          if ($text !~ /\n *$/) {
            $last->setData($text . "\n");
          }
        } else {
          $node->appendChild($dom_doc->createTextNode("\n"));
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
                $prev->setData($text . $newline_indent);
              }
            } else {
              $node->insertBefore($dom_doc->createTextNode($newline_indent), $child);
            }
            if (defined $next && $next->nodeType == XML_TEXT_NODE) {
              my $text = $next->nodeValue;
              if ($text !~ /^ *\n/) {
                $next->setData($newline_indent . $text);
              }
            } else {
              $node->insertAfter($dom_doc->createTextNode($newline_indent), $child);
            }
          }
          pretty($child, $indent_level+1);
        } elsif ($child->nodeType == XML_TEXT_NODE) {
          my $text = $child->nodeValue;
          # collapse newlines
          $text =~ s/\n([\t ]*\n)+/\n/g;
          # indent
          if (defined $next) {
            $text =~ s/\n[\t ]*/$newline_indent/ge;
          } else {
            $text =~ s/\n[\t ]*/$newline_indent/ge;
            $text =~ s/\n[\t ]*$/$newline_indent_last/e;
          }
          $child->setData($text);
        }
      }
      
      # removes whitespace at the beginning and end of paragraphs
      if ($name eq 'p' && defined $node->firstChild && $node->firstChild->nodeType == XML_TEXT_NODE) {
        my $text = $node->firstChild->nodeValue;
        $text =~ s/^\s*//;
        if ($text eq '') {
          $node->removeChild($node->firstChild);
        } else {
          $node->firstChild->setData($text);
        }
      }
      if ($name eq 'p' && defined $node->lastChild && $node->lastChild->nodeType == XML_TEXT_NODE) {
        my $text = $node->lastChild->nodeValue;
        $text =~ s/\s*$//;
        if ($text eq '') {
          $node->removeChild($node->lastChild);
        } else {
          $node->lastChild->setData($text);
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
          $node->firstChild->setData($text);
        }
      }
      if (defined $node->lastChild && $node->lastChild->nodeType == XML_TEXT_NODE) {
        my $text = $node->lastChild->nodeValue;
        $text =~ s/\n( *\n)+$/\n/;
        if ($text eq '') {
          $node->removeChild($node->lastChild);
        } else {
          $node->lastChild->setData($text);
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

# replaces a node by its children
sub replace_by_children {
  my ($node) = @_;
  my $parent = $node->parentNode;
  my $next;
  for (my $child=$node->firstChild; defined $child; $child=$next) {
    $next = $child->nextSibling;
    $node->removeChild($child);
    $parent->insertBefore($child, $node);
  }
  $parent->removeChild($node);
}

# returns the trimmed attribute value if the attribute exists and is not blank, undef otherwise
sub get_non_empty_attribute {
  my ($node, $attribute_name) = @_;
  my $value = $node->getAttribute($attribute_name);
  if (defined $value && $value !~ /^\s*$/) {
    $value =~ s/^\s+|\s+$//g;
    return($value);
  }
  return(undef);
}
