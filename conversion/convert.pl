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


binmode(STDOUT, ':encoding(UTF-8)');

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
  $pathname =~ s/\/$//;
  my $start = time();
  my ($converted, $failures) = convert_dir($pathname);
  my $end = time();
  my $elapsed = $end - $start;
  my $minutes = int($elapsed / 60);
  my $seconds = $elapsed - ($minutes*60);
  print "\n".scalar(@$converted)." files were converted in $minutes minutes $seconds seconds\n";
  if (scalar(@$failures) > 0) {
    print "\n".scalar(@$failures)." files could not be converted, and need a manual fix:\n";
    foreach my $failure (@$failures) {
      print "  $failure\n";
    }
  }
} elsif (-f $pathname) {
  convert_file($pathname);
}

# Converts a directory recursively, selecting only non-version .problem files.
# Returns a list of files that were converted, and a list of files that could not be converted.
sub convert_dir {
  my ($dirpath) = @_;
  
  my @converted = ();
  my @failures = ();
  opendir (my $dh, $dirpath) or die $!;
  while (my $entry = readdir($dh)) {
    next if ($entry =~ m/^\./); # ignore entries starting with a period
    my $pathname = $dirpath.'/'.$entry;
    if (-d $pathname) {
      my ($new_converted, $new_failures) = convert_dir($pathname);
      push(@converted, @$new_converted);
      push(@failures, @$new_failures);
    } elsif (-f $pathname) {
      # check that the file ends in .problem, .exam, .survey, .html or .htm but not .number.* or .lc
      if (($pathname =~ /\.problem$/ || $pathname =~ /\.exam$/ || $pathname =~ /\.survey$/ ||
          $pathname =~ /\.html$/ || $pathname =~ /\.htm$/) &&
          $pathname !~ /\.[0-9]+\.[a-z]+$/ && $pathname !~ /\.lc$/) {
        try {
          convert_file($pathname);
          push(@converted, $pathname);
        } catch {
          print "$_\n"; # continue processing even if a file cannot be converted
          push(@failures, $pathname);
        };
      }
    }
  }
  closedir($dh);
  return((\@converted, \@failures));
}

# Converts a file, creating a .lc file in the same directory.
sub convert_file {
  my ($pathname) = @_;

  # create a name for the new file
  #my ($filename_no_ext, $dirs, $ext) = fileparse($pathname, qr/\.[^.]*/);
  my $newpath = $pathname.'.lc';

  print "converting $pathname...\n";

  my $textref;
  try {
    $textref = pre_xml::pre_xml($pathname);
  } catch {
    die "pre_xml error for $pathname: $_";
  };

  try {
    $textref = html_to_xml::html_to_xml($textref);
  } catch {
    die "html_to_xml error for $pathname: $_";
  };

  try {
    post_xml::post_xml($textref, $newpath);
  } catch {
    die "post_xml error for $pathname: $_";
  };
}
