use strict;
use JSON::DWIW;
use utf8;

open(IN,"taxotrans.txt");
my %en=();
my %de=();
while (my $line=<IN>) {
   chomp($line);
   my ($term,$e,$d)=split(/\s*\:\s*/,$line);
   $en{$term}=$e;
   $de{$term}=$d;
}
close(IN);
my $taxo;
open(IN,"taxonomy.dat");
while (my $line=<IN>) {
   my ($tax,$for,$against)=split(/\s+/,$line);
   my $cross='';
   if ($for=~/\:/) { 
      $cross=$for;
      $for='';
   }
   my ($t1,$t2,$t3)=split(/\:/,$tax);
   if ($t3) {
       $taxo->{$t1}->{'sub'}->{$t2}->{'sub'}->{$t3}->{'lang'}->{'en'}=$en{$t3};
       $taxo->{$t1}->{'sub'}->{$t2}->{'sub'}->{$t3}->{'lang'}->{'de'}=$de{$t3};
       if ($for) {
          my @array=split(/\,/,$for);
          $taxo->{$t1}->{'sub'}->{$t2}->{'sub'}->{$t3}->{'pro'}=\@array;
       }
       if ($against) {
          my @array=split(/\,/,$against);
          $taxo->{$t1}->{'sub'}->{$t2}->{'sub'}->{$t3}->{'con'}=\@array;
       }
       if ($cross) {
          $taxo->{$t1}->{'sub'}->{$t2}->{'sub'}->{$t3}->{'cross'}=[$cross];
       }
   }
   if ($t2) { 
       $taxo->{$t1}->{'sub'}->{$t2}->{'lang'}->{'en'}=$en{$t2};
       $taxo->{$t1}->{'sub'}->{$t2}->{'lang'}->{'de'}=$de{$t2};
       if ($for) {
          my @array=split(/\,/,$for);
          $taxo->{$t1}->{'sub'}->{$t2}->{'pro'}=\@array;
       }
       if ($against) {
          my @array=split(/\,/,$against);
          $taxo->{$t1}->{'sub'}->{$t2}->{'con'}=\@array;
       }
   }
   if ($t1) {
       $taxo->{$t1}->{'lang'}->{'en'}=$en{$t1};
       $taxo->{$t1}->{'lang'}->{'de'}=$de{$t1};
       if ($for) {
          my @array=split(/\,/,$for);
          $taxo->{$t1}->{'pro'}=\@array;
       }
       if ($against) {
          my @array=split(/\,/,$against);
          $taxo->{$t1}->{'con'}=\@array;
       }
   }
}
close(IN);
print JSON::DWIW->to_json($taxo, { pretty => 1 });
