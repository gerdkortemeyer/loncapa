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
use Apache::lc_mongodb();
use Apache::lc_entity_utils();
use Apache::lc_connection_utils();
use Apache::lc_parameters;
use File::Copy;
use File::stat;


#
# Get the metadata for an asset
#
sub local_dump_metadata {
   return &Apache::lc_mongodb::dump_metadata(@_);
}

sub local_json_dump_metadata {
   return &Apache::lc_json_utils::perl_to_json(&local_dump_metadata(@_));
}

sub remote_dump_metadata {
   my ($host,$entity,$domain)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'dump_metadata',
                                            "{ entity : '$entity', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return &Apache::lc_json_utils::json_to_perl($response);
   } else {
      return undef;
   }
}

sub dump_metadata {
   my ($entity,$domain)=@_;
   my $metadata=&Apache::lc_memcached::lookup_metadata($entity,$domain);
   if ($metadata) { return $metadata; }
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      $metadata=&local_dump_metadata($entity,$domain);
   } else {
      $metadata=&remote_dump_metadata(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain);
   }
   if ($metadata) {
      &Apache::lc_memcached::insert_metadata($entity,$domain,$metadata);
   }
   return $metadata;
}


#
# Versioning metadata
# --- update (increment) the version
# Nothing more - returns the new version number
#
sub local_new_version {
   my ($entity,$domain)=@_;
   my $current_metadata=&Apache::lc_mongodb::dump_metadata($entity,$domain);
   my $new_version=$current_metadata->{'current_version'}+1;
   my $return=&Apache::lc_mongodb::update_metadata($entity,$domain,{ 'current_version' => $new_version,
                                          'versions' => { $new_version => &Apache::lc_date_utils::now2str() }});
   &Apache::lc_memcached::insert_current_version($entity,$domain,$new_version);
   &Apache::lc_memcached::insert_metadata($entity,$domain,&Apache::lc_mongodb::dump_metadata($entity,$domain));
   return $return;
} 


sub remote_new_version {
   my ($host,$entity,$domain)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'new_version',
                                            "{ entity : '$entity', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return $response;
   } else {
      return undef;
   }
}

# --- set the initial version, which is 1
# Nothing more ... just make the new version
#
sub local_initial_version {
   my ($entity,$domain)=@_;
   &Apache::lc_memcached::insert_current_version($entity,$domain,1);
   return &Apache::lc_mongodb::insert_metadata($entity,$domain,{ current_version => 1,
                                                          versions => { 1 => &Apache::lc_date_utils::now2str() } });
}

sub remote_initial_version {
   my ($host,$entity,$domain)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'initial_version',
                                            "{ entity : '$entity', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return $response;
   } else {
      return undef;
   }
}

#
# Handling current version requests
# --- retrieve the actual current version
# This is also what's called externally
#
sub local_current_version {
   my ($entity,$domain)=@_;
   my $current_metadata=&Apache::lc_mongodb::dump_metadata($entity,$domain);
   return $current_metadata->{'current_version'};
}

sub remote_current_version {
   my ($host,$entity,$domain)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'current_version',
                                            "{ entity : '$entity', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return $response;
   } else {
      return undef;
   }
}

sub current_version {
   my ($entity,$domain)=@_;
   my $version=&Apache::lc_memcached::lookup_current_version($entity,$domain);
   if ($version) { return $version; }
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      $version=&local_current_version($entity,$domain);
   } else {
      $version=&remote_current_version(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain);
   }
   if ($version) {
      &Apache::lc_memcached::insert_current_version($entity,$domain,$version);
   }
   return $version;     
}

# =======================================================
# Taking apart a URL of type /asset/... or /raw/ ...
# Both point the same resource, but "raw" leaves it
# unrendered for copying
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
# Directory listing
# ======================================================
#
sub local_dir_list {
   return &Apache::lc_postgresql::dir_list(@_);
}

sub local_json_dir_list {
   return &Apache::lc_json_utils::perl_to_json(&local_dir_list(@_));
}

sub remote_dir_list {
   my ($host,$path)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'dir_list',
       &Apache::lc_json_utils::perl_to_json({'path' => $path}));
   if ($code eq HTTP_OK) {
      return &Apache::lc_json_utils::json_to_perl($response);
   } else {
      return undef;
   }
}

sub dir_list {
   my ($path)=@_;
   my ($domain,$entity)=($path=~/^([^\/]+)\/([^\/]+)\//);
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_dir_list($path);
   } else {
      return &remote_dir_list(&Apache::lc_entity_utils::homeserver($entity,$domain),$path);
   }
}

