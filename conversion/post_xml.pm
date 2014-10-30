#!/usr/bin/perl

package post_xml;

use strict;
use utf8;
use warnings;

use File::Basename;
use Cwd 'abs_path';
use XML::LibXML;
use HTML::TokeParser; # used to parse sty files
use Tie::IxHash; # for ordered hashes

use Env qw(RES_DIR); # path of res directory parent (without the / at the end)

no warnings 'recursion'; # yes, fix_paragraph is using heavy recursion, I know

# these are constants
my @block_elements = ('loncapa','parameter','location','answer','foil','image','polygon','rectangle','text','conceptgroup','itemgroup','item','label','data','function','array','unit','answergroup','functionplotresponse','functionplotruleset','functionplotelements','functionplotcustomrule','essayresponse','hintpart','formulahint','numericalhint','reactionhint','organichint','optionhint','radiobuttonhint','stringhint','customhint','mathhint','imageresponse','foilgroup','datasubmission','textfield','hiddensubmission','radiobuttonresponse','rankresponse','matchresponse','import','script','window','block','library','notsolved','part','postanswerdate','preduedate','problem','problemtype','randomlabel','bgimg','labelgroup','randomlist','solved','while','tex','web','gnuplot','curve','Task','IntroParagraph','ClosingParagraph','Question','QuestionText','Setup','Instance','InstanceText','Criteria','CriteriaText','GraderNote','languageblock','translated','lang','instructorcomment','dataresponse','togglebox','standalone','comment','drawimage','allow','displayduedate','displaytitle','responseparam','organicstructure','scriptlib','parserlib','drawoptionlist','spline','backgroundplot','plotobject','plotvector','drawvectorsum','functionplotrule','functionplotvectorrule','functionplotvectorsumrule','axis','key','xtics','ytics','title','xlabel','ylabel','hiddenline','htmlhead','htmlbody','lcmeta','perl');
my @inline_like_block = ('stringresponse','optionresponse','numericalresponse','formularesponse','mathresponse','organicresponse','reactionresponse','customresponse','externalresponse', 'hint', 'hintgroup'); # inline elements treated like blocks for pretty print and some other things
my @responses = ('stringresponse','optionresponse','numericalresponse','formularesponse','mathresponse','organicresponse','reactionresponse','customresponse','externalresponse','essayresponse','radiobuttonresponse','matchresponse','rankresponse','imageresponse','functionplotresponse');
my @block_html = ('html','head','body','section','h1','h2','h3','h4','h5','h6','div','p','ul','ol','li','table','tbody','tr','td','th','dl','dt','dd','pre','noscript','hr','blockquote','object','applet','embed','map','form','fieldset','iframe','center');
my @no_newline_inside = ('import','parserlib','scriptlib','data','function','label','xlabel','ylabel','tic','text','rectangle','image','title','h1','h2','h3','h4','h5','h6','li','td','p');
my @preserve_elements = ('script','answer','perl');


# Parses the XML document and fixes many things to turn it into a LON-CAPA 3 document
# Returns the text of the document.
sub post_xml {
  my ($textref, $new_path) = @_;
  
  my $dom_doc = XML::LibXML->load_xml(string => $textref);

  my $root = create_new_structure($dom_doc);

  remove_elements($root, ['startouttext','startoutext','endouttext','endoutext','startpartmarker','endpartmarker','displayweight','displaystudentphoto','basefont','displaytitle','displayduedate','allow']);

  my @all_block = (@block_elements, @block_html);
  add_sty_blocks($new_path, $root, \@all_block); # must come before the subs using @all_block

  fix_block_styles($root, \@all_block);
  $root->normalize();

  fix_fonts($root, \@all_block);
  
  replace_u($root);

  replace_responseparam($root);
  
  replace_script_by_perl($root);

  remove_bad_cdata_sections($root);

  fix_style_element($root);
  
  fix_tables($root);

  fix_lists($root);

  replace_deprecated_attributes_by_css($root);
  
  replace_center($root, \@all_block); # must come after replace_deprecated_attributes_by_css
  
  fix_parts($root);
  
  fix_paragraphs_inside($root, \@all_block);

  change_hints($root); # after fix_paragraphs_inside to avoid problems with hintgroup/p/hintpart
  
  remove_empty_style($root);

  fix_empty_lc_elements($root);

  pretty($root, \@all_block);

  open my $out, '>', $new_path;
  print $out $dom_doc->toString(); # byte string !
  close $out;
}

sub create_new_structure {
  my ($doc) = @_;
  # the 'loncapa' root element has already been added in pre_xml
  my $root = $doc->documentElement;
  # replace html elements by the content
  my @htmls = $doc->getElementsByTagName('html');
  foreach my $html (@htmls) {
    replace_by_children($html);
  }
  # replace head by htmlhead, insert all style elements inside
  my $current_node = undef;
  my @heads = $doc->getElementsByTagName('head');
  my @styles = $doc->getElementsByTagName('style');
  if (scalar(@heads) > 0 || scalar(@styles) > 0) {
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
    foreach my $style (@styles) {
      $style->parentNode->removeChild($style);
      $htmlhead->appendChild($style);
    }
    insert_after_or_first($root, $htmlhead, $current_node);
    $current_node = $htmlhead;
  }
  # replace a body with attributes by an empty htmlbody with the same attributes
  my $htmlbody = undef;
  my @bodies = $doc->getElementsByTagName('body');
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
  my @metas = $doc->getElementsByTagName('meta');
  foreach my $meta (@metas) {
    $meta->parentNode->removeChild($meta);
    my $name = $meta->getAttribute('name');
    my $content = $meta->getAttribute('content');
    if (defined $name && defined $content && string_in_array(\@meta_names, lc($name))) {
      my $lcmeta = $doc->createElement('lcmeta');
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
      if (string_in_array($to_remove, $child->nodeName)) {
        $node->removeChild($child);
      } else {
        remove_elements($child, $to_remove);
      }
    }
  }
}

# use the linked sty files to guess which newly defined elements should be considered blocks
# @param {string} fn - the clean .problem file path (we only extract the directory path from it)
sub add_sty_blocks {
  my ($fn, $root, $all_block) = @_;
  my $doc = $root->ownerDocument;
  my @parserlibs = $doc->getElementsByTagName('parserlib');
  my @libs = ();
  foreach my $parserlib (@parserlibs) {
    if (defined $parserlib->firstChild && $parserlib->firstChild->nodeType == XML_TEXT_NODE) {
      my $value = $parserlib->firstChild->nodeValue;
      $value =~ s/^\s+|\s+$//g;
      if ($value ne '') {
        push(@libs, $value);
      }
    }
  }
  my ($name, $path, $suffix) = fileparse($fn);
  foreach my $sty (@libs) {
    if (substr($sty, 0, 1) eq '/') {
      $sty = $RES_DIR.$sty;
    } else {
      $sty = $path.$sty;
    }
    my $new_elements = parse_sty($sty, $all_block);
    better_guess($root, $new_elements, $all_block);
    my $new_blocks = $new_elements->{'block'};
    my $new_inlines = $new_elements->{'inline'};
    push(@$all_block, @{$new_blocks});
    #push(@inlines, @{$new_inlines}); # we are not using a list of inline elements at this point
  }
}

