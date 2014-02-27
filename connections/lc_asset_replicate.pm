# The LearningOnline Network with CAPA - LON-CAPA
#
# Everything having to do with replicating assets between servers
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
package Apache::lc_replicate;

use strict;
use Apache2::RequestRec();
use Apache2::RequestIO();
use File::Copy;
use File::stat;
use Apache2::Const qw(:common :http);

use Apache::lc_parameters;
use Apache::lc_logs;

# ================================================================
# Translate from domain/entity/version to filepath
# ================================================================
# ==== Make four layer deep substructure to avoid huge directories
# /unpub/-/: currently unpublished version
# /version/N/: published version N for sure
# /-/-/: latest published version
# /as-of/date/: version as-of date

sub entity_to_filepath {
   my ($domain,$entity,$version_type,$version_arg)=@_;
   $entity=~/^(\w)(\w)(\w)(\w)/;
   my $version='';
   if ($version_type eq 'unpub') { $version='_unpub'; }
   if ($version_type eq 'version') { $version='_'.$version_arg; }
   return FILEROOT.$domain.'/'.$1.'/'.$2.'/'.$3.'/'.$4.'/'.$entity.$version;
}

# ================================================================
# Move and copy assets
# ================================================================
# ==== Copy an asset entity (edited/unpublished version) from another server
# usually after right editing it.
#
sub copyasset {
   my ($host,$domain,$entity,$version_type,$version_arg)=@_;
   return &Apache::cw_core_cluster::copyurl($host,'/local_asset_entity/'.$version_type.'/'.$version_arg.'/'.$domain.'/'.$entity,
                                                  &entity_to_filepath($domain,$entity,$version_type,$version_arg));
}

# ==== Subscribe to an asset on $host so this machine will get updates
#
sub subscribe {
   my ($domain,$entity)=@_;
   my $host=&Apache::cw_core_cluster::homeserver('asset','entity',$domain,$entity);
# Safety: this should never happen on homeserver
   if ($host eq $Apache::cw_core_cluster::thishost) {
      &logthis("Cannot subscribe to homeserver [$domain] [$entity]");
      return HTTP_BAD_REQUEST;
   }
   return &Apache::cw_core_cluster::dispatch($host,'POST','/core/data/asset/entity/'.$domain.'/'.$entity.'/subscriptions',
                                                          '{ "'.$Apache::cw_core_cluster::thishost.'" : "'.
                                                                &Apache::cw_core_utils::now2str().'" }');
}

# ==== Unsubscribe from an asset on $host, no longer get updates
# And: ensure that local copy is gone
#
sub unsubscribe {
   my ($domain,$entity)=@_;
   my $host=&Apache::cw_core_cluster::homeserver('asset','entity',$domain,$entity);
# Safety: this should never happen on homeserver
   if ($host eq $Apache::cw_core_cluster::thishost) {
      &logthis("Cannot unsubscribe from homeserver [$domain] [$entity]");
      return HTTP_BAD_REQUEST;
   }
# Old versions don't change, only need to delete current one
   unlink(&entity_to_filepath($domain,$entity,'-','-'));
   return &Apache::cw_core_cluster::dispatch($host,'DELETE','/core/data/asset/entity/'.$domain.'/'.$entity.'/subscriptions/'.
                                                   $Apache::cw_core_cluster::thishost);
}


