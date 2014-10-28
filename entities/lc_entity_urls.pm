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
use Apache::lc_memcached();
use Apache::lc_entity_utils();
use Apache::lc_connection_utils();
use Apache::lc_parameters;
use Apache::lc_date_utils();
use File::Copy;
use File::stat;
use HTML::Entities;

use Data::Dumper;

# =========================================================================
# Get the metadata for an asset
# =========================================================================
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

# =======================================================================
# Version handling
# =======================================================================
#
# Versioning metadata
# Set initial version or increment the version
# Nothing more - returns the new version number
#
sub local_new_version {
   my ($entity,$domain)=@_;
   unless (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      &logwarning("Cannot locally update version of ($entity) ($domain), not homeserver");
      return undef;
   }
   my $current_metadata=&Apache::lc_mongodb::dump_metadata($entity,$domain);
   my $new_version;
   if ($current_metadata->{'current_version'}>0) {
# There already is an existing version
      $new_version=$current_metadata->{'current_version'}+1;
      unless (&Apache::lc_mongodb::update_metadata($entity,$domain,{ 'current_version' => $new_version,
                                          'versions' => { $new_version => &Apache::lc_date_utils::now2str() }})) {
         &logerror("Could not update metadata entry for ($entity) ($domain) to version ($new_version)");
         return undef;
      }
   } else {
      $new_version=1;
      unless (&Apache::lc_mongodb::update_metadata($entity,$domain,{ current_version => 1,
                                                          versions => { 1 => &Apache::lc_date_utils::now2str() } })) {
         &logerror("Could not generate first metadata entry for ($entity) ($domain)");
         return undef;
      }
   }
# Update the local memcache, since we know this now ...
   &Apache::lc_memcached::insert_current_version($entity,$domain,$new_version);
   &Apache::lc_memcached::insert_metadata($entity,$domain,&Apache::lc_mongodb::dump_metadata($entity,$domain));
   return $new_version;
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
# Evaluating an URL
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


#
# Returns a raw "directory" listing
# domain/authorentity/path
# Array of arrays: [[url,entity],[url,entity]]
#
sub dir_list {
   my ($path)=@_;
   my ($domain,$entity)=($path=~/^([^\/]+)\/([^\/]+)\//);
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_dir_list($path);
   } else {
      return &remote_dir_list(&Apache::lc_entity_utils::homeserver($entity,$domain),$path);
   }
}

#
# Returns a full "directory" listing
# domain/authorentity/path
# including metadata
#
sub full_dir_list {
   my ($path)=@_;
   my $dir_list=&dir_list($path);
   my $full_list;
   foreach my $file (@{$dir_list}) {
      my $url=$file->[0];
      my $url_part=$url;
      $url_part=~s/^\Q$path\E//;
# This gets everything underneath the path,
# but (for now), only take stuff at this level
      unless (($url_part=~/\/[^\/]/) || ($url_part eq '')) {
         my $entity=$file->[1];
         my ($domain)=($url=~/^\/?([^\/]+)\//);
         my $metadata=&dump_metadata($entity,$domain);
         my $type='file';
         if ($url_part=~/\/$/) {
            $url_part=~s/\/+$//;
            $type='directory';
         }
         push(@{$full_list},{ type => $type, url => $url, filename => $url_part, entity => $entity, domain => $domain, metadata => $metadata });
      }
   }
   return $full_list;
}

# =============================================================
# Moving an uploaded asset from wrk-space over to asset space
# =============================================================
# At this point, the uploaded asset already needs to have an
# assigned $entity, i.e., we need to know where this is going
#
sub transfer_uploaded {
   my ($full_url)=@_;
   my $entity=&url_to_entity($full_url);
   unless ($entity) {
      &logwarning("Cannot transfer uploaded version of ($full_url), no entity");
      return undef;
   }
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
   my $wrk_filename=&wrk_to_filepath('/wrk/'.$url);
   unless (-e $wrk_filename) {
      &logwarning("Cannot transfer uploaded version of ($full_url), file ($wrk_filename) does not exist");
      return undef;
   }
   my $dest_filename=&asset_resource_filename($entity,$domain,'wrk','-');
   &Apache::lc_file_utils::ensuresubdir($dest_filename);
   unless (&move($wrk_filename,$dest_filename)) {
      &logerror("Failed to move ($wrk_filename) to ($dest_filename)");
      return undef;
   }
   unless (&save($full_url)) {
      &logerror("Unable to save uploaded file ($full_url) to homeserver");
      return undef;
   }
   return 1;
}

# =============================================================
# Get/Set the rights for a file
# =============================================================
#
sub modify_right {
   my ($entity,$domain,$type,$target_domain,$target_entity,$target_section,$value)=@_;
   unless (($type eq 'grade') ||
           ($type eq 'use') || 
           ($type eq 'view') || 
           ($type eq 'edit') ||
           ($type eq 'clone')) {
      return undef;
   }
   my $rights;
   if ($target_domain) {
      if ($target_entity) {
         if ($target_section) {
            $rights->{$type}->{'domain'}->{$target_domain}->{'entity'}->{$target_entity}->{'section'}->{$target_section}=$value;
         } else {
            $rights->{$type}->{'domain'}->{$target_domain}->{'entity'}->{$target_entity}->{'any'}=$value;
         }
      } else {
         $rights->{$type}->{'domain'}->{$target_domain}->{'any'}=$value;
      }
   } else {
      $rights->{$type}->{'any'}=$value;
   }
   return &set_rights($entity,$domain,$rights);
}

sub get_rights {
   my ($entity,$domain)=@_;
   my $metadata=&dump_metadata($entity,$domain);
   return $metadata->{'rights'};
}

sub set_rights {
   my ($entity,$domain,$rights)=@_;
   return &store_metadata($entity,$domain,{ 'rights' => $rights });
}

#
# Find out if we have standard rules, or if it is customized
#

sub standard_rights {
   my ($entity,$domain,$url)=@_;
   my $rights=&get_rights($entity,$domain);
   my ($rversion_type,$rversion_arg,$rdomain,$rauthor,$rpath)=&split_url('/asset/-/-/'.$url);
   my $std={};
   my $overall='none';
   foreach my $type ('grade','use','view','edit','clone') {
      $std->{$type}='none';
      if ($rights->{$type}->{'any'}) {
         $std->{$type}='systemwide';
         $overall='standard';
      } else {
         foreach my $tdomain (keys(%{$rights->{$type}->{'domain'}})) {
            if ($rights->{$type}->{'domain'}->{$tdomain}->{'any'}) {
               if ($tdomain eq $rdomain) {
                  if ($std->{$type} eq 'none') {
                     $std->{$type}='domainwide';
                     $overall='standard';
                  } else {
                     $std->{$type}='custom';
                  }
               } else {
                  $std->{$type}='custom';
               }
            }
            foreach my $tentity (keys(%{$rights->{$type}->{'domain'}->{$tdomain}->{'entity'}})) {
               if ($rights->{$type}->{'domain'}->{$tdomain}->{'entity'}->{$tentity}) {
                  if ($std->{$type} eq 'none') {
                     if ($type eq 'grade') {
                        $std->{$type}='course';
                        $overall='standard';
                     } else {
                        $std->{$type}='custom';
                     }
                  } else {
                     $std->{$type}='custom';
                  }
               }
            }
         }
      }
      if ($std->{$type} eq 'custom') {
         $overall='custom';
      }
   }
   return ($overall,$std);
}

# =============================================================
# Get some raw metadata, only on homeserver where file is
# =============================================================
#
sub local_store_file_vitals {
   my ($entity,$domain,$version,$version_arg)=@_;
   my $filename=&asset_resource_filename($entity,$domain,$version,$version_arg);
   if (-e $filename) {
      my $sb=stat($filename);
      if ($version eq 'wrk') { $version_arg='wrk'; }
      return &local_store_metadata($entity,$domain,
                                        { 'filedata' => { 
                                              $version_arg => {
                                                 'size' => $sb->size,
                                                 'modified' => &Apache::lc_date_utils::num2str($sb->mtime)
                                                              }
                                                        }
                                        });
   }
   return undef;
}

# =============================================================
# Store metadata flags
# =============================================================
#
# Called with the entity, the domain, and the new metadata as hash pointer
# Takes optional array references of keys that should be completely flushed
# - if those keys are not in the new metadata, they will be gone
# Returns full updated metadata as hash pointer
#
sub local_store_metadata {
   my ($entity,$domain,$newmetadata,$refreshkeys)=@_;
# Do we already have metadata? If not, do it now
   my $oldmetadata=&local_dump_metadata($entity,$domain);
   unless ($oldmetadata) {
      &lognotice("Started metadata record for [$entity] [$domain]");
      unless (&Apache::lc_mongodb::insert_metadata($entity,$domain,{ 'generated' => &Apache::lc_date_utils::now2str() })) {
         &logwarning("Could not generate metadata record for [$entity] [$domain]");
      }
   }
# Any keys that should be completely flushed/deleted?
   if ($refreshkeys) {
      unless (&Apache::lc_mongodb::delete_metadata_keys($entity,$domain,$refreshkeys)) {
         &logerror("Could not flush keys from metadata [$entity] [$domain]");
         return undef;
      }
   }
# Attempt to update the metadata
   if ($newmetadata) {
      unless (&Apache::lc_mongodb::update_metadata($entity,$domain,$newmetadata)) {
         &logerror("Could not store metadata [$entity] [$domain]");
         return undef;
      }
   }
# Now see if it updated correctly, and to what
   my $updatedmetadata=&local_dump_metadata($entity,$domain);
   unless ($updatedmetadata) {
      &logerror("Updating of metadata failed for [$entity] [$domain]");
      return undef;
   }
# Might as well remember locally
   &Apache::lc_memcached::insert_metadata($entity,$domain,$updatedmetadata);
   return $updatedmetadata;
}

#
# Called with the entity, the domain, and the new metadata in JSON
# Returns full updated metadata in JSON
#
sub local_json_store_metadata {
   my ($entity,$domain,$newmetajson,$refreshkeys)=@_;
   return &Apache::lc_json_utils::perl_to_json(
       &local_store_metadata($entity,$domain,&Apache::lc_json_utils::json_to_perl($newmetajson),
                                             &Apache::lc_json_utils::json_to_perl($refreshkeys))
                                              );
}

#
# The remote call for storing metadata
#
sub remote_store_metadata {
   my ($host,$entity,$domain,$newmetadata,$refreshkeys)=@_;
   unless ($host) {
      &logwarning("Cannot store metadata, no homewserver for [$entity] [$domain]");
      return undef;
   }
# Put refreshkeys into JSON
   unless ($refreshkeys) { $refreshkeys=[]; }
   my $refresh_json=&Apache::lc_json_utils::perl_to_json($newmetadata);
# Put the new metadata into JSON
   unless ($newmetadata) { $newmetadata={}; }
   my $fields_json=&Apache::lc_json_utils::perl_to_json($newmetadata);
   unless ($fields_json) {
      &logerror("Could not store metadata for [$entity] [$domain], no valid hash given");
      return undef;
   }
# Send the JSON inside JSON
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'store_metadata',
                              &Apache::lc_json_utils::perl_to_json({ entity => $entity,
                                                                     domain => $domain,
                                                                     fields_json => $fields_json,
                                                                     refresh_json => $refresh_json
                                                                      }));
# If okay, cache and return
   if ($code eq HTTP_OK) {
      my $updatedmetadata=&Apache::lc_json_utils::json_to_perl($response);
      if ($updatedmetadata) {
         &Apache::lc_memcached::insert_metadata($entity,$domain,$updatedmetadata);
         return $updatedmetadata;
      } else {
         return undef;
      }
   } else {
      return undef;
   }
}

sub store_metadata {
   my ($entity,$domain,$newmetadata,$refreshkeys)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_store_metadata($entity,$domain,$newmetadata,$refreshkeys);
   } else {
      return &remote_store_metadata(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain,$newmetadata,$refreshkeys);
   }
}

