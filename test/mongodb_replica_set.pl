# The LearningOnline Network with CAPA - LON-CAPA
#
# Write configuration for mongodb replica set 
# Must be run with root privileges
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
use strict;
use lib '/home/httpd/lib/perl';
use Apache::lc_parameters;
use JSON::DWIW;
use Socket;

# Do we have a cluster table?
#
unless (-e &lc_cluster_table()) {
   print "No cluster table\n";
   exit;
}
# Apparently yes. Can we read it?
#
unless (open(IN,&lc_cluster_table())) { 
   print "Cannot open cluster table, $!\n"; 
   exit; 
}
my $cluster_table_data=join('',<IN>);
close(IN);
# Does the cluster table contain anything?
#
unless ($cluster_table_data=~/\w/) {
   print "Cluster table is empty\n";
   exit;
}
# See if we can digest this
#
my $cluster_table=JSON::DWIW->new->from_json($cluster_table_data);
unless (ref($cluster_table->{'hosts'})) {
   print "Cluster table does not contain hosts\n";
   exit;
}
# Do we know who is cluster master?
unless (-e &lc_cluster_manager()) {
   print "Cluster manager not defined\n";
   exit;
}
# Get the cluster manager
open(IN,&lc_cluster_manager());
my $cluster_manager=<IN>;
close(IN);
$cluster_manager=~s/[^\w\.\-]//gs;
unless ($cluster_manager) {
   print "Cluster manager malconfigured\n";
   exit;
}
# Last check: is the cluster manager part of the cluster?
my $found=0;
foreach my $host (keys(%{$cluster_table->{'hosts'}})) {
   if ($cluster_table->{'hosts'}->{$host}->{'address'} eq $cluster_manager) {
      $found=1;
      last;
   }
}
unless ($found) {
   print "Cluster manager not in cluster\n";
   exit;
}
#
# Good, looks like we have a valid cluster table
# We are in busines!!!
#





# Write the configuration file
#open(OUT,'>'.&lc_cluster_dir().'mongod.conf');
#print OUT <<ENDHEADER;
#config = {
#"_id":"lctest",
#"members":[
#ENDHEADER
#my $num=0;
#foreach my $host (keys(%{$cluster_table->{'hosts'}})) {
#   if ($num) { print OUT ",\n"; }
#   print OUT '{"_id" : '.$num.', "host" : "'.$cluster_table->{'hosts'}->{$host}->{'address'}.':27017"}';
#   $num++
#}
#print OUT "\n]\n}\n";
#close(OUT);
