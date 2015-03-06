#!/usr/bin/perl

# Validates a file or directory against loncapa.xsd with libxml2

use strict;
use utf8;
use warnings;

use File::Basename;
use Try::Tiny;
use XML::LibXML;


binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

if (scalar(@ARGV) != 1) {
  print STDERR "Usage: perl validate_converted.pl file|directory\n";
  exit(1);
}

# find the command-line argument encoding
use I18N::Langinfo qw(langinfo CODESET);
my $codeset = langinfo(CODESET);
use Encode qw(decode);
@ARGV = map { decode $codeset, $_ } @ARGV;

my $pathname = "$ARGV[0]";

my $script_dir = dirname(__FILE__);
my $xmlschema = XML::LibXML::Schema->new(location => $script_dir.'/loncapa.xsd');

if (-d "$pathname") {
  validate_dir($pathname);
} elsif (-f $pathname) {
  validate_file($pathname);
}


# Validates a directory recursively, selecting only .lc files.
sub validate_dir {
  my ($dirpath) = @_;
  
  opendir (my $dh, $dirpath) or die $!;
  while (my $entry = readdir($dh)) {
    next if ($entry =~ m/^\./); # ignore entries starting with a period
    my $pathname = $dirpath.'/'.$entry;
    if (-d $pathname) {
      validate_dir($pathname);
    } elsif (-f $pathname) {
      if ($pathname =~ /\.lc$/) {
        validate_file($pathname);
      }
    }
  }
  closedir($dh);
}

# Validates a file against loncapa.xsd with libxml2
sub validate_file {
  my ($pathname) = @_;
  
  my $doc = XML::LibXML->load_xml(location => $pathname);
  try {
    $xmlschema->validate($doc);
    print "$pathname is valid\n";
  } catch {
    $_ =~ s/%20/ /g;
    print "$_\n";
  }
}