##
# Parses a sty file and returns lists of block and inline elements.
# @param {string} fn - the file path
##
sub parse_sty {
  my ($fn, $all_block) = @_;
  my @blocks = ();
  my @inlines = ();
  my $p = HTML::TokeParser->new($fn);
  if (! $p) {
    die "post_xml.pl: parse_sty: Error reading $fn\n";
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
        if (string_in_array($all_block, $tag)) {
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
# marks as block the elements that contain block elements in the input file
# @param {string} fn - the file path
# @param {Hash<string,Array>} new_elements - contains arrays in 'block' and 'inline'
##
sub better_guess {
  my ($root, $new_elements, $all_block) = @_;
  my $new_blocks = $new_elements->{'block'};
  my $new_inlines = $new_elements->{'inline'};
  
  my @change = (); # change these elements from inline to block
  foreach my $tag (@{$new_inlines}) {
    my @nodes = $root->getElementsByTagName($tag);
    NODE_LOOP: foreach my $node (@nodes) {
      for (my $child=$node->firstChild; defined $child; $child=$child->nextSibling) {
        if ($child->nodeType == XML_ELEMENT_NODE) {
          if (string_in_array($all_block, $child->nodeName) || string_in_array($new_blocks, $child->nodeName)) {
            push(@change, $tag);
            last NODE_LOOP;
          }
        }
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

# When a style element contains a block, move the style inside the block where it is allowed.
# style/block/other -> block/style/other
# When a style is used where it is not allowed, move it inside its children or remove it.
# element_not_containing_styles/style/other -> element_not_containing_styles/other/style (except if other is a style)
# The fix is not perfect in the case of element_not_containing_styles/style1/style2/block/text (style1 will be lost):
# element_not_containing_styles/style1/style2/block/text -> element_not_containing_styles/block/style2/text
# (a solution to this problem would be to merge the styles in a span)
# NOTE: .sty defined elements are not considered like elements containing styles
sub fix_block_styles {
  my ($element, $all_block) = @_;
  my $doc = $element->ownerDocument;
  # list of elements that can contain style elements:
  my @containing_styles = ('loncapa','problem','foil','item','text','hintgroup','hintpart','label','part','preduedate','postanswerdate','solved','notsolved','block','while','web','standalone','problemtype','languageblock','translated','lang','window','windowlink','togglebox','instructorcomment','section','div','p','li','dd','td','th','blockquote','object','applet','video','audio','canvas','fieldset','button',
  'span','strong','em','b','i','sup','sub','code','kbd','samp','tt','ins','del','var','small','big','u','font');
  my @styles = ('span', 'strong', 'em' , 'b', 'i', 'sup', 'sub', 'tt', 'var', 'small', 'big', 'u');
  if (string_in_array(\@styles, $element->nodeName)) {
    # move spaces out of the style element
    if (defined $element->firstChild && $element->firstChild->nodeType == XML_TEXT_NODE) {
      my $child = $element->firstChild;
      if ($child->nodeValue =~ /^(\s+)(\S.*)$/s) {
        $element->parentNode->insertBefore($doc->createTextNode($1), $element);
        $child->setData($2);
      }
    }
    if (defined $element->lastChild && $element->lastChild->nodeType == XML_TEXT_NODE) {
      my $child = $element->lastChild;
      if ($child->nodeValue =~ /^(.*\S)(\s+)$/s) {
        $element->parentNode->insertAfter($doc->createTextNode($2), $element);
        $child->setData($1);
      }
    }
    
    my $found_block = 0;
    for (my $child=$element->firstChild; defined $child; $child=$child->nextSibling) {
      if ($child->nodeType == XML_ELEMENT_NODE && string_in_array($all_block, $child->nodeName)) {
        $found_block = 1;
        last;
      }
    }
    my $no_style_here = !string_in_array(\@containing_styles, $element->parentNode->nodeName);
    if ($found_block || $no_style_here) {
      # there is a block or the style is not allowed here,
      # the style element has to be replaced by its modified children
      my $s; # a clone of the style
      my $next;
      for (my $child=$element->firstChild; defined $child; $child=$next) {
        $next = $child->nextSibling;
        if ($child->nodeType == XML_ELEMENT_NODE && (string_in_array($all_block, $child->nodeName) ||
            $child->nodeName eq 'br' || $no_style_here)) {
          # avoid inverting a style with a style with $no_style_here (that would cause endless recursion)
          if (!$no_style_here || !string_in_array(\@styles, $child->nodeName)) {
            # block node or inline node when the style is not allowed:
            # move all children inside the style, and make the style the only child
            $s = $element->cloneNode();
            my $next2;
            for (my $child2=$child->firstChild; defined $child2; $child2=$next2) {
              $next2 = $child2->nextSibling;
              $child->removeChild($child2);
              $s->appendChild($child2);
            }
            $child->appendChild($s);
          }
          $s = undef;
        } elsif (($child->nodeType == XML_TEXT_NODE && $child->nodeValue !~ /^\s*$/) ||
            $child->nodeType == XML_ELEMENT_NODE) {
          # if the style is allowed, move text and inline nodes inside the style
          if (!$no_style_here) {
            if (!defined $s) {
              $s = $element->cloneNode();
              $element->insertBefore($s, $child);
            }
            $element->removeChild($child);
            $s->appendChild($child);
          }
        } else {
          # do not put other nodes inside the style
          $s = undef;
        }
      }
      # now replace by children and fix them
      my $parent = $element->parentNode;
      for (my $child=$element->firstChild; defined $child; $child=$next) {
        $next = $child->nextSibling;
        $element->removeChild($child);
        $parent->insertBefore($child, $element);
        if ($child->nodeType == XML_ELEMENT_NODE) {
          fix_block_styles($child, $all_block);
        }
      }
      $parent->removeChild($element);
      return;
    }
  }
  # otherwise fix all children
  my $next;
  for (my $child=$element->firstChild; defined $child; $child=$next) {
    $next = $child->nextSibling;
    if ($child->nodeType == XML_ELEMENT_NODE) {
      fix_block_styles($child, $all_block);
    }
  }
}

# removes empty font elements and font elements that contain at least one block element
# replaces other font elements by equivalent span
sub fix_fonts {
  my ($root, $all_block) = @_;
  my $doc = $root->ownerDocument;
  my @fonts = $root->getElementsByTagName('font');
  foreach my $font (@fonts) {
    my $block = 0;
    for (my $child=$font->firstChild; defined $child; $child=$child->nextSibling) {
      if (string_in_array($all_block, $child->nodeName) || string_in_array(\@inline_like_block, $child->nodeName)) {
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
      if (defined $face) {
        $face =~ s/^,|,$//;
      }
      if (!defined $color && !defined $size && !defined $face) {
        # useless font element: replace this node by its content
        replace_by_children($font);
        next;
      }
      my $replacement;
      if (!defined $color && !defined $size && defined $face && lc($face) eq 'symbol') {
        $replacement = $doc->createDocumentFragment();
      } else {
        $replacement = $doc->createElement('span');
        tie (my %properties, 'Tie::IxHash', ());
        my $css = '';
        if (defined $color) {
          $color =~ s/^x//;
          $properties{'color'} = $color;
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
          $properties{'font-size'} = $value;
        }
        if (defined $face) {
          if (lc($face) ne 'symbol' && lc($face) ne 'bold') {
            $properties{'font-family'} = $face;
          }
        }
        set_css_properties($replacement, \%properties);
      }
      if (defined $face && lc($face) eq 'symbol') {
        # convert all content to unicode
        my $next;
        for (my $child=$font->firstChild; defined $child; $child=$next) {
          $next = $child->nextSibling;
          if ($child->nodeType == XML_TEXT_NODE) {
            my $value = $child->nodeValue;
            $value =~ tr/ABGDEZHQIKLMNXOPRSTUFCYWabgdezhqiklmnxoprVstufcywJjv¡«¬®/ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθικλμνξοπρςστυφχψωϑϕϖϒ↔←→/;
            $child->setData($value);
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

# replaces u by <span style="text-decoration: underline">
sub replace_u {
  my ($root) = @_;
  my $doc = $root->ownerDocument;
  my @us = $root->getElementsByTagName('u');
  foreach my $u (@us) {
    my $span = $doc->createElement('span');
    $span->setAttribute('style', 'text-decoration: underline');
    my $next;
    for (my $child=$u->firstChild; defined $child; $child=$next) {
      $next = $child->nextSibling;
      $u->removeChild($child);
      $span->appendChild($child);
    }
    $u->parentNode->replaceChild($span, $u);
  }
}

# replace responseparam by parameter
sub replace_responseparam {
  my ($root) = @_;
  my @responseparams = $root->getElementsByTagName('responseparam');
  foreach my $responseparam (@responseparams) {
    $responseparam->setNodeName('parameter');
  }
}

# replaces all script[@type='loncapa/perl'] by a perl element
sub replace_script_by_perl {
  my ($root) = @_;
  my $doc = $root->ownerDocument;
  my @scripts = $root->getElementsByTagName('script');
  foreach my $script (@scripts) {
    my $type = $script->getAttribute('type');
    if (defined $type && $type eq 'loncapa/perl') {
      my $perl = $doc->createElement('perl');
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
    my @nodes = $root->getElementsByTagName($name);
    foreach my $node (@nodes) {
      if (defined $node->firstChild && $node->firstChild->nodeType == XML_TEXT_NODE) {
        my $value = $node->firstChild->nodeValue;
        # at the beginning:
        $value =~ s/^(\s*)<!\[CDATA\[/$1/; # <![CDATA[
        $value =~ s/^(\s*)\/\*\s*<!\[CDATA\[\s*\*\//$1/; # /* <![CDATA[ */
        $value =~ s/^(\s*)(\/\/)?\s*<!--/$1/; # // <!--
        # at the end:
        $value =~ s/\]\]>(\s*)$/$1/; # ]]>
        $value =~ s/(\/\/)?\s*-->(\s*)$/$2/; # // -->
        $value =~ s/\/\*\s*\]\]>\s*\*\/(\s*)$/$1/; # /* ]]> */
        
        $value = "\n".$value."\n";
        $value =~ s/\s*(\n[ \t]*)/$1/;
        $value =~ s/\s+$/\n/;
        $node->firstChild->setData($value);
      }
    }
  }
}

# removes "<!--" and "-->" at the beginning and end of style elements
sub fix_style_element {
  my ($root) = @_;
  my @styles = $root->getElementsByTagName('style');
  foreach my $style (@styles) {
    if (defined $style->firstChild && $style->firstChild->nodeType == XML_TEXT_NODE &&
        !defined $style->firstChild->nextSibling) {
      my $text = $style->firstChild->nodeValue;
      if ($text =~ /^\s*<!--(.*)-->\s*$/s) {
        $style->firstChild->setData($1);
      }
    }
  }
}

# create missing cells at the end of table rows
sub fix_tables {
  my ($root) = @_;
  my @tables = $root->getElementsByTagName('table');
  foreach my $table (@tables) {
    fix_cells($table);
    foreach my $tbody ($table->getChildrenByTagName('tbody')) {
      fix_cells($tbody);
    }
    foreach my $thead ($table->getChildrenByTagName('thead')) {
      fix_cells($thead);
    }
    foreach my $tfoot ($table->getChildrenByTagName('tfoot')) {
      fix_cells($tfoot);
    }
  }
}

# create missing cells at the end of table rows
sub fix_cells {
  my ($table) = @_; # could actually be table, tbody, thead or tfoot
  my $doc = $table->ownerDocument;
  my @nb_cells = ();
  my $max_nb_cells = 0;
  my @rowspans = ();
  my @trs = $table->getChildrenByTagName('tr');
  foreach my $tr (@trs) {
    my $nb_cells;
    if (defined $rowspans[0]) {
      $nb_cells = shift(@rowspans);
    } else {
      $nb_cells = 0;
    }
    for (my $cell=$tr->firstChild; defined $cell; $cell=$cell->nextSibling) {
      if ($cell->nodeName eq 'td' || $cell->nodeName eq 'th') {
        my $colspan = $cell->getAttribute('colspan');
        if (defined $colspan && $colspan =~ /^\s*[0-9]+\s*$/) {
          $nb_cells += $colspan;
        } else {
          $nb_cells++;
        }
        my $rowspan = $cell->getAttribute('rowspan');
        if (defined $rowspan && $rowspan =~ /^\s*[0-9]+\s*$/) {
          for (my $i=0; $i < $rowspan-1; $i++) {
            if (!defined $rowspans[$i]) {
              $rowspans[$i] = 1;
            } else {
              $rowspans[$i]++;
            }
          }
        }
      }
    }
    push(@nb_cells, $nb_cells);
    if ($nb_cells > $max_nb_cells) {
      $max_nb_cells = $nb_cells;
    }
  }
  foreach my $tr (@trs) {
    my $nb_cells = shift(@nb_cells);
    if ($nb_cells < $max_nb_cells) {
      for (1..($max_nb_cells - $nb_cells)) {
        $tr->appendChild($doc->createElement('td'));
      }
    }
  }
}

# replaces ul/ul by ul/li/ul and the same for ol (using the previous li if possible)
# also adds a ul element when a li has no ul/ol ancestor
sub fix_lists {
  my ($root) = @_;
  my $doc = $root->ownerDocument;
  my @uls = $root->getElementsByTagName('ul');
  my @ols = $root->getElementsByTagName('ol');
  my @lists = (@uls, @ols);
  foreach my $list (@lists) {
    my $next;
    for (my $child=$list->firstChild; defined $child; $child=$next) {
      $next = $child->nextSibling;
      if ($child->nodeType == XML_ELEMENT_NODE && string_in_array(['ul','ol'], $child->nodeName)) {
        my $previous = $child->previousNonBlankSibling(); # note: non-DOM method
        $list->removeChild($child);
        if (defined $previous && $previous->nodeType == XML_ELEMENT_NODE && $previous->nodeName eq 'li') {
          $previous->appendChild($child);
        } else {
          my $li = $doc->createElement('li');
          $li->appendChild($child);
          if (!defined $next) {
            $list->appendChild($li);
          } else {
            $list->insertBefore($li, $next);
          }
        }
      }
    }
  }
  my @lis = $root->getElementsByTagName('li');
  foreach my $li (@lis) {
    my $found_list_ancestor = 0;
    my $ancestor = $li->parentNode;
    while (defined $ancestor) {
      if ($ancestor->nodeName eq 'ul' || $ancestor->nodeName eq 'ol') {
        $found_list_ancestor = 1;
        last;
      }
      $ancestor = $ancestor->parentNode;
    }
    if (!$found_list_ancestor) {
      # replace li by ul and add li under ul
      my $ul = $doc->createElement('ul');
      $li->parentNode->insertBefore($ul, $li);
      $li->parentNode->removeChild($li);
      $ul->appendChild($li);
      # add all other li afterwards inside ul (there might be text nodes in-between)
      my $next = $ul->nextSibling;
      while (defined $next) {
        my $next_next = $next->nextSibling;
        if ($next->nodeType == XML_TEXT_NODE && $next->nodeValue =~ /^\s*$/ &&
            defined $next_next && $next_next->nodeType == XML_ELEMENT_NODE && $next_next->nodeName eq 'li') {
          $next->parentNode->removeChild($next);
          $ul->appendChild($next);
          $next = $next_next;
          $next_next = $next_next->nextSibling;
        }
        if ($next->nodeType == XML_ELEMENT_NODE && $next->nodeName eq 'li') {
          $next->parentNode->removeChild($next);
          $ul->appendChild($next);
        } else {
          last;
        }
        $next = $next_next;
      }
    }
  }
}

# Replaces many deprecated attributes and replaces them by equivalent CSS when possible
sub replace_deprecated_attributes_by_css {
  my ($root) = @_;
  
  fix_deprecated_in_tables($root);
  
  fix_deprecated_in_table_rows($root);
  
  fix_deprecated_in_table_cells($root);
  
  fix_deprecated_in_lists($root);
  
  fix_deprecated_in_list_items($root);
  
  fix_deprecated_in_hr($root);
  
  fix_deprecated_in_img($root);
  
  fix_deprecated_in_body($root);
  
  fix_align_attribute($root);
}

# Replaces deprecated attributes in tables
sub fix_deprecated_in_tables {
  my ($root) = @_;
  my @tables = $root->getElementsByTagName('table');
  foreach my $table (@tables) {
    tie (my %new_properties, 'Tie::IxHash', ());
    my $align = $table->getAttribute('align');
    if (defined $align) {
      $table->removeAttribute('align');
      $align = lc(trim($align));
    }
    if ($table->parentNode->nodeName eq 'center' || (defined $align && $align eq 'center') ||
        (defined $table->parentNode->getAttribute('align') && $table->parentNode->getAttribute('align') eq 'center')) {
      $new_properties{'margin-left'} = 'auto';
      $new_properties{'margin-right'} = 'auto';
    }
    if (defined $align && ($align eq 'left' || $align eq 'right')) {
      $new_properties{'float'} = $align;
    }
    my $width = $table->getAttribute('width');
    if (defined $width) {
      $table->removeAttribute('width');
      $width = trim($width);
      if ($width =~ /^[0-9]+$/) {
        $width .= 'px';
      }
      if ($width ne '') {
        $new_properties{'width'} = $width;
      }
    }
    my $height = $table->getAttribute('height');
    if (defined $height) {
      $table->removeAttribute('height');
      # no replacement for table height
    }
    my $bgcolor = $table->getAttribute('bgcolor');
    if (defined $bgcolor) {
      $table->removeAttribute('bgcolor');
      $bgcolor = trim($bgcolor);
      $bgcolor =~ s/^x\s*//;
      if ($bgcolor ne '') {
        $new_properties{'background-color'} = $bgcolor;
      }
    }
    my $frame = $table->getAttribute('frame');
    if (defined $frame) {
      $table->removeAttribute('frame');
      $frame = lc(trim($frame));
      if ($frame eq 'void') {
        $new_properties{'border'} = 'none';
      } elsif ($frame eq 'above') {
        $new_properties{'border-top'} = '1px solid black';
      } elsif ($frame eq 'below') {
        $new_properties{'border-bottom'} = '1px solid black';
      } elsif ($frame eq 'hsides') {
        $new_properties{'border-top'} = '1px solid black';
        $new_properties{'border-bottom'} = '1px solid black';
      } elsif ($frame eq 'vsides') {
        $new_properties{'border-left'} = '1px solid black';
        $new_properties{'border-right'} = '1px solid black';
      } elsif ($frame eq 'lhs') {
        $new_properties{'border-left'} = '1px solid black';
      } elsif ($frame eq 'rhs') {
        $new_properties{'border-right'} = '1px solid black';
      } elsif ($frame eq 'box') {
        $new_properties{'border'} = '1px solid black';
      } elsif ($frame eq 'border') {
        $new_properties{'border'} = '1px solid black';
      }
    }
    if (scalar(keys %new_properties) > 0) {
      set_css_properties($table, \%new_properties);
    }
    # we can't replace the border attribute without creating a style block, but we can improve things like border="BORDER"
    my $border = $table->getAttribute('border');
    if (defined $border) {
      $border = trim($border);
      if ($border !~ /^\s*[0-9]+\s*(px)?\s*$/) {
        $table->setAttribute('border', '1');
      }
    }
  }
  
}

# Replaces deprecated attributes in tr elements
sub fix_deprecated_in_table_rows {
  my ($root) = @_;
  my @trs = $root->getElementsByTagName('tr');
  foreach my $tr (@trs) {
    my $old_properties = get_css_properties($tr);
    tie (my %new_properties, 'Tie::IxHash', ());
    my $bgcolor = $tr->getAttribute('bgcolor');
    if (defined $bgcolor) {
      $tr->removeAttribute('bgcolor');
      if (!defined $old_properties->{'background-color'}) {
        $bgcolor = trim($bgcolor);
        $bgcolor =~ s/^x\s*//;
        if ($bgcolor ne '') {
          $new_properties{'background-color'} = $bgcolor;
        }
      }
    }
    my $align = $tr->getAttribute('align');
    if (defined $align && $align !~ /\s*char\s*/i) {
      $tr->removeAttribute('align');
      if (!defined $old_properties->{'text-align'}) {
        $align = trim($align);
        if ($align ne '') {
          $new_properties{'text-align'} = $align;
        }
      }
    }
    my $valign = $tr->getAttribute('valign');
    if (defined $valign) {
      $tr->removeAttribute('valign');
      if (!defined $old_properties->{'vertical-align'}) {
        $valign = trim($valign);
        if ($valign ne '') {
          $new_properties{'vertical-align'} = $valign;
        }
      }
    }
    if (scalar(keys %new_properties) > 0) {
      set_css_properties($tr, \%new_properties);
    }
  }
}

# Replaces deprecated attributes in table cells (td and th)
sub fix_deprecated_in_table_cells {
  my ($root) = @_;
  my @tds = $root->getElementsByTagName('td');
  my @ths = $root->getElementsByTagName('th');
  my @cells = (@tds, @ths);
  foreach my $cell (@cells) {
    my $old_properties = get_css_properties($cell);
    tie (my %new_properties, 'Tie::IxHash', ());
    my $width = $cell->getAttribute('width');
    if (defined $width) {
      $cell->removeAttribute('width');
      if (!defined $old_properties->{'width'}) {
        $width = trim($width);
        if ($width =~ /^[0-9]+$/) {
          $width .= 'px';
        }
        if ($width ne '') {
          $new_properties{'width'} = $width;
        }
      }
    }
    my $height = $cell->getAttribute('height');
    if (defined $height) {
      $cell->removeAttribute('height');
      if (!defined $old_properties->{'height'}) {
        $height = trim($height);
        if ($height =~ /^[0-9]+$/) {
          $height .= 'px';
        }
        if ($height ne '') {
          $new_properties{'height'} = $height;
        }
      }
    }
    my $bgcolor = $cell->getAttribute('bgcolor');
    if (defined $bgcolor) {
      $cell->removeAttribute('bgcolor');
      if (!defined $old_properties->{'background-color'}) {
        $bgcolor = trim($bgcolor);
        $bgcolor =~ s/^x\s*//;
        if ($bgcolor ne '') {
          $new_properties{'background-color'} = $bgcolor;
        }
      }
    }
    my $align = $cell->getAttribute('align');
    if (defined $align && $align !~ /\s*char\s*/i) {
      $cell->removeAttribute('align');
      if (!defined $old_properties->{'text-align'}) {
        $align = trim($align);
        if ($align ne '') {
          $new_properties{'text-align'} = $align;
        }
      }
    }
    my $valign = $cell->getAttribute('valign');
    if (defined $valign) {
      $cell->removeAttribute('valign');
      if (!defined $old_properties->{'vertical-align'}) {
        $valign = trim($valign);
        if ($valign ne '') {
          $new_properties{'vertical-align'} = $valign;
        }
      }
    }
    if (scalar(keys %new_properties) > 0) {
      set_css_properties($cell, \%new_properties);
    }
  }
}

# Replaces deprecated attributes in lists (ul and ol)
sub fix_deprecated_in_lists {
  my ($root) = @_;
  my @uls = $root->getElementsByTagName('ul');
  my @ols = $root->getElementsByTagName('ol');
  my @lists = (@uls, @ols);
  foreach my $list (@lists) {
    my $type = $list->getAttribute('type');
    if (defined $type) {
      my $lst = list_style_type($type);
      if (defined $lst) {
        $list->removeAttribute('type');
        if (!defined get_css_property($list, 'list-style-type')) {
          set_css_property($list, 'list-style-type', $lst);
        }
      }
    }
  }
}

# Replaces deprecated attributes in list items (li)
sub fix_deprecated_in_list_items {
  my ($root) = @_;
  my @lis = $root->getElementsByTagName('li');
  foreach my $li (@lis) {
    my $type = $li->getAttribute('type');
    if (defined $type) {
      my $lst = list_style_type($type);
      if (defined $lst) {
        $li->removeAttribute('type');
        if (!defined get_css_property($li, 'list-style-type')) {
          set_css_property($li, 'list-style-type', $lst);
        }
      }
    }
  }
}

# returns the CSS list-style-type value equivalent to the given type attribute for a list or list item
sub list_style_type {
  my ($type) = @_;
  my $value;
  $type = trim($type);
  if (lc($type) eq 'circle') {
    $value = 'circle';
  } elsif (lc($type) eq 'disc') {
    $value = 'disc';
  } elsif (lc($type) eq 'square') {
    $value = 'square';
  } elsif ($type eq 'a') {
    $value = 'lower-latin';
  } elsif ($type eq 'A') {
    $value = 'upper-latin';
  } elsif ($type eq 'i') {
    $value = 'lower-roman';
  } elsif ($type eq 'I') {
    $value = 'upper-roman';
  } elsif ($type eq '1') {
    $value = 'decimal';
  }
  return $value;
}

# Replaces deprecated attributes in hr
sub fix_deprecated_in_hr {
  my ($root) = @_;
  my @hrs = $root->getElementsByTagName('hr');
  foreach my $hr (@hrs) {
    tie (my %new_properties, 'Tie::IxHash', ());
    my $align = $hr->getAttribute('align');
    if (defined $align) {
      $align = lc(trim($align));
      if ($align eq 'left') {
        $new_properties{'text-align'} = 'left';
        $new_properties{'margin-left'} = '0';
      } elsif ($align eq 'right') {
        $new_properties{'text-align'} = 'right';
        $new_properties{'margin-right'} = '0';
      }
      $hr->removeAttribute('align');
    }
    my $color = $hr->getAttribute('color');
    if (defined $color) {
      $color = trim($color);
      $color =~ s/^x\s*//;
      if ($color ne '') {
        $new_properties{'color'} = $color;
        $new_properties{'background-color'} = $color;
      }
      $hr->removeAttribute('color');
    }
    my $noshade = $hr->getAttribute('noshade');
    my $size = $hr->getAttribute('size');
    if (defined $noshade) {
      $new_properties{'border-width'} = '0';
      if (!defined $color) {
        $new_properties{'color'} = 'gray';
        $new_properties{'background-color'} = 'gray';
      }
      if (!defined $size) {
        $size = '2';
      }
      $hr->removeAttribute('noshade');
    }
    if (defined $size) {
      $size = trim($size);
      if ($size ne '') {
        $new_properties{'height'} = $size.'px';
      }
      if (defined $hr->getAttribute('size')) {
        $hr->removeAttribute('size');
      }
    }
    my $width = $hr->getAttribute('width');
    if (defined $width) {
      $width = trim($width);
      if ($width ne '') {
        if ($width !~ /\%$/) {
          $width .= 'px';
        }
        $new_properties{'width'} = $width;
      }
      $hr->removeAttribute('width');
    }
    if (scalar(keys %new_properties) > 0) {
      set_css_properties($hr, \%new_properties);
    }
  }
}

# Replaces deprecated attributes in img
sub fix_deprecated_in_img {
  my ($root) = @_;
  my @imgs = $root->getElementsByTagName('img');
  foreach my $img (@imgs) {
    my $old_properties = get_css_properties($img);
    tie (my %new_properties, 'Tie::IxHash', ());
    my $align = $img->getAttribute('align');
    if (defined $align) {
      $align = lc(trim($align));
      if ($align eq 'middle' || $align eq 'top' || $align eq 'bottom') {
        $img->removeAttribute('align');
        if (!defined $old_properties->{'vertical-align'}) {
          $new_properties{'vertical-align'} = $align;
        }
      } elsif ($align eq 'left' || $align eq 'right') {
        $img->removeAttribute('align');
        if (!defined $old_properties->{'float'}) {
          $new_properties{'float'} = $align;
        }
      } elsif ($align eq '') {
        $img->removeAttribute('align');
      }
    }
    my $border = $img->getAttribute('border');
    if (defined $border) {
      $border = lc(trim($border));
      if ($border =~ /^[0-9]+\s*(px)?$/) {
        $img->removeAttribute('border');
        if (!defined $old_properties->{'border'}) {
          if ($border !~ /px$/) {
            $border .= 'px';
          }
          $new_properties{'border'} = $border.' solid black';
        }
      }
    }
    my $hspace = $img->getAttribute('hspace');
    if (defined $hspace) {
      $hspace = lc(trim($hspace));
      if ($hspace =~ /^[0-9]+\s*(px)?$/) {
        $img->removeAttribute('hspace');
        if (!defined $old_properties->{'margin-left'} || !defined $old_properties->{'margin-right'}) {
          if ($hspace !~ /px$/) {
            $hspace .= 'px';
          }
          $new_properties{'margin-left'} = $hspace;
          $new_properties{'margin-right'} = $hspace;
        }
      }
    }
    if (scalar(keys %new_properties) > 0) {
      set_css_properties($img, \%new_properties);
    }
  }
}

# Replaces deprecated attributes in htmlbody (the style attribute could be used in a div for output)
sub fix_deprecated_in_body {
  my ($root) = @_;
  my @bodies = $root->getElementsByTagName('htmlbody');
  foreach my $body (@bodies) {
    my $old_properties = get_css_properties($body);
    tie (my %new_properties, 'Tie::IxHash', ());
    my $bgcolor = $body->getAttribute('bgcolor');
    if (defined $bgcolor) {
      $body->removeAttribute('bgcolor');
      if (!defined $old_properties->{'background-color'}) {
        $bgcolor = trim($bgcolor);
        $bgcolor =~ s/^x\s*//;
        if ($bgcolor ne '') {
          $new_properties{'background-color'} = $bgcolor;
        }
      }
    }
    if (scalar(keys %new_properties) > 0) {
      set_css_properties($body, \%new_properties);
    }
  }
}

# replaces <div align="center"> by <div style="text-align:center;">
# also for p and h1..h6
sub fix_align_attribute {
  my ($root) = @_;
  my @nodes = $root->getElementsByTagName('div');
  push(@nodes, $root->getElementsByTagName('p'));
  for (my $i=1; $i<=6; $i++) {
    push(@nodes, $root->getElementsByTagName('h'.$i));
  }
  foreach my $node (@nodes) {
    my $align = $node->getAttribute('align');
    if (defined $align) {
      $node->removeAttribute('align');
      $align = trim($align);
      if ($align ne '' && !defined get_css_property($node, 'text-align')) {
        set_css_property($node, 'text-align', lc($align));
      }
    }
  }
}

# replace center by a div or remove it if there is a table inside
sub replace_center {
  my ($root, $all_block) = @_;
  my $doc = $root->ownerDocument;
  my @centers = $root->getElementsByTagName('center');
  foreach my $center (@centers) {
    if ($center->getChildrenByTagName('table')->size() > 0) { # note: getChildrenByTagName is not DOM (LibXML specific)
      replace_by_children($center);
    } else {
      # use p or div ? check if there is a block inside
      my $found_block = 0;
      for (my $child=$center->firstChild; defined $child; $child=$child->nextSibling) {
        if ($child->nodeType == XML_ELEMENT_NODE && string_in_array($all_block, $child->nodeName)) {
          $found_block = 1;
          last;
        }
      }
      my $new_node;
      if ($found_block) {
        $new_node = $doc->createElement('div');
        $new_node->setAttribute('style', 'text-align: center; margin: 0 auto');
      } else {
        $new_node = $doc->createElement('p');
        $new_node->setAttribute('style', 'text-align: center');
      }
      my $next;
      for (my $child=$center->firstChild; defined $child; $child=$next) {
        $next = $child->nextSibling;
        $center->removeChild($child);
        $new_node->appendChild($child);
      }
      $center->parentNode->replaceChild($new_node, $center);
    }
  }
}

# checks for errors and adds a part if a problem with responses has no part
sub fix_parts {
  my ($root) = @_;
  my $doc = $root->ownerDocument;
  my @parts = $root->getElementsByTagName('part');
  my $with_parts = (scalar(@parts) > 0);
  my $one_not_in_part = 0;
  my $all_in_parts = 1;
  foreach my $response_tag (@responses) {
    my @response_nodes = $root->getElementsByTagName($response_tag);
    foreach my $response (@response_nodes) {
      my $in_part = 0;
      my $ancestor = $response->parentNode;
      while (defined $ancestor) {
        if ($ancestor->nodeName eq 'part') {
          if ($in_part) {
            die "part in part !!!";
          }
          $in_part = 1;
        }
        $ancestor = $ancestor->parentNode;
      }
      $one_not_in_part = $one_not_in_part || !$in_part;
      $all_in_parts = $all_in_parts && $in_part;
    }
  }
  if ($with_parts && $one_not_in_part) {
    die "parts are used but at least one response is not in a part";
  }
  if ($all_in_parts) {
    return;
  }
  # we are now in the case where parts are not used at all
  if (scalar(@responses) == 0) {
    # no response, no need to create a part
    return;
  }
  # there is at least one response, we will move everything inside problem in a part
  my @problems = $root->getElementsByTagName('problem');
  if (scalar(@problems) != 1) {
    die "there is a response but no problem or more than one";
  }
  foreach my $problem (@problems) {
    my $part = $doc->createElement('part');
    my $next;
    for (my $child=$problem->firstChild; defined $child; $child=$next) {
      $next = $child->nextSibling;
      $problem->removeChild($child);
      $part->appendChild($child);
    }
    $problem->appendChild($part);
  }
}

# changes the hints according to the new schema
# for instance, replaces
# <numericalresponse><hintgroup>text1<numericalhint name="c"/><hintpart on="c">text2</hintpart></hintgroup></numericalresponse>
# by
# <numericalresponse><numericalhint name="c"/></numericalresponse><hint>text1</hint><hint on="c">text2</hint>
# but keep hintgroup when it is useful
# (when it is in a part containing more than 1 hintgroup containing a hinpart with on="default")
# Also replaces "hint" elements (that should not exists) by their content.
sub change_hints {
  my ($root) = @_;
  my $doc = $root->ownerDocument;
  
  # replace all "hint" elements by their children
  foreach my $bad_hint ($root->getElementsByTagName('hint')) {
    replace_by_children($bad_hint);
  }
  
  # Check if there is a hintpart or *hint outside of a hintgroup.
  # If so, put it inside a new hintgroup.
  my @subhint_tags = ('hintpart','formulahint','numericalhint','reactionhint','organichint','optionhint','radiobuttonhint','stringhint','customhint','mathhint');
  foreach my $subhint_tag (@subhint_tags) {
    my @subhints = $root->getElementsByTagName($subhint_tag);
    foreach my $subhint (@subhints) {
      my $found_hintgroup = 0;
      my $ancestor = $subhint->parentNode;
      while (defined $ancestor) {
        if ($ancestor->nodeName eq 'hintgroup') {
          $found_hintgroup = 1;
          last;
        }
        $ancestor = $ancestor->parentNode;
      }
      if (!$found_hintgroup) {
        print "Warning: hint found outside of a hintgroup\n";
        # create a new hintgroup for the next step
        my $hintgroup = $doc->createElement('hintgroup');
        $subhint->parentNode->insertAfter($hintgroup, $subhint);
        $subhint->parentNode->removeChild($subhint);
        $hintgroup->appendChild($subhint);
      } elsif ($subhint->parentNode->nodeName ne 'hintgroup' &&
          !($subhint->parentNode->nodeName eq 'block' && $subhint->parentNode->parentNode == $ancestor)) {
        # exceptionally, the case hintgroup/block/hintpart is handled (otherwise hintpart parent must be hintgroup)
        die "Error: hint parent is ".$subhint->parentNode->nodeName." instead of hintgroup";
      }
    }
  }
  
  my @hintgroups = $root->getElementsByTagName('hintgroup');
  
  # create a list of hintgroups that are in a part containing more than 1 hintgroup containing a hinpart with on="default"
  my @hintgroups_to_preserve = ();
  foreach my $hintgroup (@hintgroups) {
    # look for the ancestor part or problem (or if not found, the root element)
    my $part_or_problem;
    my $ancestor = $hintgroup->parentNode;
    while (defined $ancestor) {
      my $name = $ancestor->nodeName;
      if ($name eq 'part' || $name eq 'problem') {
        $part_or_problem = $ancestor;
        last;
      }
      $ancestor = $ancestor->parentNode;
    }
    if (!defined $part_or_problem) {
      $part_or_problem = $root;
    }
    # check to see if there is more than 1 hintgroup containing a hinpart with on="default" in the part
    my $nb_hintgroups_with_hintpart_default = 0;
    my @hintgroups_in_part = $part_or_problem->getElementsByTagName('hintgroup');
    foreach my $hintgroup_in_part (@hintgroups_in_part) {
      my $default_hinpart = 0;
      my @hintparts = $hintgroup_in_part->getElementsByTagName('hintpart');
      foreach my $hintpart (@hintparts) {
        my $on = $hintpart->getAttribute('on');
        if (defined $on) {
          $on = lc(trim($on));
          if ($on eq 'default') {
            $default_hinpart = 1;
            last;
          }
        }
      }
      if ($default_hinpart) {
        $nb_hintgroups_with_hintpart_default++;
      }
    }
    if ($nb_hintgroups_with_hintpart_default > 1 && scalar(@{$hintgroup->nonBlankChildNodes()}) > 0) {
      push(@hintgroups_to_preserve, $hintgroup);
    }
  }
  
  # replace hintgroups when they are not necessary, move non-*hints outside of the response
  foreach my $hintgroup (@hintgroups) {
    # look for the response in the ancestors
    my $response;
    my $ancestor = $hintgroup->parentNode;
    while (defined $ancestor) {
      if (string_in_array(\@responses, $ancestor->nodeName)) {
        $response = $ancestor;
        last;
      }
      $ancestor = $ancestor->parentNode;
    }
    
    # look for a position to move the hints to
    my $move_after; # if defined, hints will be added after this node
    my $move_inside; # if defined, hints will be added inside this node
    if (defined $response) {
      $move_after = $response;
    } else {
      $move_after = $hintgroup;
    }
    while (defined $move_after->nextSibling && ($move_after->nextSibling->nodeName eq 'hint' ||
        $move_after->nextSibling->nodeName eq 'hintgroup' ||
        ($move_after->nextSibling->nodeType == XML_TEXT_NODE && $move_after->nextSibling->nodeValue eq "\n"))) {
      $move_after = $move_after->nextSibling;
    }
    
    # position to move conditions to
    my $move_conditions_after = $hintgroup;
    
    # recreate a hintgroup if necessary
    if (reference_in_array(\@hintgroups_to_preserve, $hintgroup)) {
      my $new_hintgroup = $doc->createElement('hintgroup');
      $move_after->parentNode->insertAfter($new_hintgroup, $move_after);
      $move_after = undef;
      $move_inside = $new_hintgroup;
    }
    
    # move the hints
    my $next;
    my $hint;
    for (my $child=$hintgroup->firstChild; defined $child; $child=$next) {
      $next = $child->nextSibling;
      $hintgroup->removeChild($child);
      if ($child->nodeName =~ /hint$/) {
        if (defined $hint) {
          $hint = undef;
        }
        if (!defined $response) {
          print "Warning: hint condition outside of a response\n";
        }
        $move_conditions_after->parentNode->insertAfter($child, $move_conditions_after);
        $move_conditions_after = $child;
      } elsif ($child->nodeName eq 'hintpart') {
        if (defined $hint) {
          $hint = undef;
        }
        $child->setNodeName('hint');
        if (defined $hintgroup->getAttribute('showoncorrect') && $hintgroup->getAttribute('showoncorrect') ne 'no') {
          # note: this attribute value might be a Perl variable
          $child->setAttribute('showoncorrect', $hintgroup->getAttribute('showoncorrect'));
        }
        if (defined $move_inside) {
          $move_inside->appendChild($child);
        } else {
          $move_after->parentNode->insertAfter($child, $move_after);
          $move_after = $child;
        }
      } elsif ($child->nodeType == XML_TEXT_NODE && $child->nodeValue =~ /^\s*$/) {
        # ignore blanks
      } elsif ($child->nodeType == XML_COMMENT_NODE && !defined $hint) {
        # an XML comment does not need to be in a hint
        if (defined $move_inside) {
          $move_inside->appendChild($child);
        } else {
          $move_after->parentNode->insertAfter($child, $move_after);
          $move_after = $child;
        }
      } elsif ($child->nodeName eq 'block' && scalar(@{$child->getChildrenByTagName('hintpart')}) > 0) {
        # block with hintpart inside: convert hintgroup/block/hintpart into block/hint
        if (defined $hint) {
          $hint = undef;
        }
        my $next2;
        for (my $child2=$child->firstChild; defined $child2; $child2=$next2) {
          $next2 = $child2->nextSibling;
          if ($child2->nodeName eq 'hintpart') {
            $child2->setNodeName('hint');
            if (defined $hintgroup->getAttribute('showoncorrect') && $hintgroup->getAttribute('showoncorrect') ne 'no') {
              $child2->setAttribute('showoncorrect', $hintgroup->getAttribute('showoncorrect'));
            }
          }
        }
        if (defined $move_inside) {
          $move_inside->appendChild($child);
        } else {
          $move_after->parentNode->insertAfter($child, $move_after);
          $move_after = $child;
        }
      } else {
        if (!defined $hint) {
          # create a new hint element for a hint without a condition
          $hint = $doc->createElement('hint');
          if (defined $hintgroup->getAttribute('showoncorrect') && $hintgroup->getAttribute('showoncorrect') ne 'no') {
            $hint->setAttribute('showoncorrect', $hintgroup->getAttribute('showoncorrect'));
          }
          if (defined $move_inside) {
            $move_inside->appendChild($hint);
            $move_inside->appendChild($doc->createTextNode("\n"));
          } else {
            my $newline_node;
            if ($move_after->nodeType != XML_TEXT_NODE || $move_after->nodeValue ne "\n") {
              $newline_node = $doc->createTextNode("\n");
              $move_after->parentNode->insertAfter($newline_node, $move_after);
              $move_after = $newline_node;
            }
            $move_after->parentNode->insertAfter($hint, $move_after);
            $move_after = $hint;
            if (!defined $move_after->nextSibling || $move_after->nextSibling->nodeType != XML_TEXT_NODE ||
                $move_after->nextSibling->nodeValue !~ "\n") {
              $newline_node = $doc->createTextNode("\n");
              $move_after->parentNode->insertAfter($newline_node, $move_after);
              $move_after = $newline_node;
            }
          }
        }
        $hint->appendChild($child);
      }
    }
    if (defined $hintgroup->nextSibling && $hintgroup->nextSibling->nodeType == XML_TEXT_NODE &&
        $hintgroup->nextSibling->nodeValue =~ /^\s*$/) {
      # also remove blank afterwards
      $hintgroup->parentNode->removeChild($hintgroup->nextSibling);
    }
    $hintgroup->parentNode->removeChild($hintgroup);
  }
  
  # NOTE: there are problems when hint elements are block
  # (they break paragraphs even with inline responses)
  # and when they are inline
  # (they have to be allowed everywhere, they can contains lots of text with blocks, and could trigger the creation of unnecessary paragraphs).
  # Currently they are inline, with some exceptions in the conversion, like inline responses.
  
  # hints were blocks but are becoming inline; this removes blank text nodes at the beginning and the end of all hint elements
  my @hints = $root->getElementsByTagName('hint');
  foreach my $hint (@hints) {
    if (defined $hint->firstChild && $hint->firstChild->nodeType == XML_TEXT_NODE) {
      my $text = $hint->firstChild->nodeValue;
      $text =~ s/^\s*//;
      $hint->firstChild->setData($text);
    }
    if (defined $hint->lastChild && $hint->lastChild->nodeType == XML_TEXT_NODE) {
      my $text = $hint->lastChild->nodeValue;
      $text =~ s/\s*$//;
      $hint->lastChild->setData($text);
    }
  }
}

# calls fix_paragraphs for all children
sub fix_paragraphs_inside {
  my ($node, $all_block) = @_;
  # blocks in which paragrahs will be added:
  my @blocks_with_p = ('problem','part','problemtype','window','block','while','postanswerdate','preduedate','solved','notsolved','languageblock','translated','lang','instructorcomment','togglebox','standalone');
  my @fix_p_if_br_or_p = ('foil','item','text','label','hintgroup','hintpart','hint','web','windowlink','div','li','dd','td','th','blockquote');
  if ((string_in_array(\@blocks_with_p, $node->nodeName) && paragraph_needed($node)) ||
      (string_in_array(\@fix_p_if_br_or_p, $node->nodeName) &&
      (scalar(@{$node->getChildrenByTagName('br')}) > 0 ||
       scalar(@{$node->getChildrenByTagName('p')}) > 0))) {
    # if non-empty, add a paragraph containing everything inside, paragraphs inside paragraphs will be fixed afterwards
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
        fix_paragraph($child, $all_block);
      } else {
        fix_paragraphs_inside($child, $all_block);
      }
    }
  }
}

# returns 1 if a paragraph is needed inside this node (assuming the parent can have paragraphs)
sub paragraph_needed {
  my ($node) = @_;
  for (my $child=$node->firstChild; defined $child; $child=$child->nextSibling) {
    if (($child->nodeType == XML_TEXT_NODE && $child->nodeValue !~ /^\s*$/) ||
        ($child->nodeType == XML_ELEMENT_NODE && !string_in_array(\@inline_like_block, $child->nodeName)) ||
        $child->nodeType == XML_CDATA_SECTION_NODE ||
        $child->nodeType == XML_ENTITY_NODE || $child->nodeType == XML_ENTITY_REF_NODE) {
      return(1);
    }
  }
  return(0);
}

# fixes paragraphs inside paragraphs (without a block in-between)
sub fix_paragraph {
  my ($p, $all_block) = @_;
  my $block = find_first_block($p, $all_block);
  if (defined $block) {
    my $trees = clone_ancestor_around_node($p, $block);
    my $doc = $p->ownerDocument;
    my $replacement = $doc->createDocumentFragment();
    my $left = $trees->{'left'};
    my $middle = $trees->{'middle'};
    my $right = $trees->{'right'};
    if (defined $left) {
      if (!paragraph_needed($left)) {
        # this was just blank text, comments or inline responses, it should not create a new paragraph
        my $next;
        for (my $child=$left->firstChild; defined $child; $child=$next) {
          $next = $child->nextSibling;
          $left->removeChild($child);
          $replacement->appendChild($child);
        }
      } else {
        $replacement->appendChild($left);
        # fix paragraphs inside, in case one of the descendants can have paragraphs inside (like numericalresponse/hintgroup):
        my $next;
        for (my $child=$left->firstChild; defined $child; $child=$next) {
          $next = $child->nextSibling;
          fix_paragraphs_inside($child, $all_block);
        }
      }
    }
    my $n = $middle->firstChild;
    while (defined $n) {
      if ($n->nodeType == XML_ELEMENT_NODE && (string_in_array($all_block, $n->nodeName) || $n->nodeName eq 'br')) {
        if ($n->nodeName eq 'p') {
          my $parent = $n->parentNode;
          # first apply recursion
          fix_paragraph($n, $all_block);
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
            # replace a br by a paragraph if there was nothing before in the paragraph,
            # otherwise remove it because it already broke the paragraph in half
            if (!defined $left) {
              $replacement->appendChild($middle);
            }
          } else {
            fix_paragraphs_inside($n, $all_block);
            $replacement->appendChild($n);
          }
        }
        last;
      }
      $n = $n->firstChild;
      if (defined $n && defined $n->nextSibling) {
        die "Error in post_xml.fix_paragraph: block not found";
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
        if (paragraph_needed($right)) {
          $replacement->appendChild($right);
          fix_paragraph($right, $all_block);
        } else {
          # this was just blank text, comments or inline responses, it should not create a new paragraph
          my $next;
          for (my $child=$right->firstChild; defined $child; $child=$next) {
            $next = $child->nextSibling;
            $right->removeChild($child);
            $replacement->appendChild($child);
          }
        }
      }
    }
    $p->parentNode->replaceChild($replacement, $p);
  } else {
    # fix paragraphs inside, in case one of the descendants can have paragraphs inside (like numericalresponse/hintgroup):
    my $next;
    for (my $child=$p->firstChild; defined $child; $child=$next) {
      $next = $child->nextSibling;
      fix_paragraphs_inside($child, $all_block);
    }
  }
}

sub find_first_block {
  my ($node, $all_block) = @_;
  # inline elements that can be split in half if there is a paragraph inside (currently all HTML):
  my @splitable_inline = ('span', 'a', 'strong', 'em' , 'b', 'i', 'sup', 'sub', 'code', 'kbd', 'samp', 'tt', 'ins', 'del', 'var', 'small', 'big', 'font', 'u');
  for (my $child=$node->firstChild; defined $child; $child=$child->nextSibling) {
    if ($child->nodeType == XML_ELEMENT_NODE) {
      if (string_in_array($all_block, $child->nodeName) || $child->nodeName eq 'br') {
        return($child);
      }
      if (string_in_array(\@splitable_inline, $child->nodeName)) {
        my $block = find_first_block($child, $all_block);
        if (defined $block) {
          return($block);
        }
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
    die "error in split_ancestor_around_node: middle not found";
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
  my @remove_if_blank = ('span', 'strong', 'em' , 'b', 'i', 'sup', 'sub', 'tt', 'var', 'small', 'big', 'font', 'u');
  foreach my $name (@remove_if_empty) {
    my @nodes = $root->getElementsByTagName($name);
    while (scalar(@nodes) > 0) {
      my $node = pop(@nodes);
      if (!defined $node->firstChild) {
        my $parent = $node->parentNode;
        $parent->removeChild($node);
        $parent->normalize();
        # now that we removed the node, check if the parent has become an empty style, and so on
        while (defined $parent && string_in_array(\@remove_if_empty, $parent->nodeName) && !defined $parent->firstChild) {
          my $grandparent = $parent->parentNode;
          $grandparent->removeChild($parent);
          remove_reference_from_array(\@nodes, $parent);
          $parent = $grandparent;
        }
      }
    }
    foreach my $node (@nodes) {
      if (!defined $node->firstChild) {
        $node->parentNode->removeChild($node);
      }
    }
  }
  foreach my $name (@remove_if_blank) {
    my @nodes = $root->getElementsByTagName($name);
    while (scalar(@nodes) > 0) {
      my $node = pop(@nodes);
      if (defined $node->firstChild && !defined $node->firstChild->nextSibling && $node->firstChild->nodeType == XML_TEXT_NODE) {
        if ($node->firstChild->nodeValue =~ /^\s*$/) {
          my $parent = $node->parentNode;
          replace_by_children($node);
          $parent->normalize();
          # now that we removed the node, check if the parent has become a style with only whitespace, and so on
          while (defined $parent && string_in_array(\@remove_if_blank, $parent->nodeName) &&
              !defined $parent->firstChild->nextSibling && $parent->firstChild->nodeType == XML_TEXT_NODE &&
              $parent->firstChild->nodeValue =~ /^\s*$/) {
            my $grandparent = $parent->parentNode;
            replace_by_children($parent);
            remove_reference_from_array(\@nodes, $parent);
            $parent = $grandparent;
          }
        }
      }
    }
  }
}

# remove whitespace inside LON-CAPA elements that have an empty content-model (HTML ones are handled by html_to_xml)
sub fix_empty_lc_elements {
  my ($node) = @_;
  my @lcempty = ('arc','axis','backgroundplot','drawoptionlist','drawvectorsum','fill','functionplotrule','functionplotvectorrule','functionplotvectorsumrule','hiddenline','hiddensubmission','key','line','location','organicstructure','parameter','plotobject','plotvector','responseparam','spline','textline','xlabel','ylabel');
  if (string_in_array(\@lcempty, $node->nodeName)) {
    if (defined $node->firstChild && !defined $node->firstChild->nextSibling &&
        $node->firstChild->nodeType == XML_TEXT_NODE && $node->firstChild->nodeValue =~ /^\s*$/) {
      $node->removeChild($node->firstChild);
    }
    return;
  }
  for (my $child=$node->firstChild; defined $child; $child=$child->nextSibling) {
    if ($child->nodeType == XML_ELEMENT_NODE) {
      fix_empty_lc_elements($child);
    }
  }
}

# pretty-print using im-memory DOM tree
sub pretty {
  my ($node, $all_block, $indent_level) = @_;
  my $doc = $node->ownerDocument;
  $indent_level ||= 0;
  my $type = $node->nodeType;
  if ($type == XML_ELEMENT_NODE) {
    my $name = $node->nodeName;
    if ((string_in_array($all_block, $name) || string_in_array(\@inline_like_block, $name)) &&
        !string_in_array(\@preserve_elements, $name)) {
      # make sure there is a newline at the beginning and at the end if there is anything inside
      if (defined $node->firstChild && !string_in_array(\@no_newline_inside, $name)) {
        my $first = $node->firstChild;
        if ($first->nodeType == XML_TEXT_NODE) {
          my $text = $first->nodeValue;
          if ($text !~ /^ *\n/) {
            $first->setData("\n" . $text);
          }
        } else {
          $node->insertBefore($doc->createTextNode("\n"), $first);
        }
        my $last = $node->lastChild;
        if ($last->nodeType == XML_TEXT_NODE) {
          my $text = $last->nodeValue;
          if ($text !~ /\n *$/) {
            $last->setData($text . "\n");
          }
        } else {
          $node->appendChild($doc->createTextNode("\n"));
        }
      }
      
      # indent and make sure there is a newline before and after a block element
      my $newline_indent = "\n".(' ' x (2*($indent_level + 1)));
      my $newline_indent_last = "\n".(' ' x (2*$indent_level));
      my $next;
      for (my $child=$node->firstChild; defined $child; $child=$next) {
        $next = $child->nextSibling;
        if ($child->nodeType == XML_ELEMENT_NODE) {
          if (string_in_array($all_block, $child->nodeName)) {
            # make sure there is a newline before and after a block element
            if (defined $child->previousSibling && $child->previousSibling->nodeType == XML_TEXT_NODE) {
              my $prev = $child->previousSibling;
              my $text = $prev->nodeValue;
              if ($text !~ /\n *$/) {
                $prev->setData($text . $newline_indent);
              }
            } else {
              $node->insertBefore($doc->createTextNode($newline_indent), $child);
            }
            if (defined $next && $next->nodeType == XML_TEXT_NODE) {
              my $text = $next->nodeValue;
              if ($text !~ /^ *\n/) {
                $next->setData($newline_indent . $text);
              }
            } else {
              $node->insertAfter($doc->createTextNode($newline_indent), $child);
            }
          }
          pretty($child, $all_block, $indent_level+1);
        } elsif ($child->nodeType == XML_TEXT_NODE) {
          my $text = $child->nodeValue;
          # collapse newlines
          $text =~ s/\n([\t ]*\n)+/\n/g;
          # indent and remove spaces and tabs before newlines
          if (defined $next) {
            $text =~ s/[\t ]*\n[\t ]*/$newline_indent/ge;
          } else {
            $text =~ s/[\t ]*\n[\t ]*/$newline_indent/ge;
            $text =~ s/[\t ]*\n[\t ]*$/$newline_indent_last/e;
          }
          $child->setData($text);
        }
      }
      
      # removes whitespace at the beginning and end of p td and th
      my @to_trim = ('p','td','th');
      if (string_in_array(\@to_trim, $name) && defined $node->firstChild && $node->firstChild->nodeType == XML_TEXT_NODE) {
        my $text = $node->firstChild->nodeValue;
        $text =~ s/^\s*//;
        if ($text eq '') {
          $node->removeChild($node->firstChild);
        } else {
          $node->firstChild->setData($text);
        }
      }
      if (string_in_array(\@to_trim, $name) && defined $node->lastChild && $node->lastChild->nodeType == XML_TEXT_NODE) {
        my $text = $node->lastChild->nodeValue;
        $text =~ s/\s*$//;
        if ($text eq '') {
          $node->removeChild($node->lastChild);
        } else {
          $node->lastChild->setData($text);
        }
      }
    } elsif (string_in_array(\@preserve_elements, $name)) {
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


######## utilities ########

##
# Trims a string (really, this should be built-in in Perl, this is ridiculous, ugly and slow)
# @param {string} s - the string to trim
# @returns the trimmed string
##
sub trim {
  my ($s) = @_;
  $s =~ s/^\s+//;
  $s =~ s/\s+$//;
  return($s);
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

##
# Tests if an object is in an array (using ==)
# @param {Array<Object>} array - reference to the array of references
# @param {Object} ref - the reference to look for
# @returns 1 if found, 0 otherwise
##
sub reference_in_array {
  my ($array, $ref) = @_;
  foreach my $v (@{$array}) {
    if ($v == $ref) {
      return 1;
    }
  }
  return 0;
}

##
# returns the index of a string in an array
# @param {Array<Object>} array - reference to the array of strings
# @param {string} s - the string to look for (using eq)
# @returns the index if found, -1 otherwise
##
sub index_of_string {
  my ($array, $s) = @_;
  for (my $i=0; $i<scalar(@{$array}); $i++) {
    if ($array->[$i] eq $s) {
      return $i;
    }
  }
  return -1;
}

##
# returns the index of a reference in an array
# @param {Array<Object>} array - reference to the array of references
# @param {Object} ref - the reference to look for
# @returns the index if found, -1 otherwise
##
sub index_of_reference {
  my ($array, $ref) = @_;
  for (my $i=0; $i<scalar(@{$array}); $i++) {
    if ($array->[$i] == $ref) {
      return $i;
    }
  }
  return -1;
}

##
# if found, removes a string from an array, otherwise do nothing
# @param {Array<string>} array - reference to the array of string
# @param {string} s - the string to look for (using eq)
##
sub remove_string_from_array {
  my ($array, $s) = @_;
  my $index = index_of_string($array, $s);
  if ($index != -1) {
    splice(@$array, $index, 1);
  }
}

##
# if found, removes a reference from an array, otherwise do nothing
# @param {Array<Object>} array - reference to the array of references
# @param {Object} ref - the reference to look for
##
sub remove_reference_from_array {
  my ($array, $ref) = @_;
  my $index = index_of_reference($array, $ref);
  if ($index != -1) {
    splice(@$array, $index, 1);
  }
}

##
# replaces a node by its children
# @param {Node} node - the DOM node
##
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

##
# returns the trimmed attribute value if the attribute exists and is not blank, undef otherwise
# @param {Node} node - the DOM node
# @param {string} attribute_name - the attribute name
##
sub get_non_empty_attribute {
  my ($node, $attribute_name) = @_;
  my $value = $node->getAttribute($attribute_name);
  if (defined $value && $value !~ /^\s*$/) {
    $value = trim($value);
    return($value);
  }
  return(undef);
}

##
# Returns a CSS property value from the style attribute of the element, or undef if not defined
# @param {Element} el - the DOM element
# @param {string} property_name - the CSS property name
##
sub get_css_property {
  my ($el, $property_name) = @_;
  my $style = $el->getAttribute('style');
  if (defined $style) {
    $style =~ s/^\s*;\s*//;
    $style =~ s/\s*;\s*$//;
  } else {
    $style = '';
  }
  my @pairs = split(';', $style);
  foreach my $pair (@pairs) {
    my @name_value = split(':', $pair);
    if (scalar(@name_value) != 2) {
      next;
    }
    my $name = trim($name_value[0]);
    my $value = trim($name_value[1]);
    if (lc($name) eq $property_name) {
      return($value); # return the first one found
    }
  }
  return(undef);
}

##
# Returns the reference to a hash CSS property name => value from the style attribute of the element.
# Returns an empty list if the style attribute is not defined,
# @param {Element} el - the DOM element
# @return {Hash<string, string>} reference to the hash  property name => property value
##
sub get_css_properties {
  my ($el) = @_;
  my $style = $el->getAttribute('style');
  if (defined $style) {
    $style =~ s/^\s*;\s*//;
    $style =~ s/\s*;\s*$//;
  } else {
    $style = '';
  }
  my @pairs = split(';', $style);
  tie (my %hash, 'Tie::IxHash', ());
  foreach my $pair (@pairs) {
    my @name_value = split(':', $pair);
    if (scalar(@name_value) != 2) {
      next;
    }
    my $name = trim($name_value[0]);
    my $value = trim($name_value[1]);
    if (defined $hash{$name}) {
      # duplicate property in the style attribute: keep only the last one
      delete $hash{$name};
    }
    $hash{$name} = $value;
  }
  return(\%hash);
}

##
# Sets a CSS property in the style attribute of an element
# @param {Element} el - the DOM element
# @param {string} property_name - the CSS property name
# @param {string} property_value - the CSS property value
##
sub set_css_property {
  my ($el, $property_name, $property_value) = @_;
  my $hash_ref = { $property_name => $property_value };
  set_css_properties($el, $hash_ref);
}

##
# Sets several CSS properties in the style attribute of an element
# @param {Element} el - the DOM element
# @param {Hash<string, string>} properties - reference to the hash property name => property value
##
sub set_css_properties {
  my ($el, $properties) = @_;
  my $hash = get_css_properties($el);
  foreach my $property_name (keys %$properties) {
    my $property_value = $properties->{$property_name};
    if (defined $hash->{$property_name}) {
      delete $hash->{$property_name}; # to add the new one at the end
    }
    $hash->{$property_name} = $property_value;
  }
  my $style = '';
  foreach my $key (keys %$hash) {
    $style .= $key.':'.$hash->{$key}.'; ';
  }
  $style =~ s/; $//;
  $el->setAttribute('style', $style);
}

1;
__END__
