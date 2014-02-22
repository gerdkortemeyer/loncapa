# The LearningOnline Network with CAPA - LON-CAPA
#
# Initialize the cluster table
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
package Apache::lc_init_cluster_table;

use strict;
use Apache2::RequestRec();
use Apache2::RequestIO();
use Apache2::Const qw(:common :http);

use Apache::lc_parameters;
use Apache::lc_logs;
use Apache::lc_json_utils();
use Apache::lc_file_utils();
use Apache::lc_connection_utils();
use Apache::lc_connections();

sub cluster_manager {
# Read the cluster manager configuration file
   my $config=&Apache::lc_file_utils::readfile(&lc_cluster_manager());
   $config=~s/[^\w\.\-]//gs;
   return $config;
}

sub we_are_manager {
   return &Apache::lc_connection_utils::host_match(&Apache::lc_connection_utils::server_name(),&cluster_manager());
}

sub fetch_cluster_table {
# If we are cluster manager, we won't go out to fetch the table
   if (&we_are_manager()) {
      &lognotice("We are cluster manager, using local table");
      return;
   }
# Who is cluster manager?
   my $cluster_manager=&cluster_manager();
# If we don't have one, we have a problem
   unless ($cluster_manager) {
      &logerror("No cluster manager defined");
      return;
   } else {
      &lognotice("Using cluster manager $cluster_manager");
   }
# Load the cluster table from the cluster manager
   my ($code,$response)=&Apache::lc_connections::dispatch('GET',$cluster_manager,'cluster_table');
# Only overwrite the cluster table if connection was okay
   if ($code eq HTTP_OK) {
      &Apache::lc_file_utils::writefile(&lc_cluster_table(),$response);
      &lognotice("Successfully retrieved cluster table");
   } else {
      &logwarning("Failed to retrieve cluster table, code: $code");
   }
}

sub load_cluster_table {
# See if we have a cluster table
   unless (-e &lc_cluster_table()) {
# If not, get one
      &fetch_cluster_table();
# Still not?
      unless (-e &lc_cluster_table()) {
         &logerror("No cluster table available.");
         return;
      }
   }
# Evaluate the cluster table
   my $cluster_table=&Apache::lc_json_utils::json_to_perl(
                        &Apache::lc_file_utils::readfile(&lc_cluster_table())
                                                         );
# Basic sanity checks
   unless (ref($cluster_table->{'domains'})) {
      &logerror("Cluster table does not contain domains"); 
      return;
   }
   unless (ref($cluster_table->{'hosts'})) {
      &logerror("Cluster table does not contain hosts");
      return;
   }

# Okay, seems fine
   foreach my $host (keys(%{$cluster_table->{'hosts'}})) {
   }
}

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
   return OK;
}

BEGIN {
   &load_cluster_table();
}
1;
__END__
