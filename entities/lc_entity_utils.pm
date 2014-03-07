# The LearningOnline Network with CAPA - LON-CAPA
# Utilities for entities
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
package Apache::lc_entity_utils;

use strict;
use DBI;
use Data::Uniqid qw(luniqid);
use Digest::MD5 qw(md5_hex);
use Apache2::Const qw(:common :http);

use Apache::lc_memcached();
use Apache::lc_postgresql();
use Apache::lc_logs;
use Apache::lc_connection_utils();


# ================================================================
# IDs
# ================================================================
# ==== Generate a unique ID
sub make_unique_id {
   return &luniqid();
}

# === Oneway encryption of entities
# Takes domain,entity
# or any other array of strings
sub oneway {
   return md5_hex(@_);
}

# ================================================================
# Find the homeserver
# ================================================================
#
# Locally
#
sub local_homeserver {
   my ($entity,$domain)=@_;
# First see if it is already in memcached
   my $cached=&Apache::lc_memcached::lookup_homeserver($entity,$domain);
   if ($cached) { return $cached; }
# If not, see if we have it in our local database
   my $stored=&Apache::lc_postgresql::lookup_homeserver($entity,$domain);
   if ($stored) {
# Remember for later
      &Apache::lc_memcached::insert_homeserver($entity,$domain,$stored);
      return $stored; 
   }
   return undef;
}

#
# Remotely
#
sub remote_homeserver {
   my ($entity,$domain)=@_;
# Send the query to all library servers in the domain of that entity
   my ($code,$reply)=&Apache::lc_connection::dispatcher::all_domain_libraries($domain,
                                                                              "homeserver",
                                                                              "{ entity : '$entity', domain : '$domain' }");
# If we get a reasonable answer, store and return
   if (($code eq HTTP_OK) && (&Apache::lc_connection_utils::is_library_server($reply,$domain))) {
# Store it permanently
      &Apache::lc_postgresql::insert_homeserver($entity,$domain,$reply);
# Also put it into memory
      &Apache::lc_memcached::insert_homeserver($entity,$domain,$reply);
      &lognotice("Found homeserver entity ($entity) domain ($domain): $reply");
      return $reply;
   } else {
# Wow, something is fishy, we're out of here!
      &logerror("Error finding homeserver entity ($entity) domain ($domain): code ($code) with reply ($reply)");
      return undef;
   }
}

#
# Find at any cost
#
sub homeserver {
   my $found=&local_homeserver(@_);
   if ($found) { return $found; }
   return &remote_homeserver(@_);
}

1;
__END__
