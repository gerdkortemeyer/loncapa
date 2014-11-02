use strict;
open(IN,shift);
open(OUT,">>un_keyword.txt");
while (my $line=<IN>) {
   chomp($line);
   foreach my $word (split(/\s+/,$line)) {
      print $word."?";
      my $reply=<STDIN>;
      if ($reply=~/y/i) {
         print OUT lc($word)."\n";
      }
      if ($reply=~/e/i) {
         close(IN);
         close(OUT);
         exit;
      }
   }
}
close(IN);
close(OUT);
