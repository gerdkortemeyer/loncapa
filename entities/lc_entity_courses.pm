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
use Apache::lc_logs;
use Apache::lc_dispatcher();
use Apache::lc_connection_handle();
use Apache::lc_postgresql();
use Apache::lc_mongodb();
use Apache::lc_memcached();
use Apache::lc_parameters;
use Apache::lc_date_utils();
use Apache::lc_entity_roles();

use Data::Dumper;

use Apache2::Const qw(:common :http);

# ================================================================
# Make a new course
# ================================================================
#
# Make a new course on this machine
# This is also the routine that would be called by remote servers
# CourseID is the equivalent of the username, usually an institutional ID like "phy232fs15"
# Returns entity
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
# Start course profile
   &Apache::lc_mongodb::insert_profile($entity,$domain,{ created => &Apache::lc_date_utils::now2str() });
# Start empty table of contents
   &initialize_contents($entity,$domain);
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
# Call this
# CourseID is like a username, usually an institutional ID code, like phy232fs05
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
# Looking for courses
# ================================================================
#

sub local_query_course_profiles {
   my ($domain,$term)=@_;
   $term=~s/^\s+//s;
   $term=~s/\s+$//s;
   if (length($term)<2) { return undef; }
   my @rawdata=&Apache::lc_mongodb::query_course_profiles($domain,$term);
   my $data=undef;
   my $count=0;
   foreach my $course (@rawdata) {
      foreach my $namepart ('type','title','instid') {
         $data->{$course->{'domain'}}->{$course->{'entity'}}->{$namepart}=$course->{'profile'}->{$namepart};
      }
      $count++;
      if ($count>100) { last; }
   }
   return $data;
}

sub local_json_query_course_profiles {
   return &Apache::lc_json_utils::perl_to_json(&local_query_course_profiles(@_));
}

sub query_course_profiles {
   my ($domain,$term)=@_;
   my $connection_table=&Apache::lc_init_cluster_table::get_connection_table();
   foreach my $host (split(/\,/,$connection_table->{'libraries'}->{$domain})) {
      unless ($host) { next; }
      my $data=undef;
      if ($host eq $connection_table->{'self'}) {
         $data=&local_query_course_profiles($domain,$term);
      } else {
         my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'query_course_profiles',
                                &Apache::lc_json_utils::perl_to_json({ domain => $domain, term => $term }));
         if ($code eq HTTP_OK) {
            $data=&Apache::lc_json_utils::json_to_perl($response);
         }
      }
      if ($data) {
         foreach my $entity (keys(%{$data->{$domain}})) {
            &Apache::lc_mongodb::update_profiles_cache($entity,$domain,$data->{$domain}->{$entity});
         }
      }
   }
   return 1;
}

sub query_course_profiles_result {
   my ($domain,$term)=@_;
   $term=~s/^\s+//s;
   $term=~s/\s+$//s;
   my @rawdata=&Apache::lc_mongodb::query_course_profiles_cache($domain,$term);
   my $data=undef;
   my $count=0;
   foreach my $course (@rawdata) {
      foreach my $namepart ('type','title','instid') {
         $data->{'records'}->{$course->{'domain'}}->{$course->{'entity'}}->{$namepart}=$course->{'profile'}->{$namepart};
      }
      $count++;
      if ($count>100) { last; }
   }
   $data->{'count'}=$count;
   return $data;
}

# ================================================================
# Convert stuff to entities
# ================================================================
# ==== Courseids to entities
#
# Try only the local machine
# - this is the one that needs to be called remotely
# Given something like phy232fs05 and domain, will return entity
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

#
# Reverse
#

sub local_entity_to_course {
   my ($entity,$domain)=@_;
   my $courseid=&Apache::lc_memcached::lookup_entity_course($entity,$domain);
   if ($courseid) { return $courseid; }
   $courseid=&Apache::lc_postgresql::lookup_entity_course($entity,$domain);
   if ($courseid) {
      &Apache::lc_memcached::insert_course($courseid,$domain,$entity);
   }
   return $courseid;
}

sub remote_entity_to_course {
   my ($host,$entity,$domain)=@_;
   my ($code,$reply)=&Apache::lc_dispatcher::command_dispatch($host,"entity_to_course",
                                                              "{ entity : '$entity', domain : '$domain' }");
   if ($code eq HTTP_OK) {
      return $reply;
   } else {
      return undef;
   }
}

sub entity_to_course {
   my ($entity,$domain)=@_;
   my $courseid=&Apache::lc_memcached::lookup_entity_course($entity,$domain);
   if ($courseid) { return $courseid; }
   if (&Apache::lc_entity_utils::we_are_homeserver($entity,$domain)) {
      return &local_entity_to_course($entity,$domain);
   } else {
      $courseid=&remote_entity_to_course(&Apache::lc_entity_utils::homeserver($entity,$domain),$entity,$domain);
      if ($courseid) {
         &Apache::lc_memcached::insert_course($courseid,$domain,$entity);
      }
      return $courseid;
   }
}

# =================================================================
# Table of contents
# =================================================================
#

# ==== Return the URL for the table of contents of this course
# Needs course entity and domain

sub toc_path {
   my ($entity,$domain)=@_;
   return $domain.'/'.$entity.'/toc.json';
}

sub toc_url {
   return '/asset/-/-/'.&toc_path(@_);
}

sub toc_wrk_url {
  return '/asset/wrk/-/'.&toc_path(@_);
}

