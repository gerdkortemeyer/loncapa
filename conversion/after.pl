

my $outstructure=undef;
foreach my $tag (keys(%{$VAR1})) {
   unless ($tag=~/^\w+$/) { next; }
   $outstructure->{$tag}->{'occurances'}=$VAR1->{$tag}->{'num'};
   foreach my $arg (keys(%{$VAR1->{$tag}->{'args'}})) {
      unless ($arg=~/^\w+$/) { next; }
      my $occur=0;
      foreach my $value (keys(%{$VAR1->{$tag}->{'args'}->{$arg}})) {
         $occur+=$VAR1->{$tag}->{'args'}->{$arg}->{$value};
      }
      if ($occur) {
         $outstructure->{$tag}->{'args'}->{$arg}=$occur;
      }
   }
   foreach my $inside (keys(%{$VAR1->{$tag}->{'inside'}})) {
      unless ($inside=~/^\w+$/) { next; }
      $outstructure->{$inside}->{'encloses'}->{$tag}+=$VAR1->{$tag}->{'inside'}->{$inside};
   }
}
print JSON::DWIW->new->to_json($outstructure,{ pretty => 1})."\n";