# ======================================================
# This transfers a file from workspace into res
# ======================================================
# Unpublished uploaded assets sit under the given filepath
# in the wrk-directory
# /wrk/givenpath
# Published assets have one or more virtual URLs
#
sub local_workspace_publish {
   my ($wrk_url)=@_;
# Can't publish what does not exist
   my $wrk_filename=&wrk_to_filepath($wrk_url);
   unless (-e $wrk_filename) {
      &logwarning("Attempting to publish ($wrk_url), but associated file does not exist");
      return 0;
   }
# Construct the asset-URL for this
   my $full_url=$wrk_url;
   $full_url=~s/^\/wrk\//\/asset\/\-\/\-\//;
   &lognotice("Initiated publication of ($wrk_url) to ($full_url)");
# First thing to find out: does this already exist?
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
   my $entity=&url_to_entity($full_url);
   if ($entity) {
# This already exists, must be a new version
      my $current_version=&local_current_version($entity,$domain);
      my $new_version=$current_version+1;
      &lognotice("Resource ($full_url) exists, making new version ($new_version)");
      my $dest_filename=&asset_resource_filename($entity,$domain,'n',$new_version);
      &copy($wrk_filename,$dest_filename);
# Update the metadata
      unless (&local_new_version($entity,$domain)) {
         &logwarning("Failed to generate local new verion metadata entity ($entity) domain ($domain)");
         return undef;
      }
   } else {
# This does not yet exist, first publication
      &lognotice("Resource ($full_url) does not yet exist");
      $entity=&local_make_new_url($full_url);
      unless ($entity) {
         &logwarning("Could not obtain URL entity for ($full_url)");
         return undef;
      }
      my $dest_filename=&asset_resource_filename($entity,$domain,'n',1);
      &lognotice("Destination filename is ($dest_filename)");
# Make sure we have the subdirectory
      &Apache::lc_file_utils::ensuresubdir($dest_filename);
# Okay, can copy over
      &copy($wrk_filename,$dest_filename);
# Make the first metadata entry
      unless (&local_initial_version($entity,$domain)) {
         &logwarning("Failed to generate local initial version of entity ($entity) domain ($domain)");
         return undef;
      }
   }
   return 1;
}

# =============================================================
# While working on an asset, the version is /(asset|raw)/wrk
#
# Fetches a /raw/wrk-file from another server as a particular version number
# or wrk-version
#
sub local_fetch_wrk_file {
   my ($orig_host,$entity,$domain,$version)=@_;
# Default: numbered after publication
   my $version_type='n';
   my $version_arg=$version;
# ... or wrk-version if not published
   if ($version eq 'wrk') {
      $version_type='wrk';
      $version_arg='-';
   }
   if (&Apache::lc_dispatcher::copy_file($orig_host,'/raw/wrk/-/'.$domain.'/'.$entity,
                                         &asset_resource_filename($entity,$domain,$version_type,$version_arg))) {
      return 1;
   }
   &logwarning("Failed to copy wrk-file entity ($entity) domain ($domain) from host ($orig_host) as version ($version)");
   return 0;
}

#
# Make another server fetch my /raw/wrk-file as a particular version number
# during publication
#
sub remote_fetch_wrk_file {
   my ($target_host,$entity,$domain,$version)=@_;
   my ($code,$reply)=&Apache::lc_dispatcher::command_dispatch($target_host,'fetch_wrk_file',
                              &Apache::lc_json_utils::perl_to_json({ orig_host => &Apache::lc_connection_utils::host_name(),
                                                                     entity => $entity, domain => $domain, version => $version }));
   unless ($code eq HTTP_OK) {
       &logwarning("Tried to copy entity ($entity) domain ($domain), got code ($code) from host ($target_host)");
       return undef;
   }
   unless ($reply) {
      &logwarning("Tried to copy entity ($entity) domain ($domain), failed on host ($target_host)");
      return undef;
    }
    return 1;
}

