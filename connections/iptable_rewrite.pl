# The LearningOnline Network with CAPA - LON-CAPA
#
# Rewrite the iptable based on cluster table 
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

# Retrieve command
#
my $cmd=lc(shift);
$cmd=~s/\W//gs;
unless ($cmd=~/^(close|rewrite)$/) {
   print "Must specify 'close' or 'rewrite'\n";
   exit;
}
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
# Good, looks like we have a valid cluster table
# Let's see if we can retrieve the iptable
system('iptables-save >'.&lc_cluster_dir().'backup.fw');
open(IN,&lc_cluster_dir().'backup.fw');
my $current_ip_table=join('',<IN>);
close(IN);
unless ($current_ip_table=~/\w/) {
   print "Could not retrieve iptables\n";
   exit;
}
# The next lines close the firewall for all LON-CAPA related activities
#
foreach my $line (split("\n",$current_ip_table)) {
   my @entries=split(/\s+/,$line);
   if (($entries[8] eq '--dport') || ($entries[8] eq '--sport')) {
      if (($entries[9]==27017) || ($entries[9]==27018) || ($entries[9]==27019)) {
         $entries[0]='-D';
         system('iptables',@entries);
      }
   }
}
# If all we wanted to do is close the firewall, we are done now
if ($cmd eq 'close') { 
   exit; 
}
# Apparently not, let's keep going
# Open ports for the IP addresses of all servers in the cluster
#
foreach my $host (keys(%{$cluster_table->{'hosts'}})) {
   my $hosta=&inet_aton($cluster_table->{'hosts'}->{$host}->{'address'});
   unless ($hosta) { 
      print "Invalid entry: $host\n";
      next;
   }
   my $hostip=&inet_ntoa($hosta);
   system("iptables -A INPUT -s $hostip -p tcp --destination-port 27017 -m state --state NEW,ESTABLISHED -j ACCEPT");
   system("iptables -A OUTPUT -d $hostip -p tcp --source-port 27017 -m state --state ESTABLISHED -j ACCEPT");
   system("iptables -A INPUT -s $hostip -p tcp --destination-port 27018 -m state --state NEW,ESTABLISHED -j ACCEPT");
   system("iptables -A OUTPUT -d $hostip -p tcp --source-port 27018 -m state --state ESTABLISHED -j ACCEPT");
   system("iptables -A INPUT -s $hostip -p tcp --destination-port 27019 -m state --state NEW,ESTABLISHED -j ACCEPT");
   system("iptables -A OUTPUT -d $hostip -p tcp --source-port 27019 -m state --state ESTABLISHED -j ACCEPT");
}

