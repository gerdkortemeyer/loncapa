# The LearningOnline Network with CAPA - LON-CAPA
# Deal with everything having to do with course entities
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
package Apache::lc_entity_courses;

use strict;
use DBI;
use Apache::lc_logs;

use Apache::lc_connection_handle();
use Apache::lc_postgresql();
use Apache::lc_memcached();

use Apache2::Const qw(:common :http);

# ================================================================
# Make a new course
# ================================================================
#
# Make a new course on this machine
# This is also the routine that would be called by remote servers
#
sub local_make_new_course {
   my ($courseid,$domain)=@_;
# Are we even potentially in charge here?
   unless (&Apache::lc_connection_utils::we_are_library_server($domain)) {
      return undef;
   }
# First make sure this courseid does not exist
   if (&local_course_to_entity ($courseid,$domain)) {
# Oops, that courseid already exists locally!
      &logwarning("Tried to generate course ($courseid), but already exists locally");
      return undef;
   }
# Check all other library hosts, make sure they are responding
   my ($code,$reply)=&Apache::lc_dispatcher::query_all_domain_libraries($domain,
                                                                        "course_to_entity",
                                                                        "{ courseid : '$courseid', domain : '$domain' }");
# If we could not get a hold of all libraries, do not proceed. It may exist on that one!
   unless ($code eq HTTP_OK) {
      &logwarning("Tried to generate course ($courseid), but could not get replies from all library servers");
      return undef;
   }
# We found that courseid elsewhere
   if ($reply) {
      &logwarning("Tried to generate course ($courseid), but already exists in the cluster");
      return undef;
   }
# Okay, we are a library server for the domain and 
# now we can be sure that the courseid does not already exist
# Make new entity ID ...
   my $entity=&Apache::lc_entity_utils::make_unique_id();
# ... and assign
   &Apache::lc_postgresql::insert_course($courseid,$domain,$entity);
# Take ownership
   &Apache::lc_postgresql::insert_homeserver($entity,$domain,&Apache::lc_connection_utils::host_name());
# Return the entity
   return $entity;
}

#
# Make a new course on a ***particular*** remote machine
#
sub remote_make_new_course {
   my ($host,$courseid,$domain)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'make_new_course',
                                                                 "{ courseid : '$courseid', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return $response;
   } else {
      return undef;
   }
}

#
# Make a new course somewhere
#
sub make_new_course {
   my ($courseid,$domain)=@_;
   my $libhost=&Apache::lc_connection_utils::random_library_server($domain);
# Is it us?
   if ($libhost eq &Apache::lc_connection_utils::host_name()) {
      return &local_make_new_course($courseid,$domain);
   } elsif ($libhost) {
# It wants another server
      return &remote_make_new_course($libhost,$courseid,$domain);
   }
# Oops, it's neither here nor there
   return undef;
}

# ================================================================
# Convert stuff to entities
# ================================================================
# ==== Courseids to entities
#
# Try only the local machine
# - this is the one that needs to be called remotely
#
sub local_course_to_entity {
   my ($courseid,$domain)=@_;
# Do we have it in memcache?
   my $entity=&Apache::lc_memcached::lookup_course_entity($courseid,$domain);
   if ($entity) { return $entity; }
# Look in local database
   $entity=&Apache::lc_postgresql::lookup_course_entity($courseid,$domain);
# If we have one, might as well remember
   if ($entity) {
      &Apache::lc_memcached::insert_course($courseid,$domain,$entity);
   }
   return $entity;
}

#
# Try to get the entity from remote machines
#
sub remote_course_to_entity {
   my ($courseid,$domain)=@_;
   my ($code,$reply)=&Apache::lc_dispatcher::query_all_domain_libraries($domain,
                                                                        "course_to_entity",
                                                                        "{ courseid : '$courseid', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return $reply;
   } else {
      return undef;
   }
}

#
# Try at all cost
#
sub course_to_entity {
    my ($courseid,$domain)=@_;
# First look locally
    my $entity=&local_course_to_entity($courseid,$domain);
    if ($entity) { return $entity; }
# Nope, go out on the network
    $entity=&remote_course_to_entity($courseid,$domain);
    if ($entity) { 
       &Apache::lc_memcached::insert_course($courseid,$domain,$entity);
    }
    return $entity;
}


BEGIN {
   &Apache::lc_connection_handle::register('course_to_entity',undef,undef,undef,\&local_course_to_entity,'courseid','domain');
   &Apache::lc_connection_handle::register('make_new_course',undef,undef,undef,\&local_make_new_course,'courseid','domain');
}

1;
__END__
