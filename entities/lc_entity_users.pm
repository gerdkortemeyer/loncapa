# The LearningOnline Network with CAPA - LON-CAPA
# Deal with everything having to do with users
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
package Apache::lc_entity_users;

use strict;
use DBI;
use Apache::lc_logs;

use Apache::lc_connection_handle();
use Apache::lc_postgresql();
use Apache::lc_memcached();

use Apache2::Const qw(:common :http);

# ================================================================
# Make a new user
# ================================================================
#
# Make a new user on this machine
#
sub local_make_new_user {
   my ($username,$domain)=@_;
# Are we even potentially in charge here?
   unless (&Apache::lc_connection_utils::we_are_library_server($domain)) {
      return undef;
   }
# First make sure this username does not exist
   if (&local_username_to_entity ($username,$domain)) {
# Oops, that username already exists locally!
      &logwarning("Tried to generate username ($username), but already exists locally");
      return undef;
   }
# Check all other library hosts, make sure they are responsing
   my ($code,$reply)=&Apache::lc_connection::dispatcher::query_all_domain_libraries($domain,
                                                                              "username_to_entity",
                                                                              "{ username : '$username', domain : '$domain' }");
# If we could not get a hold of all libraries, do not proceed. It may exist on that one!
   unless ($code eq HTTP_OK) {
      &logwarning("Tried to generate username ($username), but could not get replies from all library servers");
      return undef;
   }
# We found that username elsewhere
   if ($reply) {
      &logwarning("Tried to generate username ($username), but already exists in the cluster");
      return undef;
   }
# Okay, we are a library server for the domain and 
# now we can be sure that the username does not already exist
# Make new entity ID ...
   my $entity=&Apache::lc_entity_utils::make_unique_id();
# ... and assign
   &Apache::lc_postgresql::insert_username($username,$domain,$entity);
# Take ownership
   &Apache::lc_postgresql::insert_homeserver($entity,$domain,&Apache::lc_connection_utils::host_name());
# Return the entity
   return $entity;
}


# ================================================================
# Convert stuff to entities
# ================================================================
# ==== Usernames to entities
#
# Try only the local machine
# - this is the one that needs to be called remotely
#
sub local_username_to_entity {
   my ($username,$domain)=@_;
# Do we have it in memcache?
   my $entity=&Apache::lc_memcached::lookup_username_entity($username,$domain);
   if ($entity) { return $entity; }
# Look in local database
   $entity=&Apache::lc_postgresql::lookup_username_entity($username,$domain);
# If we have one, might as well remember
   if ($entity) {
      &Apache::lc_memcached::insert_username($username,$domain,$entity);
   }
   return $entity;
}

#
# Try to get the entity from remote machines
#
sub remote_username_to_entity {
   my ($username,$domain)=@_;
   my ($code,$reply)=&Apache::lc_connection::dispatcher::query_all_domain_libraries($domain,
                                                                              "username_to_entity",
                                                                              "{ username : '$username', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return $reply;
   } else {
      return undef;
   }
}

#
# Try at all cost
#
sub username_to_entity {
    my ($username,$domain)=@_;
# First look locally
    my $entity=&local_username_to_entity($username,$domain);
    if ($entity) { return $entity; }
# Nope, go out on the network
    $entity=&remote_username_to_entity($username,$domain);
    if ($entity) { 
       &Apache::lc_memcached::insert_username($username,$domain,$entity);
    }
    return $entity;
}

# ==== PIDs to entities
# Try only the local machine
#- this is the one that needs to be called remotely
#
sub local_pid_to_entity {
   my ($pid,$domain)=@_;
# Do we have it in memcache?
   my $entity=&Apache::lc_memcached::lookup_pid_entity($pid,$domain);
   if ($entity) { return $entity; }
# Look in local database
   $entity=&Apache::lc_postgresql::lookup_pid_entity(@_);
# If we have one, might as well remember
   if ($entity) {
      &Apache::lc_memcached::insert_pid($pid,$domain,$entity);
   }
   return $entity;
}

#
# Try to get the entity from remote machines
#
sub remote_pid_to_entity {
   my ($pid,$domain)=@_;
   my ($code,$reply)=&Apache::lc_connection::dispatcher::query_all_domain_libraries($domain,
                                                                                    "pid_to_entity",
                                                                                    "{ pid : '$pid', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return $reply;
   } else {
      return undef;
   }
}

#
# Try at all cost
#
sub pid_to_entity {
   my ($pid,$domain)=@_;
# Look locally
   my $entity=&local_pid_to_entity($pid,$domain);
   if ($entity) { return $entity; }
# Nope, go out on the network
   $entity=&remote_pid_to_entity($pid,$domain);
   if ($entity) {
      &Apache::lc_memcached::insert_pid($pid,$domain,$entity);
   }
   return $entity;
}

BEGIN {
   &Apache::lc_connection_handle::register('pid_to_entity',undef,undef,undef,\&local_pid_to_entity,'pid','domain');
   &Apache::lc_connection_handle::register('username_to_entity',undef,undef,undef,\&local_username_to_entity,'username','domain');
   &Apache::lc_connection_handle::register('make_new_user',undef,undef,undef,\&local_make_new_user,'username','domain','authjson');
}

1;
__END__
