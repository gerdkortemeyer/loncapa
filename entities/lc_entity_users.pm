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
use Apache::lc_logs;

use Apache::lc_connection_handle();
use Apache::lc_postgresql();
use Apache::lc_mongodb();
use Apache::lc_memcached();
use Apache::lc_date_utils();
use Apache::lc_dispatcher();
use Apache::lc_date_utils();
use Apache::lc_entity_namespace();

use Apache2::Const qw(:common :http);

# ================================================================
# Make a new user
# ================================================================
#
# Make a new user on this machine
# This is also the routine that would be called by remote servers
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
# Check all other library hosts, make sure they are responding
   my ($code,$reply)=&Apache::lc_dispatcher::query_all_domain_libraries($domain,
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
# Make a profile record
   &Apache::lc_mongodb::insert_profile($entity,$domain,{ created => &Apache::lc_date_utils::now2str() });
# Make a roleset
   &Apache::lc_mongodb::insert_roles($entity,$domain,{});
# Make an authentication record
   &Apache::lc_mongodb::insert_auth($entity,$domain,{});
# Return the entity
   return $entity;
}

#
# Make a new user on a ***particular*** remote machine
#
sub remote_make_new_user {
   my ($host,$username,$domain)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'make_new_user',
                                      "{ username : '$username', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return $response;
   } else {
      return undef;
   }
}

#
# Make a new user somewhere
#
sub make_new_user {
   my ($username,$domain)=@_;
   my $libhost=&Apache::lc_connection_utils::random_library_server($domain);
# Is it us?
   if ($libhost eq &Apache::lc_connection_utils::host_name()) {
      return &local_make_new_user($username,$domain);
   } elsif ($libhost) {
# It wants another server
      return &remote_make_new_user($libhost,$username,$domain);
   }
# Oops, it's neither here nor there
   return undef;
}

# ================================================================
# PID assignment
# ================================================================

sub local_assign_pid {
   my ($entity,$domain,$pid)=@_;
   my $existing=&pid_to_entity($pid,$domain);
   if ($existing) {
      if ($existing eq $entity) {
        return 1;
      } else {
        &logwarning("Trying to assign PID ($pid) to ($entity) ($domain), but already used by ($existing)");
        return 0;
      }
   }
   return &Apache::lc_postgresql::insert_pid($pid,$domain,$entity);
}

sub remote_assign_pid {
   my ($host,$entity,$domain,$pid)=@_;
   my ($code,$reply)=&Apache::lc_dispatcher::command_dispatch($host,
                                                              "assign_pid",
                                                              "{ entity : '$entity', domain : '$domain', pid : '$pid' }");
   if ($code eq HTTP_OK) {
      return $reply;
   } else {
      return undef;
   }
}

sub assign_pid {
   my ($entity,$domain,$pid)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_assign_pid($entity,$domain,$pid);
   } else {
      return &remote_assign_pid(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain,$pid);
   }
}

# ================================================================
# Dealing with screen form defaults
# ================================================================

sub set_screen_form_defaults {
   my ($entity,$domain,$screen,$defaults)=@_;
   return &Apache::lc_entity_namespace::modify_namespace($entity,$domain,'screen_form_defaults',{ $screen => $defaults });
}

sub screen_form_defaults {
   my ($entity,$domain,$screen)=@_;
   my $screen_defaults=&Apache::lc_entity_namespace::dump_namespace($entity,$domain,'screen_form_defaults');
   return $screen_defaults->{$screen};
}

# ================================================================
# Looking for names
# ================================================================

sub local_query_user_profiles {
   my ($term)=@_;
   $term=~s/^\s+//s;
   $term=~s/\s+$//s;
   my ($term1,$term2)=split(/[\s\,]+/,$term);
   return &Apache::lc_mongodb::query_user_profiles($term1,$term2);
}

sub local_json_query_user_profiles {
   return &Apache::lc_json_utils::perl_to_json(&local_query_user_profiles(@_));
}