# =============================================================
# Setting flags, etc, etc. Call these.
# =============================================================
# Encode URL for use as Mongo key
#
sub url_encode {
   my ($url)=@_;
   $url=&encode_entities($url,'\W');
   $url=&encode_entities($url,'_');
   $url=~s/\W/\_/gs;
   return $url;
}

sub store_url_metadata {
   my ($full_url,$data)=@_;
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
   my $entity=&url_to_entity($full_url);
   unless ($entity) {
      &logwarning("Trying to modify URL metadata for [$url], does not exist.");
   }
   return &store_metadata($entity,$domain,{ 'urldata' => { &url_encode($url) => $data } });
}

sub make_obsolete {
   my ($full_url)=@_;
   return &store_url_metadata($full_url,{ 'obsolete' => 1 }); 
}

sub un_obsolete {
   my ($full_url)=@_;
   return &store_url_metadata($full_url,{ 'obsolete' => 0 });
}

# =============================================================
# Change title
# =============================================================
#
sub store_new_title {
   my ($entity,$domain,$newtitle)=@_;
   return &store_metadata($entity,$domain,{ 'title' => $newtitle });
}

# =============================================================
# Moving unpublished assets between servers
# =============================================================
# While working on an asset, the version is /(asset|raw)/wrk
#
# Fetches a /raw/wrk-file from another server
# Shuffling around unpublished assets between servers
#
sub local_fetch_wrk_file {
   my ($orig_host,$entity,$domain)=@_;
   if (&Apache::lc_dispatcher::copy_file($orig_host,'/raw/wrk/-/'.$domain.'/'.$entity,
                                         &asset_resource_filename($entity,$domain,'wrk','-'))) {
      &local_store_file_vitals($entity,$domain,'wrk','-');
      return 1;
   }
   &logwarning("Failed to copy wrk-file entity ($entity) domain ($domain) from host ($orig_host)");
   return 0;
}

