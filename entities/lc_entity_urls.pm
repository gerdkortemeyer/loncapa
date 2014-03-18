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
use Apache::lc_parameters;

use File::stat;

#
# Get URL data out
# /asset/version_type/version_arg/domain/authorentity/...
#
sub split_url {
   my ($full_url)=@_;
   my ($version_type,$version_arg,$domain,$author,$path)=($full_url=~/^\/(?:asset|raw)\/([^\/]+)\/([^\/]+)\/([^\/]+)\/([^\/]+)\/*(.*)$/);
   return ($version_type,$version_arg,$domain,$author,$domain.'/'.$author.'/'.$path);
}

# ======================================================
# Make a new URL
# ======================================================
#
sub local_make_new_url {
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url(@_[0]);
# Are we even potentially in charge here?
   unless (&Apache::lc_entity_utils::we_are_homeserver($author,$domain)) {
      &logwarning("Tried to generate url ($url), but not homeserver of entity ($author) domain ($domain)");
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
# Make a metadata record
   &Apache::lc_mongodb::insert_metadata($entity,$domain,{ created => &Apache::lc_date_utils::now2str() });
# And return the entity
   return $entity;
}

sub remote_make_new_url {
   my ($host,$full_url)=@_;
   unless ($host) {
      &logwarning("Cannot make new URL, no homewserver for ($full_url)");
      return undef;
   }
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'make_new_url',
                              &Apache::lc_json_utils::perl_to_json({ full_url => $full_url }));
   if ($code eq HTTP_OK) {
      return $response;
   } else {
      return undef;
   }
}

sub make_new_url {
   my ($full_url)=@_;
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
   if (&Apache::lc_entity_utils::we_are_homeserver($author,$domain)) {
      return &local_make_new_url($full_url);
   } else {
      return &remote_make_new_url(&Apache::lc_entity_utils::homeserver($author,$domain),$full_url);
   }
}


# ======================================================
# URL - Entity
# ======================================================
#
# Check locally (also the one to be called from outside)
#
sub local_url_to_entity {
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url(@_[0]);
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
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
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
       my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
       &Apache::lc_memcached::insert_url($url,$entity);
    }
    return $entity;
}

#
# Get the complete filepath
# /asset/versiontype/versionarg/domain/path
sub url_to_filepath {
   my ($full_url)=@_;
# First see if this is for real, i.e., if there is a corresponding entity
   my $entity=&url_to_entity($full_url);
   unless ($entity) { return undef; }
# Okay, now determine where it would sit on the filesystem
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
   return &Apache::lc_file_utils::asset_resource_filename($entity,$domain,$version_type,$version_arg);
}

#
# Get the complete filepath for a raw resource
# /raw/versiontype/versionarg/domain/entity
#
sub raw_to_filepath {
   my ($raw_url)=@_;
   my ($version_type,$version_arg,$domain,$entity)=&split_url($raw_url);
   return &Apache::lc_file_utils::asset_resource_filename($entity,$domain,$version_type,$version_arg);
}


# ======================================================
# Copy an asset
# ======================================================
#
sub copy_raw_asset {
   my ($entity,$domain,$version_type,$version_arg)=@_;
# Get the raw file
   if (&Apache::lc_dispatcher::copy_file(&Apache::lc_entity_utils::homeserver($entity,$domain),'/raw/'.$version_type.'/'.$version_arg.'/'.$domain.'/'.$entity,
                                         &Apache::lc_file_utils::asset_resource_filename($entity,$domain,$version_type,$version_arg))) {
      return 1;
   }
   &logwarning("Failed to copy raw asset entity ($entity) domain ($domain)");
   return 0;
}

# ======================================================
# Replication
# ======================================================
#
# Get a new copy of $entity and $domain
#
sub local_fetch_update {
   my ($entity,$domain)=@_;
   my $filename=&Apache::lc_file_utils::asset_resource_filename($entity,$domain,'-','-');
# Do we even have this?
   unless (-e $filename) {
      &logwarning("Asked to update entity ($entity) domain ($domain), but no local copy");
      &unsubscribe($entity,$domain);
      return undef;
   }
# Okay, how long has it been since we last used this?
   my $sb=stat($filename);
   my $lastaccess=$sb->atime;
# Unsubscribe after a day of not being used
#FIXME: y2038?
   if (time-$lastaccess>&lc_long_expire()) {
      &lognotice("Unsubscribing from entity ($entity) domain ($domain), unused");
      &unsubscribe($entity,$domain);
# And remove local copy
      unlink($filename);
      return undef;
   }
# It's here and used!
   return &copy_raw_asset($entity,$domain,'-','-');
}

# Subscribes to a URL and copies it
#
sub replicate {
   my ($full_url)=@_;
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
   my $entity=&url_to_entity($full_url);
# If the version is latest, we need to be kept up-to-date
   if ($version_type eq '-') {
# Subscribe to it
      unless (&subscribe($entity,$domain)) {
         &logwarning("Failed to subscribe to URL ($full_url) entity ($entity) domain ($domain)");
         return 0;
      }
   }
# Now copy it - the unprocessed version
   if (&copy_raw_asset($entity,$domain,$version_type,$version_arg)) {
      return 1;
   }
   &logwarning("Failed to copy URL ($full_url) entity ($entity) domain ($domain)");
   return 0;
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
      &logwarning("Host ($host) trying to subscribe to entity ($entity) domain ($domain), but not homeserver");
      return undef; 
   }
   if (&local_already_subscribed($entity,$domain,$host)) {
      &lognotice("Host ($host) trying to subscribe to entity ($entity) domain ($domain), but already subscribed");
      return 1;
   }
# Okay, subscribe
   return (!(&Apache::lc_postgresql::subscribe($entity,$domain,$host)<0));
}

#
# Subscribe on a specific host
#
sub remote_subscribe {
   my ($remotehost,$entity,$domain,$thishost)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($remotehost,'subscribe',
                                                                 "{ entity : '$entity', domain : '$domain', host : '$thishost' }");
   if ($code eq HTTP_OK) {
      return $response;
   } else {
      return undef;
   }
}

sub subscribe {
   my ($entity,$domain)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
# That's odd, why are we doing this?
      &logwarning("Explicitly trying to subscribe to entity ($entity) domain ($domain), but we are homeserver");
      return undef;
   } else {
      return &remote_subscribe(&Apache::lc_entity_utils::homeserver($entity,$domain),
                               $entity,$domain,&Apache::lc_connection_utils::host_name());
   }
}

#
# Unsubscribe a host
#
sub local_unsubscribe {
   my ($entity,$domain,$host)=@_;
# if this is not our entity, it's none of our business
   unless (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) { 
      &logwarning("Trying to unsubscribe from entity ($entity) domain ($domain), but not homeserver");
      return undef; 
   }
# The homeserver must not unsubscribe!
   if ($host eq &Apache::lc_connection_utils::host_name()) {
      &logwarning("Trying to unsubscribe from entity ($entity) domain ($domain), but the homeserver cannot unsubscribe!");
      return undef;
   }
# Okay, unsubscribe
   return (!(&Apache::lc_postgresql::unsubscribe($entity,$domain,$host)<0));
}

sub remote_unsubscribe {
   my ($remotehost,$entity,$domain,$thishost)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($remotehost,'unsubscribe',
                                                                 "{ entity : '$entity', domain : '$domain', host : '$thishost' }");
   if ($code eq HTTP_OK) {
      return $response;
   } else {
      return undef;
   }
}

sub unsubscribe {
   my ($entity,$domain)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
# That's not good, we cannot unsubscribe from our own assets
      &logwarning("Trying to unsubscribe from entity ($entity) domain ($domain), but we are homeserver");
      return undef;
   } else {
      return &remote_unsubscribe(&Apache::lc_entity_utils::homeserver($entity,$domain),
                                 $entity,$domain,&Apache::lc_connection_utils::host_name());
   }
}


#
# List all subscribed hosts
#
sub local_subscriptions {
   my ($entity,$domain)=@_;
   return &Apache::lc_postgresql::subscriptions($entity,$domain);
}

sub local_json_subscriptions {
   return &Apache::lc_json_utils::perl_to_json(&local_subscriptions(@_));
}

sub remote_subscriptions {
   my ($host,$entity,$domain)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'subscriptions',
                                                                 "{ entity : '$entity', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return &Apache::lc_json_utils::json_to_perl($response);
   } else {
      return undef;
   }
}

sub subscriptions {
   my ($entity,$domain)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_subscriptions($entity,$domain);
   } else {
      return &remote_subscriptions(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain);
   }
}

sub local_already_subscribed {
   my ($entity,$domain,$host)=@_;
   foreach my $thishost (&local_subscriptions($entity,$domain)) {
      if ($thishost eq $host) { return 1; }
   }
   return 0;
}

sub remote_notify_subscribed {
   my ($entity,$domain)=@_;
   my $ourselves=&Apache::lc_connection_utils::host_name();
   foreach my $host (&local_subscriptions($entity,$domain)) {
      unless ($host) { next; }
      if ($host eq $ourselves) { next; }
      my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'fetch_update',
                                                                 "{ entity : '$entity', domain : '$domain' }");      
   }
}

BEGIN {
   &Apache::lc_connection_handle::register('url_to_entity',undef,undef,undef,\&local_url_to_entity,'full_url');
   &Apache::lc_connection_handle::register('make_new_url',undef,undef,undef,\&local_make_new_url,'full_url');
   &Apache::lc_connection_handle::register('subscribe',undef,undef,undef,\&local_subscribe,'entity','domain','host');
   &Apache::lc_connection_handle::register('unsubscribe',undef,undef,undef,\&local_unsubscribe,'entity','domain','host');
   &Apache::lc_connection_handle::register('subscriptions',undef,undef,undef,\&local_json_subscriptions,'entity','domain');
   &Apache::lc_connection_handle::register('fetch_update',undef,undef,undef,\&local_fetch_update,'entity','domain');
}
1;
__END__
