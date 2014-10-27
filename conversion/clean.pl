#!/usr/bin/perl

use strict;
use utf8;
use warnings;

use File::Basename;
use Try::Tiny;

use lib dirname(__FILE__);

use pre_xml;
use html_to_xml;
use post_xml;


if (scalar(@ARGV) != 1) {
  print STDERR "Usage: perl clean.pl file|directory\n";
  exit(1);
}

# find the command-line argument encoding
use I18N::Langinfo qw(langinfo CODESET);
my $codeset = langinfo(CODESET);
use Encode qw(decode);
@ARGV = map { decode $codeset, $_ } @ARGV;

my $pathname = "$ARGV[0]";
if (-d "$pathname") {
  my $failures = convert_dir($pathname);
  if (scalar(@$failures) > 0) {
    print "\nThe following files could not be converted, and need a manual fix:\n";
    foreach my $failure (@$failures) {
      print "  $failure\n";
    }
  }
} elsif (-f $pathname) {
  convert_file($pathname);
}

# Converts a directory recursively, selecting only non-version .problem files.
# Returns a list of files that could not be converted.
sub convert_dir {
  my ($dirpath) = @_;
  
  my @failures = ();
  opendir (my $dh, $dirpath) or die $!;
  while (my $entry = readdir($dh)) {
    next if ($entry =~ m/^\./); # ignore entries starting with a period
    my $pathname = $dirpath.'/'.$entry;
    if (-d $pathname) {
      my $new_failures = convert_dir($pathname);
      push(@failures, @$new_failures);
    } elsif (-f $pathname) {
      # check that the file ends in .problem but not .number.problem or _clean.problem
      if ($pathname =~ /\.problem$/ && $pathname !~ /\.[0-9]+\.problem$/ && $pathname !~ /_clean\.problem$/) {
        try {
          convert_file($pathname);
        } catch {
          print "$_\n"; # continue processing even if a file cannot be converted
          push(@failures, $pathname);
        };
      }
    }
  }
  closedir($dh);
  return(\@failures);
}

# Converts a file, creating a _clean.problem file in the same directory.
sub convert_file {
  my ($pathname) = @_;

  # create a name for the clean file
  my ($filename_no_ext, $dirs, $ext) = fileparse($pathname, qr/\.[^.]*/);
  my $newpath = "$dirs/${filename_no_ext}_clean$ext";

  binmode(STDOUT, ':encoding(UTF-8)');
  print "converting $pathname...\n";

  my $text;
  try {
    $text = pre_xml::pre_xml($pathname);
  } catch {
    die "pre_xml error for $pathname: $_";
  };

  try {
    $text = html_to_xml::html_to_xml($text);
  } catch {
    die "html_to_xml error for $pathname: $_";
  };

  try {
    $text = post_xml::post_xml($text, $newpath);
  } catch {
    die "post_xml error for $pathname: $_";
  };
}
