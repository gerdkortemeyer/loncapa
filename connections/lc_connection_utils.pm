# The LearningOnline Network with CAPA - LON-CAPA
#
# Utilities for cluster connections
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
package Apache::lc_connection_utils;

use strict;
use Sys::Hostname;
use Socket;
use Apache::lc_memcached;


#
# Check if two hosts are the same
#
sub host_match {
   my ($host1,$host2)=@_;
   my $hostip1=&inet_aton($host1);
   my $hostip2=&inet_aton($host2);
   unless (($hostip1) && ($hostip2)) { return 0; }
   return (&inet_ntoa($hostip1) eq &inet_ntoa($hostip2));
}

#
# Who are we?
#
sub server_name {
   return hostname;
}

1;
__END__
