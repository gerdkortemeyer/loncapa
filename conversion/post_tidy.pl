#!/usr/bin/perl

use strict;

use File::Basename;
use Cwd 'abs_path';

use XML::LibXSLT;
use XML::LibXML;

my $dir = dirname(abs_path(__FILE__));

my $xslt = XML::LibXSLT->new();

my $in;

open(my $in, "<-");

my $source = XML::LibXML->load_xml(IO => $in);

close($in);

my $style_doc = XML::LibXML->load_xml(location=>$dir.'/post_tidy.xsl', no_cdata=>1);

my $stylesheet = $xslt->parse_stylesheet($style_doc);

my $results = $stylesheet->transform($source);

print $stylesheet->output_as_bytes($results);

