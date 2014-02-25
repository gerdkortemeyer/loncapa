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
use Sys::Hostname;
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
# and: are the addresses real?
my $found=0;
foreach my $host (keys(%{$cluster_table->{'hosts'}})) {
   if ($cluster_table->{'hosts'}->{$host}->{'address'} eq $cluster_manager) {
      $found=1;
      last;
   }
   unless (&inet_aton($cluster_table->{'hosts'}->{$host}->{'address'})) {
      print "Could not DNS resolve ".$cluster_table->{'hosts'}->{$host}->{'address'}."\n";
      exit;
   }
}
unless ($found) {
   print "Cluster manager not in cluster\n";
   exit;
}
# Are we cluster manager ourselves?
my $current_aton=&inet_aton(hostname);
unless ($current_aton) {
   print "Could not DNS resolve current host\n";
   exit;
}
my $cluster_aton=&inet_aton($cluster_manager);
unless ($cluster_aton) {
   print "Count not DNS resolve cluster master\n";
   exit;
}
my $we_are_master=(&inet_ntoa($current_aton) eq &inet_ntoa($cluster_aton));
#
# Good, looks like we have a valid cluster table
# We are in business!!!
#
# Make a backup of the mongodb configuration if not existing yet
unless (-e &lc_cluster_dir().'mongod.conf.bck') {
   system('cp /etc/mongod.conf '.&lc_cluster_dir().'mongod.conf.bck');
}
# Transfer content up to end of file or marker
open(IN,&lc_cluster_dir().'mongod.conf.bck');
open(OUT,'>'.&lc_cluster_dir().'mongod.conf');
while (my $line=<IN>) {
   if ($line=~/LON\-CAPA MARKER/) { last; }
   print OUT $line;
}
close(IN);
print OUT "\n# ======== LON-CAPA MARKER ======== DO NOT REMOVE ====================\n";
print OUT "# Configuration for LON-CAPA replica set below, based on cluster table\n";
print OUT "keyFile = ".&lc_cluster_dir()."mongo_keyfile\n";
print OUT "replSet = loncapa\n";

close(OUT);




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
