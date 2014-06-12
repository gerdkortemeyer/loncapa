use strict;
use HTML::TokeParser;
use Data::Dumper;
use JSON::DWIW;

my $definitions='';
open(IN,'old_loncapa_tags_clean.json');
while (my $line=<IN>) {
   $definitions.=$line;
}
close(IN);
my ($defs,$error)=JSON::DWIW->new->from_json($definitions);

if ($error) {
   print "\nCould not read definitions: $error\n";
   exit;
}

my $stack;
my $error;

open(IN,"all_files.txt");
while (my $line=<IN>) {
   chomp($line);
   if ($line=~/\.\d+\.\w+$/) { next; }
   $error='';
   $stack=undef;
   &parse($line);
   if ($error) {
      print "\n====> $line\n$error\n";
   }
}
close(IN);

sub parse {
   my ($fn)=@_;
   my $p=HTML::TokeParser->new($fn);
   $p->empty_element_tags(1);
   while (my $token = $p->get_token) {
      if ($token->[0] eq 'T') {
      } elsif ($token->[0] eq 'S') {
         unless ($defs->{$token->[1]}) {
            &error('undefined_start_tag',$token->[1]);
         }
# Should this be here?
         if ($stack->{'tags'}->[-1]) {
            unless ($defs->{$stack->{'tags'}->[-1]->{'name'}}->{'encloses'}->{$token->[1]}) {
               &error('unexpected_embedded',$token->[1],$stack->{'tags'}->[-1]->{'name'});
            }
         }
# A start tag - evaluate the attributes in here
         foreach my $key (keys(%{$token->[2]})) {
            unless ($defs->{$token->[1]}->{'args'}->{$key}) {
               &error('undefined_argument',$token->[1],$key);
            }
            my $value=$token->[2]->{$key};
         } 
# - remember for embedded tags and for the end tag
         push(@{$stack->{'tags'}},{ 'name' => $token->[1], 'args' => $token->[2] });
      } elsif ($token->[0] eq 'E') {
         unless ($defs->{$token->[1]}) {
            &error('undefined_end_tag',$token->[1]);
         }
# Unexpected ending tags
         if ($stack->{'tags'}->[-1]->{'name'} ne $token->[1]) {
            &error('unexpected_ending',$stack->{'tags'}->[-1]->{'name'},$token->[1]);
         }
# Pop the stack again
         pop(@{$stack->{'tags'}});
      }
   }
# The stack should be empty again
   for (my $i=0;$i<=$#{$stack->{'tags'}};$i++) {
       &error('missing_ending',$stack->{'tags'}->[$i]->{'name'});
   }
}

sub error {
   my ($code,$expected,$found)=@_;
   $error.= "$code - $expected - $found\n";
}

