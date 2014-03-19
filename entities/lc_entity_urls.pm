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
# Versioning metadata
# --- update (increment) the version
#
sub local_new_version {
   my ($entity,$domain)=@_;
   my $current_metadata=&Apache::lc_mongodb::dump_metadata($entity,$domain);
   my $new_version=$current_metadata->{'current_version'}+1;
   &Apache::lc_mongodb::update_metadata($entity,$domain,{ 'current_version' => $new_version,
                                          'versions' => { $new_version => &Apache::lc_date_utils::now2str() }});
} 

# --- set the initial version, which is 1
#
sub local_initial_version {
   my ($entity,$domain)=@_;
   &Apache::lc_mongodb::insert_metadata($entity,$domain,{ current_version => 1,
                                                          versions => { 1 => &Apache::lc_date_utils::now2str() } });
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
# This transfers a file from wrk into res
# ======================================================
# Unpublished assets sit under the given filepath in the wrk-directory
# Published assets have one or more virtual URLs
#
sub local_publish {
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
      &local_new_version($entity,$domain);
      &Apache::lc_memcached::insert_current_version($entity,$domain,$new_version);
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
      &local_initial_version($entity,$domain);
      &Apache::lc_memcached::insert_current_version($entity,$domain,1);
   }
   return 1;
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
   if ($version_type eq '-') {
# Current version
      return $base.'_'.&current_version($entity,$domain);
   } elsif ($version_type eq 'n') {
# Absolute version number
      return $base.'_'.$version_arg;
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
}
1;
__END__
