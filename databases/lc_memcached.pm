# The LearningOnline Network with CAPA - LON-CAPA
# Deal with memcached
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
#
package Apache::lc_memcached;

use strict;
use Cache::Memcached;
use Apache::lc_logs;

require Exporter;
our @ISA = qw (Exporter);
our @EXPORT = qw(mget mset);


use vars qw($memd);

#
# Get key
sub mget {
   return $memd->get(@_[0]);
}

#
# Set key, value, expiration
sub mset {
   $memd->set(@_);
}
   


#
# Initialize the memd client, local host
#
sub init_memd {
   $memd=new Cache::Memcached({'servers' => ['127.0.0.1:11211']});
   if ($memd->set('connected','yes')) {
      &lognotice("Connected to memcached");
   } else {
      &logerror("Could not connect to memcached");
   } 
}

BEGIN {
   &init_memd();
}

1;
__END__