# ==== Publish a resource
# Turn unpublished version into a new public version
#
sub publish {
   my ($domain,$entity,$data)=@_;
   my $host=&Apache::cw_core_cluster::homeserver('asset','entity',$domain,$entity);
   if ($host) {
# If this is the homeserver, go ahead locally
      if ($host eq $Apache::cw_core_cluster::thishost) {
# Is on this server, so initiatiate publication
# First get current version
         my $currentversion=&Apache::cw_core_entity::local_get_asset_version($domain,$entity);
         my $newversion;
# Might not even be published yet
         if ($currentversion) {
# Is published
            $newversion=$currentversion+1;
            &copy(&entity_to_filepath($domain,$entity,'-','-'),
                  &entity_to_filepath($domain,$entity,'version',$currentversion));
         } else {
# First publication
            $newversion=1;
         }
# Copy the unpublished version to the current version
         &copy(&entity_to_filepath($domain,$entity,'unpub','-'),
               &entity_to_filepath($domain,$entity,'-','-'));
# Store away the new version
         &Apache::cw_core_entity::local_store_asset_version($domain,$entity,$newversion);
# Notify all subscribers
         my $subscribers=&Apache::cw_core_data::local_retrieve_data('asset','entity/'.$domain.'/'.$entity.'/subscriptions');
         if (ref($subscribers)) {
# Only relevant if indeed anybody subscribed
            delete($subscribers->{'___COMMITS'});
            foreach my $host (keys(%$subscribers)) {
               if ($subscribers->{$host}) {
                  &Apache::cw_core_buffer::buffer_sub_update($host,$domain,$entity);
               }
            }
         }
      } else {
# Not on this server, hand off to homeserver
        $status=&Apache::cw_core_cluster::dispatch($host,'POST','/core/asset/publish/entity/'.$domain.'/'.$entity,
                                                                &Apache::cw_core_utils::perl_to_json($data));
      }
   } else {
      &logthis("Could not find homeserver while trying to publish [$domain] [$entity]");
      $status=HTTP_NOT_FOUND;
   }
}


# ==== Replicate a resource from its homeserver and subscribe
# Called by trans handler if file is not locally present
#
sub replicate {
   my ($domain,$entity,$version_type,$version_arg)=@_;
# Find homeserver
   my $host=&Apache::cw_core_cluster::homeserver('asset','entity',$domain,$entity);
   if ($host) {
# First see if we can subscribe
      my ($code,$result)=&subscribe($domain,$entity);
      unless ($code eq HTTP_OK) {
         &logthis("Could not subscribe to [$domain] [$entity] on host [$host], code: [$code]");
         return HTTP_NOT_FOUND;
      }
   } else {
      &logthis("Could not find homeserver while trying to subscribe to [$domain] [$entity]");
      return HTTP_NOT_FOUND;
   } 
# Only if subscription succeeded, copy
   return &copyasset($host,$domain,$entity,$version_type,$version_arg);
}

# ==== Fetch temporary file
# Transfer a recently edited/uploaded file from temporary space to
# where it should be as an asset
#
sub fetch_tmpfile {
   my ($domain,$entity,$path)=@_;
# Where should this be?
   my $targetpath=&entity_to_filepath($domain,$entity,'unpub','-');
# Make sure that place exists
   &Apache::cw_core_utils::ensuresubdir($targetpath);
# Now attempt to copy over
   unless (&copy('/home/cw/tmp/transfer/'.$path,$targetpath)) {
      $status=HTTP_NOT_FOUND;
      &logthis("Unable to copy ".$path." to ".$targetpath);
      return;
   }
# If this is not the homeserver, get the homeserver to fetch it after we are done here
# Make the other server get it from us (using fetch_from_server mechanism)
   unless (&Apache::cw_core_cluster::islocal('asset','entity',$domain,$entity)) {
      &Apache::cw_core_buffer::buffer_update_asset_notifications($domain,$entity);
   }
}

# ==== Copy unpublished asset from another server
#
sub fetch_from_server {
   my ($domain,$entity,$host)=@_;
# Attempt to copy it over
   my $code=&copyasset($host,$domain,$entity,'unpub','-');
   if ($code ne HTTP_OK) {
      $status=HTTP_SERVICE_UNAVAILABLE;
      &logthis('Unable to fetch ['.$domain.'] ['.$entity.'] from ['.$host.'], code: '.$code);
      return;
   }
}

