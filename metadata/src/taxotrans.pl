use strict;
my %keywords=();
open(IN,"taxonomy.dat");
while (my $line=<IN>) {
   my ($taxo,$for,$against)=split(/\s+/,$line);
   foreach my $item (split(/\:/,$taxo)) {
      $keywords{$item}=1;
   }
}
close(IN);
foreach my $key (keys(%keywords)) {
   print $key."\n";
}
