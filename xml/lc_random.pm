# The LearningOnline Network with CAPA - LON-CAPA
# The random number generator 
#
# Copyright (C) 2014 Michigan State University Board of Trustees
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
package Apache::lc_random;

use strict;

use Math::Random();
use Math::BigInt;
use Digest::MD5 qw(md5_hex);

use Apache::lc_logs;

my @lowerseed;
my @upperseed;

#
# Set the random number generation based on a phrase
#
sub set_context_random_seed {
   my ($phrase)=@_;
# Form the hex digest of the phrase
   my $digest=&md5_hex($phrase);
# The digest will have 32 characters
# Replace the non-numbers
   $digest=~tr/a-f/1-6/;
# Now have 32 digits   
# Split in half, turn into numbers, put in range of Math::Random, store
   &pushseed(1+scalar(Math::BigInt->new(substr($digest,0,16))->bmod(2147483562)),
             1+scalar(Math::BigInt->new(substr($digest,16,16))->bmod(2147483398)));
}

#
# Generate phrase
#
sub contextseed {
   my ($context,$tagid)=@_;
   return join(':',$context->{'user'}->{'entity'},
                   $context->{'user'}->{'domain'},
                   $context->{'course'}->{'entity'},
                   $context->{'course'}->{'domain'},
                   $context->{'asset'}->{'assetid'},
                   $context->{'randversion'},
                   $tagid);
}

# === Routines that can be called from Perl scripts (among others);
#

sub random {
   my ($lower,$upper,$step)=@_;
   $step=abs($step);
# Sanity
   unless ($step>0) { return $lower; }
   if (($lower+$step)>$upper) { return $lower; } 
# Restore the random seed
   &loadseed();
# Return value
   my $value=0;
# How many steps do we have?
   my $maxn=($upper-$lower)/$step;
   if ($maxn>1e300) {
# Continuous case
      $value=$lower+&Math::Random::random_uniform(1,0,$upper-$lower);
   } elsif ($maxn>2147483561) {
# Not enough available noise to do integer
      $value=$lower+$step*int(0.5+&Math::Random::random_uniform(1,0,$upper-$lower)/$step);
   } else {
# Nice, we can do this smoothly
      $value=$lower+$step*&Math::Random::random_uniform_integer(1,0,$maxn);
   }
# Save the random seed
   &saveseed();
   return $value;
}


# === Internal routines
#
# The seed stack 
# Push a new value on top of the stack (problem/part)
#
sub pushseed {
   my ($lower,$upper)=@_;
   if (($lower>2147483562) || ($upper>2147483398) || ($lower<1) || ($upper<1)) {
      &logerror("Seed out of range: [$lower] [$upper]");
      $lower=1;
      $upper=1;
   }
   push(@lowerseed,$lower);
   push(@upperseed,$upper);
}

#
# Pop the stack when end of problem/part is reached
#
sub popseed {
   unless (($#lowerseed>=0) && ($#upperseed>=0)) {
      &logwarning("Cannot pop empty random seed stack.");
      return;
   }
   pop(@lowerseed);
   pop(@upperseed);
}

#
# Flush the stack
#
sub resetseed {
   unless (($#lowerseed==-1) && ($#upperseed==-1)) {
      &logwarning("Random seed stack was not empty.");
   }
   @upperseed=[];
   @lowerseed=[];
}

#
# Save and load top of stack
#
sub loadseed {
   if (($#lowerseed>=0) && ($#upperseed>=0)) {
      &Math::Random::random_set_seed($lowerseed[-1],$upperseed[-1]);
   }
}

sub saveseed {
   if (($#lowerseed>=0) && ($#upperseed>=0)) {
      ($lowerseed[-1],$upperseed[-1])=&Math::Random::random_get_seed();
   }
}

BEGIN {
   &resetseed();
}

1;
__END__