# ==== Copy current version from another server
# We are subscribed to it.
#
sub update_from_server {
   my ($domain,$entity,$host)=@_;
# First check if we still want this
   my $filepath=&entity_to_filepath($domain,$entity,'-','-');
   my $lastaccess=0;
# Actually, this file should always exist, since we are
# subscribed. But just checking to make sure.
   if (-e $filepath) {
      my $sb=stat($filepath);
      $lastaccess=$sb->atime;
   }
# Unsubscribe after a day of not being used
   if (time-$lastaccess>86400) {
# Looks like nobody cares
# Unsubscribe
      my ($code,$response)=&unsubscribe($domain,$entity);
      if ($code ne HTTP_OK) {
         $status=HTTP_SERVICE_UNAVAILABLE;
         &logthis('Unable to unsubscribe ['.$domain.'] ['.$entity.'] from ['.$host.'], code: '.$code);
         return;
      }
   } else {
# Attempt to copy it over
      my $code=&copyasset($host,$domain,$entity,'-','-');
      if ($code ne HTTP_OK) {
         $status=HTTP_SERVICE_UNAVAILABLE;
         &logthis('Unable to update ['.$domain.'] ['.$entity.'] from ['.$host.'], code: '.$code);
         return;
      }
   }
}

# ================================================================
# Method Handlers
# ================================================================
# ==== PUT handler
# Makes a new entity
sub put_handler {
   my ($r,$realm,@uri_parts)=@_;
}

# ==== POST handler
#
sub post_handler {
    my ($r,$realm,@uri_parts)=@_;
    my $data=&Apache::cw_core_data::extract_content($r);
# First translate into entity form if coming in as uri
    my $entity;
    if ($uri_parts[0] eq 'uri') {
       $entity=&Apache::cw_core_entity::uri_to_entity('asset',$uri_parts[1],$uri_parts[2]);
    } elsif ($uri_parts[0] eq 'entity') {
       $entity=$uri_parts[2];
    }
    unless ($entity) {
       $status=HTTP_SERVICE_UNAVAILABLE;
       &logthis('Could not find entity for ['.$uri_parts[0].'] ['.$uri_parts[1].'] ['.$uri_parts[2].']');
       return;
    }
# Seems like we have a real asset and are in business
# First deal with situation where an unpublished asset
# needs to be transfered around, either locally or between
# servers
    if ($realm eq 'fetch') {
       if ($data->{'tmpfile'}) {
# Move into place locally from tmp/transfer
          &fetch_tmpfile($uri_parts[1],$entity,$data->{'tmpfile'});
          if ($status) { return; }
       } elsif ($data->{'host'}) {
# Get unpublished version from another server
          &fetch_from_server($uri_parts[1],$entity,$data->{'host'});
          if ($status) { return; }
       } 
# Now deal with publication, moving an unpublished
# asset into a new published version
    } elsif ($realm eq 'publish') {
# Turn an unpublished asset into a new published version
       &publish($uri_parts[1],$entity,$data);
       if ($status) { return; }
    } elsif ($realm eq 'update') {
# We are apparently subscribed to this resource and might want it
       &update_from_server($uri_parts[1],$entity,$data->{'host'});
       if ($status) { return; }
    }
}

# ==== GET hander
#
sub get_handler {
   my ($r,$realm,@uri_parts)=@_;
   if ($realm eq 'resid') {
      $r->print(&Apache::cw_core_utils::perl_to_json(&Apache::cw_core_entity::resid_to_asset(@uri_parts)));
      return;
   }
}

# ==== Processor
# Called every time that /core/asset or /core/localasset is invoked
#
sub process {
# Get request object
   my ($r,$method,$realm,@uri_parts)=@_;
# The world is still okay
   $status=0;
# Call handlers for different methods
   if ($method eq 'PUT') {
      &put_handler($r,$realm,@uri_parts);
   } elsif ($method eq 'POST') {
      &post_handler($r,$realm,@uri_parts);
   } elsif ($method eq 'GET') {
      &get_handler($r,$realm,@uri_parts);
   }
   return $status;
}

1;
__END__