#
# Take a file out of local workspace and publish it through the homeserver
#
sub remote_workspace_publish {
   my ($host,$wrk_url)=@_;
# Does this file exist?
   my $wrk_filename=&wrk_to_filepath($wrk_url);
   unless (-e $wrk_filename) {
      &logwarning("Attempting to remote publish ($wrk_url), but associated file does not exist");
      return 0;
   }
# Construct the asset-URL for this
   my $full_url=$wrk_url;
   $full_url=~s/^\/wrk\//\/asset\/\-\/\-\//;
   &lognotice("Initiated remote publication of ($wrk_url) to ($full_url)");
# First thing to find out: does this already exist?
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
   my $entity=&url_to_entity($full_url);
   if ($entity) {
# This already exists, must be a new version
      my $current_version=&current_version($entity,$domain);
      my $new_version=$current_version+1;
      &lognotice("Resource ($full_url) exists, making new version ($new_version)");
# This needs to become the wrk-version
      my $dest_filename=&asset_resource_filename($entity,$domain,'wrk','-');
# Make sure we have the subdirectory locally
      &Apache::lc_file_utils::ensuresubdir($dest_filename);
# Move it into position locally
      &copy($wrk_filename,$dest_filename);
# Copy it over to the homeserver
      unless (&remote_fetch_wrk_file($host,$entity,$domain,$new_version)) {
         &logwarning("Failed to turn local wrk file entity ($entity) domain ($domain) into version ($new_version) on host ($host)"); 
         return undef; 
      }
# Update the metadata remotely
      unless (&remote_new_version($host,$entity,$domain)) {
         &logwarning("Failed to remote generate new version of entity ($entity) domain ($domain) on host ($host)");
         return undef;
      }
# Locally we would like to see this immediately, so we don't confuse the user
      &Apache::lc_memcached::insert_current_version($entity,$domain,$new_version);
      &Apache::lc_memcached::insert_metadata($entity,$domain,&remote_dump_metadata($host,$entity,$domain));
   } else {
# This does not yet exist, first publication
     &lognotice("Resource ($full_url) does not yet exist");
     $entity=&remote_make_new_url($host,$full_url);
     unless ($entity) {
        &logwarning("Could remotely not obtain URL entity for ($full_url) from host ($host)");
        return undef;
     }
# Where does the wrk-version sit?
     my $dest_filename=&asset_resource_filename($entity,$domain,'wrk','-');
     &lognotice("Intermediate filename is ($dest_filename)");
# Make sure we have the subdirectory locally
     &Apache::lc_file_utils::ensuresubdir($dest_filename);
# Okay, can copy over locally
     &copy($wrk_filename,$dest_filename);
# Copy over to homeserver
     unless (&remote_fetch_wrk_file($host,$entity,$domain,1)) {
        &logwarning("Remote server ($host) failed to fetch work copy of entity ($entity) domain ($domain)"); 
        return undef; 
     }
# Remotely make the first metadata entry
     unless (&remote_initial_version($host,$entity,$domain)) {
        &logwarning("Failed to remote generate initial version of entity ($entity) domain ($domain) on host ($host)");
        return undef;
     }
# Update locally immediately
     &Apache::lc_memcached::insert_current_version($entity,$domain,1);
   }
   return 1;
}

