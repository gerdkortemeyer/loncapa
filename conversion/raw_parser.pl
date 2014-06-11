use strict;
use HTML::TokeParser;
use Data::Dumper;

my $stack;
my $output;

open(IN,"all_files.txt");
while (my $line=<IN>) {
   chomp($line);
   &parse($line);
exit;
}
close(IN);

sub parse {
   my ($fn)=@_;
   my $p=HTML::TokeParser->new($fn);
   $p->empty_element_tags(1);
   while (my $token = $p->get_token) {
      if ($token->[0] eq 'T') {
      } elsif ($token->[0] eq 'S') {
# A start tag - evaluate the attributes in here
         foreach my $key (keys(%{$token->[2]})) {
            my $value=$token->[2]->{$key};
         } 
# - remember for embedded tags and for the end tag
         push(@{$stack->{'tags'}},{ 'name' => $token->[1], 'args' => $token->[2] });
      } elsif ($token->[0] eq 'E') {
# Unexpected ending tags
         if ($stack->{'tags'}->[-1]->{'name'} ne $token->[1]) {
            &error('unexpected_ending',$stack->{'tags'}->[-1]->{'name'},$token->[1]);
         }
# Pop the stack again
         pop(@{$stack->{'tags'}});
      } else {
         $output.=$token->[-1];
      }
   }
# The stack should be empty again
   for (my $i=0;$i<=$#{$stack->{'tags'}};$i++) {
       &error('missing_ending',$stack->{'tags'}->[$i]->{'name'});
   }
}

sub error {
   my ($code,$expected,$found)=@_;
   print "$code - $expected - $found\n";
}

