# The LearningOnline Network with CAPA - LON-CAPA
# Dispatch requests to the cluster
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

package Apache::lc_dispatcher;

use strict;

use Apache::lc_parameters;
use Apache::lc_memcached();
use Apache2::Const qw(:common :http);

use vars qw(%addresses);

#
# Send a single command to a single server
#
sub command_dispatch {
   my ($host,$command,$jsondata)=@_;
   unless ($addresses{$host}) {
      my $connection_table=&Apache::lc_memcached::get_connection_table();
      my $addr=$connection_table->{'cluster_table'}->{'hosts'}->{$host}->{'address'};
      unless ($addr) {
         &logerror("Could not find address for ($host)");
         return (HTTP_SERVICE_UNAVAILABLE,undef);
      }
      $addresses{$host}=$addr;
   }
   return &Apache::lc_connections::dispatch('POST',
                                            $addresses{$host},
                                            "/connection_handle/$host/$command",
                                            $jsondata);
}
#
# Send a command to all library servers in a domain
#
sub all_domain_libraries {
   my ($domain,$command,$jsondata)=@_;
}

1;
__END__