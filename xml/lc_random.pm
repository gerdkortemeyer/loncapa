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

my $lowerseed;
my $upperseed;

#
# Reset the random number generation based on a phrase
#
sub reset_random_seed {
   my ($phrase)=@_;
# Form the hex digest of the phrase
   my $digest=&md5_hex($phrase);
# The digest will have 32 characters
# Replace the non-numbers
   $digest=~tr/a-f/1-6/;
# Now have 32 digits   
# Split in half, turn into numbers, put in range of Math::Random, store
   &saveseed(1+scalar(Math::BigInt->new(substr($digest,0,16))->bmod(2147483562)),
             1+scalar(Math::BigInt->new(substr($digest,16,16))->bmod(2147483398)));
}

#
# Save and load seeds from global
#
sub saveseed {
   my ($lower,$upper)=@_;
   if (($lower>2147483562) || ($upper>2147483398) || ($lower<1) || ($upper<1)) {
      &logerror("Seed out of range: [$lower] [$upper]");
   }
   $lowerseed=$lower;
   $upperseed=$upper;
}

sub loadseed {
   return($lowerseed,$upperseed);
}

#
# Push and pull the seed
#

sub pushseed {
   &saveseed(&Math::Random::random_get_seed());
}

sub pullseed {
   &Math::Random::random_set_seed(&loadseed());
}
1;
__END__
