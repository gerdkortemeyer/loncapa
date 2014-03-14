# The LearningOnline Network with CAPA - LON-CAPA
# Deal with everything having to do with URLs
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
package Apache::lc_entity_urls;

use strict;

use Apache2::Const qw(:common :http);

use Apache::lc_logs;
use Apache::lc_postgresql();
use Apache::lc_entity_utils();
use Apache::lc_connection_utils();


#
# Get URL data out
# /asset/version_type/version_arg/domain
#
sub split_url {
   my ($full_url)=@_;
   my ($version_type,$version_arg,$domain,$path)=($full_url=~/^\/asset\/([^\/]+)\/([^\/]+)\/([^\/]+)\/(.*)$/);
   return ($version_type,$version_arg,$domain,$domain.'/'.$path);
}

# ======================================================
# Make a new URL
# ======================================================
#
sub local_make_new_url {
   my ($version_type,$version_arg,$domain,$url)=&split_url(@_[0]);
# Are we even potentially in charge here?
   unless (&Apache::lc_connection_utils::we_are_library_server($domain)) {
       return undef;
   }
# First make sure this url does not exist
   if (&local_url_to_entity ($url)) {
# Oops, that url already exists locally!
      &logwarning("Tried to generate url ($url), but already exists locally");
      return undef;
   }
# Check all other library hosts, make sure they are responding
   my ($code,$reply)=&Apache::lc_dispatcher::query_all_domain_libraries($domain,"url_to_entity","{ url : '$url'}");
# If we could not get a hold of all libraries, do not proceed. It may exist on that one!
   unless ($code eq HTTP_OK) {
      &logwarning("Tried to generate url ($url), but could not get replies from all library servers");                                           return undef;
   }
# We found that url elsewhere
   if ($reply) {
      &logwarning("Tried to generate url ($url), but already exists in the cluster");
      return undef;
   }
# Okay, we are a library server for the domain and 
# now we can be sure that the url does not already exist
# Make new entity ID ...
   my $entity=&Apache::lc_entity_utils::make_unique_id();
# ... and assign
   &Apache::lc_postgresql::insert_url($url,$entity);
# Take ownership
   &Apache::lc_postgresql::insert_homeserver($entity,$domain,&Apache::lc_connection_utils::host_name());
# Subscribe ourselves
   &local_subscribe($entity,$domain,&Apache::lc_connection_utils::host_name());
# Make a metadata record
   &Apache::lc_mongodb::insert_metadata($entity,$domain,{ created => &Apache::lc_date_utils::now2str() });
# And return the entity
   return $entity;
}


# ======================================================
# URL - Entity
# ======================================================
#
# Check locally (also the one to be called from outside)
#
sub local_url_to_entity {
   my ($version_type,$version_arg,$domain,$url)=&split_url(@_[0]);
# Do we have it in memcache?
   my $entity=&Apache::lc_memcached::lookup_url_entity($url);
   if ($entity) { return $entity; }
# Look in local database
   $entity=&Apache::lc_postgresql::lookup_url_entity($url);
# If we have one, might as well remember
   if ($entity) {
      &Apache::lc_memcached::insert_url($url,$entity);
   }
   return $entity;
}

#
# Try to get the entity from remote machines
#

sub remote_url_to_entity {
   my ($full_url)=@_;
   my ($version_type,$version_arg,$domain,$url)=&split_url($full_url);
   my ($code,$reply)=&Apache::lc_dispatcher::query_all_domain_libraries($domain,"url_to_entity", 
                                     &Apache::lc_json_utils::perl_to_json({ full_url => $full_url })); 
   if ($code eq HTTP_OK) {
      return $reply;
   } else {
      return undef;
   }
}

#
# Try from anywhere
#
sub url_to_entity {
    my ($full_url)=@_;
# First look locally
    my $entity=&local_url_to_entity($full_url);
    if ($entity) { return $entity; }
# Nope, go out on the network
    $entity=&remote_url_to_entity($full_url);
    if ($entity) { 
       my ($version_type,$version_arg,$domain,$url)=&split_url($full_url);
       &Apache::lc_memcached::insert_url($url,$entity);
    }
    return $entity;
}

# ======================================================
# Subscriptions
# ======================================================
# Subscribe a host
# The homeserver keeps the list of the subscribed hosts
#
sub local_subscribe {
   my ($entity,$domain,$host)=@_;
# if this is not our entity, do not subscribe to it
   unless (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) { 
      &logwarning("Trying to subscribe to entity ($entity) domain ($domain), but not homeserver");
      return undef; 
   }
# Okay, subscribe
   return &Apache::lc_postgresql::subscribe($entity,$domain,$host);
}

#
# Unsubscribe a host
#
sub local_unsubscribe {
   my ($entity,$domain,$host)=@_;
# if this is not our entity, it's none of our business
   unless (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) { 
      &logwarning("Trying to unsubscribe to entity ($entity) domain ($domain), but not homeserver");
      return undef; 
   }
# The homeserver must not unsubscribe!
   if ($host eq &Apache::lc_connection_utils::host_name()) {
      &logwarning("Trying to unsubscribe to entity ($entity) domain ($domain), but the homeserver cannot unsubscribe!");
      return undef;
   }
# Okay, unsubscribe
   return &Apache::lc_postgresql::unsubscribe($entity,$domain,$host);
}

#
# List all subscribed hosts
#
sub local_subscribed {
   my ($entity,$host)=@_;
   return &Apache::lc_postgresql::subscribed($entity,$host);
}

1;
__END__
