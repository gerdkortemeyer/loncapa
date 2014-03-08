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
# Do we have the address cached in this module?
   unless ($addresses{$host}) {
# Nope, get it and remember it
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
# Send a query command to all library servers in a domain
# EXCEPT this server
# Return with first valid answer
#
sub query_all_domain_libraries {
   my ($domain,$command,$jsondata)=@_;
# Get connection table from memchache
   my $connection_table=&Apache::lc_memcached::get_connection_table();
# The world is still okay
   my $error_code=0;
   foreach my $host (split(/\,/,$connection_table->{'libraries'}->{$domain})) {
# Not interested in ourselves
      unless ($host) { next; }
      if ($host eq $connection_table->{'self'}) { next; }
# Send command
      my ($code,$response)=&command_dispatch($host,$command,$jsondata);
      if ($code eq HTTP_OK) {
# Valid response, we are done
         return ($code,$response);
      } elsif ($code ne HTTP_NOT_FOUND) {
# There was a problem. Not yet fatal, maybe another host has the answer
         $error_code=$code;
         &logwarning("Could not contact host ($host): code ($code)");
      }
   }
# Nobody had an answer
   if ($error_code) {
# Maybe the failed one would have had the answer, but we don't know
      return ($error_code,undef);
   } else {
# There just is no answer
      return (HTTP_OK,undef);
   }
}

1;
__END__
