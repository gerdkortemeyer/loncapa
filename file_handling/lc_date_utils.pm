# The LearningOnline Network with CAPA - LON-CAPA
# Utilities for handling dates 
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
package Apache::lc_date_utils;

use strict;
use Time::y2038;
use Time::HiRes;

use Apache::lc_logs;

my %months=(Jan=>0,Feb=>1,Mar=>2,Apr=>3,May=>4,Jun=>5,
            Jul=>6,Aug=>7,Sep=>8,Oct=>9,Nov=>10,Dec=>11);

# ================================================================
# Timer for debugging/optimization only. Calls to these routines
# should not be in production versions
# ================================================================
#
my $timer_log;
my $timer_last;
my $timer_start;

sub starttimer {
   my ($msg)=@_;
   $timer_log="\nStart\t$msg\n";
   $timer_start=&Time::HiRes::time();
   $timer_last=$timer_start;
}

sub marktimer {
   my ($msg)=@_;
   my $now=&Time::HiRes::time();
   my $elapsed=int(1000.*($now-$timer_last)+.5);
   $timer_log.="Mark\t$msg\t$elapsed ms\n";
   $timer_last=$now;
}

sub endtimer {
   my ($msg)=@_;
   my $now=&Time::HiRes::time();
   my $elapsed=int(1000.*($now-$timer_start)+.5);
   $timer_log.="End\t$msg\t$elapsed ms\n";
   &logdebug($timer_log);
}

# ================================================================
# Time handling using Time::y2038
# ================================================================
# ==== All date operations with the Core should be done here.
# All stored times should be GMT.
#
# ==== Give current time as string
#
sub now2str {
   return scalar &gmtime();
}

# ==== Turn string into (extended) epoch seconds
#
sub str2num {
   my ($datestr)=@_;
# If _ is used instead of string (for URLs)
   $datestr=~s/\_+/ /g;
# Sat Dec  6 03:48:16 142715360
   if ($datestr=~/\s*(\w+)\s+(\d+)\s+(\d+)\:(\d+)\:(\d+)\s+(\d+)$/) {
      return &timegm($5,$4,$3,$2,$months{$1},$6-1900);
   } else {
      return 0;
   }
}

# ==== Turn (extended) epoch seconds into string
#
sub num2str {
   my ($num)=@_;
   return scalar &gmtime($num);
}

1;
__END__
