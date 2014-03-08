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
use APR::Table;
use Apache2::Const qw(:common :http);

use Apache::lc_memcached();
use Apache::lc_connection_handle();

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

#
# Is a host a library server for a domain?
#
sub is_library_server {
   my ($host,$domain)=@_;
   my $connection_table=&Apache::lc_memcached::get_connection_table();
   return ($connection_table->{'cluster_table'}->{'hosts'}->{$host}->{'domains'}->{$domain}->{'function'} eq 'library');
}

#
# Is this a library server for a domain?
#
sub we_are_library_server {
   my ($domain)=@_;
   my $connection_table=&Apache::lc_memcached::get_connection_table();
   return ($connection_table->{'cluster_table'}->{'hosts'}->{$connection_table->{'self'}}->{'domains'}->{$domain}->{'function'} eq 'library');
}

#
# Get a random library server in the domain
#
sub random_library_server {
   my ($domain)=@_;
   my $connection_table=&Apache::lc_memcached::get_connection_table();
   my @libraries=split(/\,/,$connection_table->{'libraries'}->{$domain});
# First entry is empty! Take a random one
   my $random_library=$libraries[1+int(rand($#libraries))];
   if (&online($random_library)) {
      return $random_library;
   }
# Wow, that one was offline. Take the first one that's online.
   foreach my $library (@libraries) {
      unless ($library) { next; }
      if (&online($library)) {
         return $library;
      }
   }
   return undef;
}

#
# Check if a server is online
#
sub online {
   my ($host)=@_;
# If it's us, we are online or we weren't here
   if ($host eq &host_name()) { return 1; }
# Okay, it's not us. Contact them
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'online');
   if (($code eq HTTP_OK) && ($response eq 'ok')) { return 1; }
# Nope
   return 0;
}

#
# This gets called when a remote server asks "online?"
#
sub local_online {
   return 'ok';
}

#
# What is our hostname?
#
sub host_name {
   my $connection_table=&Apache::lc_memcached::get_connection_table();
   return $connection_table->{'self'};
}

#
# Get posted data out of a request
# Takes the request object
#
sub extract_content {
   my ($r)=@_;
   my $content='';
   if ($r->headers_in->{"Content-length"}>0) {
      $r->read($content,$r->headers_in->{"Content-length"});
   }
   return $content;
}

BEGIN {
   &Apache::lc_connection_handle::register('online',undef,undef,undef,\&local_online);
}

1;
__END__