#
# Make another server fetch my /raw/wrk-file
# during publication
#
sub remote_fetch_wrk_file {
   my ($target_host,$entity,$domain)=@_;
   my ($code,$reply)=&Apache::lc_dispatcher::command_dispatch($target_host,'fetch_wrk_file',
                              &Apache::lc_json_utils::perl_to_json({ orig_host => &Apache::lc_connection_utils::host_name(),
                                                                     entity => $entity, domain => $domain }));
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

# ======================================================
# Make a new URL
# ======================================================
#
# Takes a full URL and generates an entity for it
# Happing on this server, which would need to be the
# homeserver for the author
#
sub local_make_new_url {
   my ($full_url)=@_;
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
# Are we even potentially in charge here?
   unless (&Apache::lc_entity_utils::we_are_homeserver($author,$domain)) {
      &logwarning("Tried to generate url ($url), but not homeserver of entity ($author) domain ($domain)");
      return undef;
   }
# First make sure this url does not exist
   if (&local_url_to_entity ($full_url)) {
# Oops, that url already exists locally!
      &logwarning("Tried to generate url ($url), but already exists locally");
      return undef;
   }
# Check all other library hosts, make sure they are responding
   my ($code,$reply)=&Apache::lc_dispatcher::query_all_domain_libraries($domain,"url_to_entity",
                        &Apache::lc_json_utils::perl_to_json({'full_url' => $full_url})
                                                                       );
# If we could not get a hold of all libraries, do not proceed. It may exist on that one!
   unless ($code eq HTTP_OK) {
      &logwarning("Tried to generate url ($url), but could not get replies from all library servers");
      return undef;
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

# Takes a full URL and generates an entity on the homeserver of the author
#
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

#
# This generates the entity for a new initial URL
# It returns the $entity for it
#
sub make_new_url {
   my ($full_url)=@_;
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
   if (&Apache::lc_entity_utils::we_are_homeserver($author,$domain)) {
      return &local_make_new_url($full_url);
   } else {
      return &remote_make_new_url(&Apache::lc_entity_utils::homeserver($author,$domain),$full_url);
   }
}

#
# Make a new subdirectory
#
sub make_new_subdir {
   my ($full_url)=@_;
   unless ($full_url=~/\/$/) { $full_url.='/'; }
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
   unless ($version_type eq 'wrk') { 
      &logwarning("Tried to make subdirectory [$full_url], but cannot be published");
      return undef; 
   }
   my ($entity,$domain)=&url_to_entity($full_url);
   if ($entity) {
      &logwarning("Tried to make subdirectory [$full_url], but already exists"); 
      return undef; 
   }
# We don't have it, so let's make it
   return &make_new_url($full_url);
}

# ======================================================
# /(asset|raw)/wrk -versions
# This is the normal way to deal with unpublished
# resources, they are the version "wrk"
# ======================================================
#
# Locally publish this
# return the new version
#
sub local_publish {
   my ($full_url)=@_;
   my $entity=&url_to_entity($full_url);
   unless ($entity) {
      &logerror("Cannot locally publish unassigned URL ($full_url)");
      return undef;
   }
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
   my $new_version=&local_new_version($entity,$domain);
   if ($new_version) {
# Sanity check - we should not have the version yet that we are about to make
      my $dest_filename=&asset_resource_filename($entity,$domain,'n',$new_version);
      if (-e $dest_filename) {
         &logerror("About to publish version ($new_version) or ($full_url) at ($dest_filename), but file already exists");
         return undef;
      }
      if (&move(&asset_resource_filename($entity,$domain,'wrk','-'),$dest_filename)) {
         &lognotice("Published version ($new_version) of ($full_url)");
         &local_store_file_vitals($entity,$domain,'n',$new_version); 
         return $new_version;
      } else {
# How could that fail?
         &logerror("Could not copy wrk-version of ($full_url) to version ($new_version)");
         return undef;
      } 
   } else {
      &logerror("Failed to obtain new version of ($full_url)");
      return undef;
   }
}

# Call on other host to publish this
# It's already there due to previous "safe"
#
sub remote_publish {
   my ($host,$full_url)=@_;
   my $entity=&url_to_entity($full_url);
   unless ($entity) {
      &logerror("Cannot remotely publish unassigned URL ($full_url)");
      return undef;
   }
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'publish',
                                      &Apache::lc_json_utils::perl_to_json({'full_url' => $full_url}));
   if ($code eq HTTP_OK) {
      if ($response) {
# The response is the new version, update local cache and return
         my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
         &Apache::lc_memcached::insert_current_version($entity,$domain,$response);
         &Apache::lc_memcached::insert_metadata($entity,$domain,&Apache::lc_mongodb::dump_metadata($entity,$domain));
         return $response;
      } else {
         &logerror("Failed to publish new version of ($full_url) on ($host)");
         return undef;
      }
   } else {
      return undef;
   }
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
   my $new_version;
   if (&Apache::lc_entity_utils::we_are_homeserver($author,$domain)) {
      $new_version=&local_publish($full_url);
   } else {
      $new_version=&remote_publish(&Apache::lc_entity_utils::homeserver($author,$domain),$full_url);
   }
   if ($new_version) {
      &lognotice("Successfully published version ($new_version) of ($full_url)");
#FIXME: remember that we are done with this
      return 1;
   } else {
      &logerror("Failed to publish ($full_url)");
      return undef;
   }
}

# Save an asset
# Should be called after every saving of an /asset/wrk
# to current file system, this also save it to its homeserver
#
sub save {
   my ($full_url)=@_;
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
   my $entity=&url_to_entity($full_url);
   unless ($entity) {
# Wow, this should not happen. We cannot save unassigned URLs!
      &logerror("Trying to save ($full_url), but no entity assigned yet!");
      return undef;
   }
   if (&Apache::lc_entity_utils::we_are_homeserver($author,$domain)) {
# Remember the file vitals
      &local_store_file_vitals($entity,$domain,$version_type,$version_arg);
# There's nothing more to do, all set
      return 1;
   } else {
      return &remote_fetch_wrk_file(&Apache::lc_entity_utils::homeserver($author,$domain),$entity,$domain,'wrk');   
   }
}

# Get a fresh version of the /asset/wrk-file from the
# homeserver
#
sub checkout {
   my ($full_url)=@_;
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
# We can only do this with the most recent version
   unless ($version_type eq '-') {
      &logerror("Cannot checkout anything but most recent of ($full_url)");
      return undef;
   }
   if (&Apache::lc_entity_utils::we_are_homeserver($author,$domain)) {
# Nothing to do, we are homeserver ourselves
      return 1;
   } else {
      my $entity=&url_to_entity($full_url);
      unless ($entity) {
# There's a problem here
         &logwarning("Cannot check out ($full_url), no entity defined");
         return undef;
      }
# Get it from the homeserver
      if (&local_fetch_wrk_file(&Apache::lc_entity_utils::homeserver($author,$domain),$entity,$domain)) {
# Great, we are done
#FIXME: remember that we did this in the environment
         return 1;
      } else {
# There was no work version, get the latest and make it a wrk-version
         return &checkout_published($full_url);
      }
   }
}

# Check out a specific published version of an asset
# to be the local wrk-file
#
sub checkout_published {
   my ($full_url)=@_;
   my ($version_type,$version_arg,$domain,$author,$url)=&split_url($full_url);
# We cannot do this with the wrk-file
   if ($version_type eq 'wrk') {
      &logerror("Cannot checkout ($full_url) as a published file");
      return undef;
   } 
   my $entity=&url_to_entity($full_url);
   unless ($entity) {
# Published assets would have an entity for sure
      &logerror("Cannot check out ($full_url) as published, no entity defined");
      return undef;
   }
   unless (&replicate($full_url)) {
# Failed to get the asset
      &logerror("Could not check out ($full_url), replication failed");
      return undef;
   }
# So far so good. Make it the new wrk-version
   if (&copy(&asset_resource_filename($entity,$domain,$version_type,$version_arg),
             &asset_resource_filename($entity,$domain,'wrk','-'))) {
#FIXME: remember that we did this
      return 1;
   } else {
# How could this fail?
      &logerror("Could not copy ($full_url) to wrk-copy");
      return undef;
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
   $wrk_url=~s/\/\//\//gs;
   return &lc_wrk_dir().$wrk_url;
}

# ======================================================
# Copy an asset
# ======================================================
# This is used to transfer and replicate assets
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
# Replicates a URL
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
   &Apache::lc_connection_handle::register('store_metadata',undef,undef,undef,\&local_json_store_metadata,'entity','domain','fields_json');
   &Apache::lc_connection_handle::register('dir_list',undef,undef,undef,\&local_json_dir_list,'path');
   &Apache::lc_connection_handle::register('fetch_wrk_file',undef,undef,undef,\&local_fetch_wrk_file,'orig_host','entity','domain');
   &Apache::lc_connection_handle::register('publish',undef,undef,undef,\&local_publish,'full_url');
}
1;
__END__