# ==== Load and return the table of contents
#
sub load_contents {
   my ($entity,$domain)=@_;
# See if we already have it cached
   my $toc=&Apache::lc_memcached::lookup_toc($entity,$domain);
   if ($toc) { return $toc; }
# Load it
   $toc=&Apache::lc_json_utils::json_to_perl(&Apache::lc_file_utils::readurl(&toc_url($entity,$domain)));
   if ($toc) {
# Cache and return it
      &Apache::lc_memcached::insert_toc($entity,$domain,$toc);
      return $toc;
   } else {
# Oops!
      &logwarning("Could not find table of contents for ($entity) ($domain)");
      return undef;
   }
}


# ==== Initialize new table of contents
#
sub initialize_contents {
   my ($entity,$domain)=@_;
   unless (&publish_contents($entity,$domain,[])) {
      &logerror("Unable to publish table of contents of course ($entity) domain ($domain)");
      return undef;
   }
   return 1;
}

# ==== Store the table of contents in $toc
# Store a wrk-copy, also back to homeserver
#
sub save_contents {
   my ($entity,$domain,$toc)=@_;
   if (&Apache::lc_file_utils::writeurl(&toc_wrk_url($entity,$domain),&Apache::lc_json_utils::perl_to_json($toc))) {
      return &Apache::lc_entity_urls::save(&toc_wrk_url($entity,$domain));
   } else {
      &logerror("Unable to save table of contents for course ($entity) domain ($domain)");
      return undef;
   }
}

#
# This is for real, actually publish and change

sub publish_contents {
   my ($entity,$domain,$toc)=@_;
   unless (&save_contents($entity,$domain,$toc)) {
      return undef;
   }
   if (&Apache::lc_entity_urls::publish(&toc_wrk_url($entity,$domain))) {
# Cache it, too, so it takes effect immediately in order to avoid confusion
      &Apache::lc_memcached::insert_toc($entity,$domain,$toc);
# No valid digest in this session
      &Apache::lc_memcached::insert_tocdigest(&Apache::lc_entity_sessions::user_entity_domain(),$entity,$domain,undef);
      return 1;
   } else {
      return undef;
   }
}

#
# Accessor functions for title, type, etc
#
# Title: e.g., "Introductory Physics II FS15"
# 
sub set_course_title {
   my ($entity,$domain,$title)=@_;
   return &Apache::lc_entity_profile::modify_profile($entity,$domain,{ title => $title });
}

sub course_title {
   my ($entity,$domain)=@_;
   my $profile=&Apache::lc_entity_profile::dump_profile($entity,$domain);
   return $profile->{'title'};
}

# Type: regular or community

sub set_course_type {
   my ($entity,$domain,$type)=@_;
   return &Apache::lc_entity_profile::modify_profile($entity,$domain,{ type => $type });
}

sub course_type {
   my ($entity,$domain)=@_;
   my $profile=&Apache::lc_entity_profile::dump_profile($entity,$domain);
   return $profile->{'type'};
}

#
# Get the information on active courses/communities in this session
#
sub active_session_courses {
# Get active roles from session environment
   my $roles=&Apache::lc_entity_sessions::roles();
# We will return an array of profiles
   my @courses=();
   if ($roles) {
      foreach my $domain (keys(%{$roles->{'course'}})) {
         foreach my $entity (keys(%{$roles->{'course'}->{$domain}})) {
            my $profile=&Apache::lc_entity_profile::dump_profile($entity,$domain);
            $profile->{'domain'}=$domain;
            $profile->{'entity'}=$entity;
            push(@courses,$profile);
         }
      }
   }
   return @courses;
}

#
# Update the "last accessed" record for the course
#
sub set_last_accessed {
   my ($entity,$domain)=@_;
   return &Apache::lc_entity_profile::modify_profile($entity,$domain,{ last_accessed => &Apache::lc_date_utils::now2str() });
}

sub last_accessed {
   my ($entity,$domain)=@_;
   my $profile=&Apache::lc_entity_profile::dump_profile($entity,$domain);
   return $profile->{'last_accessed'};
}

#
# Assemble a complete list of all users in a course/community
#
sub courselist {
   my ($entity,$domain)=@_;
   my $raw_classlist=&Apache::lc_entity_roles::lookup_entity_rolelist($entity,$domain);
   my @classlist=();
   foreach my $row (@{$raw_classlist}) {
      my ($roleentity,$roledomain,$rolesection,
          $userentity,$userdomain, 
          $role, 
          $startdate,$enddate,
          $manualenrollentity,$manualenrolldomain)=@{$row};
      my $userprofile=&Apache::lc_entity_profile::dump_profile($userentity,$userdomain);
      push(@classlist,{ firstname => $userprofile->{'firstname'}, 
                        middlename => $userprofile->{'middlename'}, 
                        lastname => $userprofile->{'lastname'},
                        suffix => $userprofile->{'suffix'},
                        username => &Apache::lc_entity_users::entity_to_username($userentity,$userdomain),
                        entity => $userentity,
                        domain => $userdomain,
                        pid => &Apache::lc_entity_users::entity_to_pid($userentity,$userdomain),
                        role => $role,
                        section => &Apache::lc_entity_roles::norm_section($rolesection),
                        startdate => $startdate,
                        enddate => $enddate,
                        manualenrollentity => $manualenrollentity,
                        manualenrolldomain => $manualenrolldomain });
   }
   return @classlist;
}

BEGIN {
   &Apache::lc_connection_handle::register('course_to_entity',undef,undef,undef,\&local_course_to_entity,'courseid','domain');
   &Apache::lc_connection_handle::register('entity_to_course',undef,undef,undef,\&local_entity_to_course,'entity','domain');
   &Apache::lc_connection_handle::register('make_new_course',undef,undef,undef,\&local_make_new_course,'courseid','domain');
}

1;
__END__