#
# Routine to call to publish a file from out of workspace
# /wrl/filepath
#
sub workspace_publish {
   my ($wrk_url)=@_;
# Get author and domain to see if we are in charge here
   my ($domain,$author_entity)=($wrk_url=~/^\/wrk\/([^\/]+)\/([^\/]+)\//);
   my $return;
# It's our job if this is the author's homeserver
   if (&Apache::lc_entity_utils::we_are_homeserver($author_entity,$domain)) {
      $return=&local_workspace_publish($wrk_url);
   } else {
# No, this is another server's business
      $return=&remote_workspace_publish(&Apache::lc_entity_utils::homeserver($author_entity,$domain),$wrk_url);
   }
# Are we done?
   if ($return) {
# Get rid of /wrk-copy, we are done with it
      unless (unlink(&wrk_to_filepath($wrk_url))) {
         &logerror("Could not remove local workspace copy of ($wrk_url)");
         return undef;
      }
      return 1;
   } else {
      return undef;
   }
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
# /(asset|raw)/wrk -versions
# This is the normal way to deal with unpublished
# resources, they are the version "wrk"
# ======================================================
#
# Locally publish this
#
sub local_publish {
   my ($full_url)=@_;
}

# Call on other host to publish this
# It's already there due to previous "safe"
#
sub remote_publish {
   my ($host,$full_url)=@_;
}


# Publish an asset
# This publishes an /asset/wrk through its homeserver
#
sub publish {
   my ($full_url)=@_;
   unless (&save($full_url)) {
      &logerror("Could not publish ($full_url)");
      return 0;
   }
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
   if (&Apache::lc_entity_utils::we_are_homeserver($author,$domain)) {
      return &local_publish($full_url);
   } else {
      return &remote_publish(&Apache::lc_entity_utils::homeserver($author,$domain),$full_url);
   }
}

# Save an asset
# Should be called after every saving of an /asset/wrk
# to current file system, this also save it to its homeserver
#
sub save {
   my ($full_url)=@_;
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
   if (&Apache::lc_entity_utils::we_are_homeserver($author,$domain)) {
# There's nothing to do, all set
      return 1;
   } else {
      my $entity=&url_to_entity($full_url);
      unless ($entity) {
# Wow, this should not happen. We cannot save unassigned URLs!
         &logerror("Trying to save ($full_url), but no entity assigned yet!");
         return 0;
      }
# Make the homeserver copy it over
      return &remote_fetch_wrk_file(&Apache::lc_entity_utils::homeserver($author,$domain),$entity,$domain,'wrk');   
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

sub asset_resource_filename {
   my ($entity,$domain,$version_type,$version_arg)=@_;
   $entity=~/(\w)(\w)(\w)(\w)/;
   my $base=&lc_res_dir().$domain.'/'.$1.'/'.$2.'/'.$3.'/'.$4.'/'.$entity;
   my $current_version=&current_version($entity,$domain);
   if ($version_type eq '-') {
# Current version
      return $base.'_'.$current_version;
   } elsif ($version_type eq 'n') {
# Absolute version number
      my $version_num=int($version_arg);
      if ($version_num<=0) { $version_num=1; }
      return $base.'_'.$version_num;
   } elsif ($version_type eq 'as_of') {
# Want the resource as of a certain date
      my $version_date=&Apache::lc_date_utils::str2num($version_arg);
      unless ($version_date) {
         &lognotice("Wrong date format for versioned asset ($version_arg)");
         return $base.'_'.$current_version;
      }
# Do we have it cached?
      my $clean_date_string=&Apache::lc_date_utils::num2str($version_date);
      my $version_num=&Apache::lc_memcached::lookup_as_of_version($entity,$domain,$clean_date_string);
      if ($version_num) { return $base.'_'.$version_num; }
      my $metadata=&dump_metadata($entity,$domain);
# If it did not exist yet by the given date, use first existing version
      $version_num=1;
# Move forward
      for (my $i=1; $i<=$current_version; $i++) {
          my $pub_date=&Apache::lc_date_utils::str2num($metadata->{'versions'}->{$i});
          if ($pub_date<=$version_date) {
             $version_num=$i;
          }
      }
      &Apache::lc_memcached::insert_as_of_version($entity,$domain,$clean_date_string,$version_num);
      return $base.'_'.$version_num;
   } elsif ($version_type eq 'wrk') {
# Currently worked-on version in asset space
      return $base.'_wrk';
   }
# Huh?
   return undef;
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
   return &asset_resource_filename($entity,$domain,$version_type,$version_arg);
}

#
# Get the complete filepath for a raw resource
# /raw/versiontype/versionarg/domain/entity
#
sub raw_to_filepath {
   my ($raw_url)=@_;
   my ($version_type,$version_arg,$domain,$entity)=&split_url($raw_url);
   return &asset_resource_filename($entity,$domain,$version_type,$version_arg);
}

#
# Get the complete filepath for a workspace resource
# /wrk/domain/authorentity/path
# Workspace is where uploaded resources get unpacked, etc.
# It still retains an actual directory structure
#
sub wrk_to_filepath {
   my ($wrk_url)=@_;
   $wrk_url=~s/^\/wrk\///;
   return &lc_wrk_dir().$wrk_url;
}

# ======================================================
# Copy an asset
# ======================================================
#
sub copy_raw_asset {
   my ($entity,$domain,$version_type,$version_arg)=@_;
# Get the raw file
   if (&Apache::lc_dispatcher::copy_file(&Apache::lc_entity_utils::homeserver($entity,$domain),'/raw/'.$version_type.'/'.$version_arg.'/'.$domain.'/'.$entity,
                                         &asset_resource_filename($entity,$domain,$version_type,$version_arg))) {
      return 1;
   }
   &logwarning("Failed to copy raw asset entity ($entity) domain ($domain)");
   return 0;
}

#
# Copies a URL
#
sub replicate {
   my ($full_url)=@_;
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
   my $entity=&url_to_entity($full_url);
# Does that exist?
   unless ($entity) {
      &lognotice("No entity exists for ($full_url)");
      return 0;
   }
# Copy the unprocessed version
   if (&copy_raw_asset($entity,$domain,$version_type,$version_arg)) {
      return 1;
   }
   &logwarning("Failed to copy URL ($full_url) entity ($entity) domain ($domain)");
   return 0;
}

BEGIN {
   &Apache::lc_connection_handle::register('url_to_entity',undef,undef,undef,\&local_url_to_entity,'full_url');
   &Apache::lc_connection_handle::register('make_new_url',undef,undef,undef,\&local_make_new_url,'full_url');
   &Apache::lc_connection_handle::register('current_version',undef,undef,undef,\&local_current_version,'entity','domain');
   &Apache::lc_connection_handle::register('dump_metadata',undef,undef,undef,\&local_json_dump_metadata,'entity','domain');
   &Apache::lc_connection_handle::register('dir_list',undef,undef,undef,\&local_json_dir_list,'path');
   &Apache::lc_connection_handle::register('fetch_wrk_file',undef,undef,undef,\&local_fetch_wrk_file,'orig_host',
                                                                                                     'entity','domain','version');
   &Apache::lc_connection_handle::register('initial_version',undef,undef,undef,\&local_initial_version,'entity','domain');
   &Apache::lc_connection_handle::register('new_version',undef,undef,undef,\&local_new_version,'entity','domain');
}
1;
__END__
