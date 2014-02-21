# The LearningOnline Network with CAPA - LON-CAPA
#
# The cluster primary server delivering the cluster table
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
package Apache::lc_cluster_table;

use strict;
use Apache2::RequestRec();
use Apache2::RequestIO();
use Apache2::Connection();
use Apache2::ServerUtil();
use Apache2::Const qw(:common :http);

use Apache::lc_parameters;
use Apache::lc_logs;
use Apache::lc_connection_utils();
use Apache::lc_file_utils();

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
# We should not answer this if we are not the cluster manager
   unless (&Apache::lc_connection_utils::host_match(
               Apache2::ServerUtil->server->dir_config('cluster_manager'),
               $r->connection->local_ip())
          ) {
      return HTTP_BAD_REQUEST;
   } 
   &logdebug("Testing");
   $r->print(&lc_log_dir());
   $r->print(&Apache::lc_file_utils::readfile("/home/loncapa/cluster/cluster_table.json"));

   return OK;
}

1;
__END__