sub query_user_profiles {
   my ($domain,$term)=@_;
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
   my ($code,$reply)=&Apache::lc_dispatcher::query_all_domain_libraries($domain,
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

#
# Reverse entity to username
#
sub local_entity_to_username {
   my ($entity,$domain)=@_;
   my $username=&Apache::lc_memcached::lookup_entity_username($entity,$domain);
   if ($username) { return $username; }
   $username=&Apache::lc_postgresql::lookup_entity_username($entity,$domain);
   if ($username) {
      &Apache::lc_memcached::insert_username($username,$domain,$entity);
   }
   return $username;
}

sub remote_entity_to_username {
   my ($host,$entity,$domain)=@_;
   my ($code,$reply)=&Apache::lc_dispatcher::command_dispatch($host,"entity_to_username",
                                                              "{ entity : '$entity', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return $reply;
   } else {
      return undef;
   }
}

sub entity_to_username {
   my ($entity,$domain)=@_;
   my $username=&Apache::lc_memcached::lookup_entity_username($entity,$domain);
   if ($username) { return $username; }
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_entity_to_username($entity,$domain);
   } else {
      $username=&remote_entity_to_username(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain);
      if ($username) {
         &Apache::lc_memcached::insert_username($username,$domain,$entity);
      }
      return $username;
   }
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
   my ($code,$reply)=&Apache::lc_dispatcher::query_all_domain_libraries($domain,
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

#
# Reverse
#

sub local_entity_to_pid {
   my ($entity,$domain)=@_;
   my $pid=&Apache::lc_memcached::lookup_entity_pid($entity,$domain);
   if ($pid) { return $pid; }
   $pid=&Apache::lc_postgresql::lookup_entity_pid($entity,$domain);
   if ($pid) {
      &Apache::lc_memcached::insert_pid($pid,$domain,$entity);
   }
   return $pid;
}

sub remote_entity_to_pid {
   my ($host,$entity,$domain)=@_;
   my ($code,$reply)=&Apache::lc_dispatcher::command_dispatch($host,"entity_to_pid",
                                                              "{ entity : '$entity', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return $reply;
   } else {
      return undef;
   }
}

sub entity_to_pid {
   my ($entity,$domain)=@_;
   my $pid=&Apache::lc_memcached::lookup_entity_pid($entity,$domain);
   if ($pid) { return $pid; }
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_entity_to_pid($entity,$domain);
   } else {
      $pid=&remote_entity_to_pid(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain);
      if ($pid) {
         &Apache::lc_memcached::insert_pid($pid,$domain,$entity);
      }
      return $pid;
   }
}



#
# Various accessor functions for profile
#
sub set_full_name {
   my ($entity,$domain,$firstname,$middlename,$lastname,$suffix)=@_;
   return &Apache::lc_entity_profile::modify_profile($entity,$domain,{ firstname => $firstname, 
                                                                       middlename => $middlename, 
                                                                       lastname => $lastname, 
                                                                       suffix => $suffix });
}

sub full_name {
   my ($entity,$domain)=@_;
   my $profile=&Apache::lc_entity_profile::dump_profile($entity,$domain);
   return ($profile->{'firstname'},$profile->{'middlename'},$profile->{'lastname'},$profile->{'suffix'});
}

#
# Set last access to an entity (e.g., a course)
#
sub set_last_accessed {
   my ($entity,$domain,$accessed_entity,$accessed_domain)=@_;
   return &Apache::lc_entity_profile::modify_profile($entity,$domain,{ last_accessed => 
                                                                       { $accessed_domain => 
                                                                          { $accessed_entity => &Apache::lc_date_utils::now2str() }
                                                                       }
                                                                     });
}

#
# Gives back the whole last accessed record
#
sub last_accessed {
   my ($entity,$domain)=@_;
   my $profile=&Apache::lc_entity_profile::dump_profile($entity,$domain);
   return $profile->{'last_accessed'};
}



BEGIN {
   &Apache::lc_connection_handle::register('pid_to_entity',undef,undef,undef,\&local_pid_to_entity,'pid','domain');
   &Apache::lc_connection_handle::register('username_to_entity',undef,undef,undef,\&local_username_to_entity,'username','domain');
   &Apache::lc_connection_handle::register('entity_to_pid',undef,undef,undef,\&local_entity_to_pid,'entity','domain');
   &Apache::lc_connection_handle::register('entity_to_username',undef,undef,undef,\&local_entity_to_username,'entity','domain');
   &Apache::lc_connection_handle::register('make_new_user',undef,undef,undef,\&local_make_new_user,'username','domain');
   &Apache::lc_connection_handle::register('assign_pid',undef,undef,undef,\&local_assign_pid,'entity','domain','pid');
   &Apache::lc_connection_handle::register('query_user_profiles',undef,undef,undef,\&local_json_query_user_profiles,'term');
}

1;
__END__
