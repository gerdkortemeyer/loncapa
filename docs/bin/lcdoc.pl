#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use HTML::Entities;

sub printUsage {
    print "usage: perl lcdoc.pl -d output_dir file1.pm [file2.pl ...]\n";
    exit(1);
}

##
# Reads a Perl file and returns the list of packages.
# Each package is a hash with the keys name, comments, subs.
# subs is a list of subs, each one with the keys name, comments, params.
# params is a list of parameters, each one with the keys key, type, name, comment.
# @param {string} filename - the Perl file name
# @returns {Array} the list of packages.
##
sub readPerlFile {
    my( $filename ) = @_;
    
    #print "processing $filename...\n";
    open(my $pscript, "<", $filename);
    
    my $subs = [];
    my $package = {
        "name" => undef,
        "comments" => '',
        "subs" => $subs,
    };
    # this default "package" will gather the subs without a package:
    my @packages = ( $package );
    my $comments = '';
    my $sub;
    my $params = [];
    my $param;
    my $sub_par = 0;
    while (<$pscript>) {
        if ($sub_par > 0) {
            # ignore strings and regular expressions when counting block level
            $_ =~ s/"[^"]*"//;
            $_ =~ s/'[^']*'//;
            $_ =~ s/\/[^\/]*\///;
            my $nb_open = $_ =~ tr/{/{/;
            my $nb_close = $_ =~ tr/}/}/;
            $sub_par += $nb_open - $nb_close;
            next;
        }
        if (/^\s*package\s+(\S+);/) {
            $subs = [];
            if (defined $comments) {
                $comments =~ s/^\s+|\s+$//g;
            }
            $package = {
                "name" => $1,
                "comments" => $comments,
                "subs" => $subs,
            };
            push(@packages, $package);
            $comments = '';
        } elsif (/^\s*sub\s+(\S+)\s*\{/) {
            if (defined $comments) {
                $comments =~ s/^\s+|\s+$//g;
            }
            $sub = {
                "name" => $1,
                "comments" => $comments,
                "params" => $params,
            };
            push(@{$subs}, $sub);
            $comments = '';
            $params = [];
            $sub_par = 1;
        } elsif (/^#\s*@(\S+)\s*(\{(\s?.+\s?)\})?\s*(\S+)?\s*\-?\s*(.*)$/) {
            my $name = $4;
            my $comment = $5;
            if ($1 eq "returns") {
                if (defined $4 && defined $5) {
                    $comment = $4." ".$5;
                } elsif (defined $4) {
                    $comment = $4;
                } elsif (defined $5) {
                    $comment = $5;
                }
                $name = "";
            }
            $param = {
                "key" => $1,
                "type" => $3,
                "name" => $name,
                "comment" => $comment,
            };
            push(@{$params}, $param);
        } elsif (/^#[#\s\-=]*(.*)$/) {
            $comments .= $1."\n";
        } elsif (/^\s*$/) {
            $comments = '';
        }
    }
    
    close($pscript);
    return \@packages;
}

