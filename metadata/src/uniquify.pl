use strict;
use utf8;
use locale;
open(IN,"un_keyword.txt");
my %unkey=();
while (my $line=<IN>) {
   $line=~s/^[^äöüÄÖÜßA-Za-z]+//gs;
   $line=~s/[^äöüÄÖÜßA-Za-z]+$//gs;
   $unkey{$line}=1;
}
close(IN);
foreach my $word (sort(keys(%unkey))) {
   print $word."\n";
}