##
# Writes an HTML file matching a Perl file.
# @param {string} outdir - output directory
# @param {string} name - name of the file (without the extension)
# @param {Array} packages - the list of packages returned by readPerlFile
# @param {Array<string>} all_file_package_names - the names of all the Perl files (without the extension)
##
sub writeHTMLFile {
    my( $outdir, $name, $packages, $all_file_package_names ) = @_;
    
    my $filename = "$outdir/$name.html";
    open(my $html, ">", $filename);
    print $html "<!DOCTYPE html>\n";
    print $html "<html>\n";
    print $html "<head>\n";
    print $html "<meta charset=\"utf-8\">\n";
    print $html "<title>$name</title>\n";
    print $html "<style type=\"text/css\">\n";
    print $html "body { background-color: #FFFFFF; }\n";
    print $html "h1 { text-align: center; }\n";
    print $html "li { padding-bottom: 0.5em; }\n";
    print $html "span.type { font-family: monospace; }\n";
    print $html "span.sub-name { color: #000050; font-weight: bold; }\n";
    print $html "span.param-name { color: #005000; }\n";
    print $html "</style>\n";
    print $html "</head>\n";
    print $html "<body>\n";
    print $html "<p><a href=\"index.html\">Index</a><p>\n";
    print $html "<h1>$name</h1>\n";
    foreach my $package (@{$packages}) {
        if (defined $package->{name}) {
            print $html "<h2>package ".$package->{name}."</h2>\n";
        }
        if (defined $package->{comments}) {
            print $html "<p>".HTML::Entities::encode($package->{comments})."</p>\n";
        }
        if (scalar(@{$package->{subs}}) > 0) {
            print $html "<ul>\n";
            foreach my $sub (@{$package->{subs}}) {
                print $html "<li>\n";
                print $html "<span class=\"sub-name\">".$sub->{name}."</span>";
                print $html "(";
                if (scalar(@{$sub->{params}}) > 0) {
                    foreach my $param (@{$sub->{params}}) {
                        if ($param->{key} eq "optional" || $param->{key} eq "param") {
                            if ($param != $sub->{params}->[0]) {
                                print $html ", ";
                            }
                            if (defined $param->{name}) {
                                print $html "<span class=\"param-name\">".$param->{name}."</span>";
                            } elsif (defined $param->{type}) {
                                print $html $param->{type};
                            }
                            if ($param->{key} eq "optional") {
                                print $html "?";
                            }
                        }
                    }
                }
                print $html ")\n";
                if (defined $sub->{comments}) {
                    print $html "<p>".HTML::Entities::encode($sub->{comments})."</p>\n";
                }
                if (scalar(@{$sub->{params}}) > 0) {
                    print $html "<ul>\n";
                    foreach my $param (@{$sub->{params}}) {
                        print $html "<li>";
                        if ($param->{key} eq "optional") {
                            #print $html "optional ";
                        } elsif ($param->{key} eq "returns") {
                            print $html "returns ";
                        } elsif ($param->{key} eq "author") {
                            print $html "Author: ";
                        } elsif ($param->{key} ne "param") {
                            print $html $param->{key}." ";
                        }
                        if (defined $param->{type}) {
                            my @types = split(/\|/, $param->{type});
                            my $first = 1;
                            foreach my $t (@types) {
                                if (!$first) {
                                    print $html " | ";
                                }
                                print $html "<span class=\"type\">";
                                my $name = $t;
                                $name =~ s/.*:://;
                                $name =~ s/\[\]//g;
                                if ($name ~~ @{$all_file_package_names}) {
                                    print $html "<a href=\"$name.html\">$t</a>";
                                } else {
                                    print $html HTML::Entities::encode($t);
                                }
                                print $html "</span> ";
                                $first = 0;
                            }
                        }
                        if (defined $param->{name}) {
                            print $html "<span class=\"param-name\">".$param->{name}."</span>";
                        }
                        if (defined $param->{comment} && $param->{comment} ne '') {
                            print $html " : ".HTML::Entities::encode($param->{comment});
                        }
                        print $html "</li>\n";
                    }
                    print $html "</ul>\n";
                }
                print $html "</li>\n";
            }
            print $html "</ul>\n";
        }
    }
    print $html "</body>\n";
    print $html "</html>\n";
    close($html);
}

##
# Writes an index of the generated files in an HTML file named index.html.
# @param {string} outdir - output directory
# @param {Array<string>} all_file_package_names - the names of all the Perl files (without the extension)
##
sub writeIndexHTMLFile {
    my( $outdir, $all_file_package_names ) = @_;
    
    my $filename = "$outdir/index.html";
    open(my $html, ">", $filename);
    print $html "<!DOCTYPE html>\n";
    print $html "<html>\n";
    print $html "<head>\n";
    print $html "<meta charset=\"utf-8\">\n";
    print $html "<title>Index</title>\n";
    print $html "<style type=\"text/css\">\n";
    print $html "body { background-color: #FFFFFF; }\n";
    print $html "h1 { text-align: center; }\n";
    print $html "li { margin-bottom: 0.5em; }\n";
    print $html "</style>\n";
    print $html "</head>\n";
    print $html "<body>\n";
    print $html "<h1>Index</h1>\n";
    print $html "<ul>\n";
    my @sorted_list = sort @{$all_file_package_names};
    foreach my $name (@sorted_list) {
        print $html "<li><a href=\"$name.html\">$name</a></li>\n";
    }
    print $html "</ul>\n";
    print $html "</body>\n";
    print $html "</html>\n";
    close($html);
}

if ($#ARGV < 0) {
    printUsage();
}
my $outdir = `pwd`;
$outdir =~ s/\n//;
while (substr($ARGV[0],0,1) eq "-") {
    if ($ARGV[0] eq "-d") {
        if ($#ARGV < 1) {
            printUsage();
        }
        $outdir = $ARGV[1];
        shift @ARGV;
        shift @ARGV;
    } else {
        print "unsupported option: ".$ARGV[0]."\n";
        printUsage();
    }
}

my @all_file_package_names = ();
foreach my $filename (@ARGV) {
    my $name = $filename;
    $name =~ s/\.[^.\/]*$//;
    $name =~ s/.*\///;
    push(@all_file_package_names, $name);
}
foreach my $filename (@ARGV) {
    my $packages = readPerlFile($filename);
    my $name = $filename;
    $name =~ s/\.[^.\/]*$//;
    $name =~ s/.*\///;
    writeHTMLFile($outdir, $name, $packages, \@all_file_package_names);
}
if (scalar(@all_file_package_names) > 1) {
    writeIndexHTMLFile($outdir, \@all_file_package_names);
}
