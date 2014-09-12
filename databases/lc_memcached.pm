# The LearningOnline Network with CAPA - LON-CAPA
# Deal with memcached
#
# !!!
# !!! These are low-level routines. They do no sanity checking on parameters!
# !!! Do not call from higher level handlers, do no not use direct user input
# !!!
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
package Apache::lc_memcached;

use strict;
use Cache::Memcached;
use Apache::lc_logs;
use Apache::lc_parameters;

use vars qw($memd);

#
# Deal with connection table storage
#
sub get_connection_table {
   return &mget('connection_table');
}

sub set_connection_table {
   &mset('connection_table',@_[0]);
}

#
# Deal with homeserver cache
#
sub insert_homeserver {
   my ($entity,$domain,$homeserver)=@_;
   &mset("homeserver:$entity:$domain",$homeserver);
}

sub lookup_homeserver {
   my ($entity,$domain)=@_;
   return &mget("homeserver:$entity:$domain");
}

#
# Deal with URL cache
#
sub insert_url {
   my ($url,$entity)=@_;
   &mset("url:$url",$entity);
}

sub lookup_url_entity {
   return &mget("url:".@_[0]);
}

#
# Deal with PID cache
#
sub insert_pid {
   my ($pid,$domain,$entity)=@_;
   &mset("pid:$pid:$domain",$entity,&lc_medium_expire());
   &mset("entitypid:$entity:$domain",$pid,&lc_medium_expire());
}

sub lookup_pid_entity {
   my ($pid,$domain)=@_;
   return &mget("pid:$pid:$domain");
}

sub lookup_entity_pid {
   my ($entity,$domain)=@_;
   return &mget("entitypid:$entity:$domain");
}


#
# Deal with usernames cache
#
sub insert_username {
   my ($username,$domain,$entity)=@_;
   &mset("username:$username:$domain",$entity,&lc_medium_expire());
   &mset("entityusername:$entity:$domain",$username,&lc_medium_expire());
}

sub lookup_username_entity {
   my ($username,$domain)=@_;
   return &mget("username:$username:$domain");
}

sub lookup_entity_username {
   my ($entity,$domain)=@_;
   return &mget("entityusername:$entity:$domain");
}

#
# Deal with courseid cache
#
sub insert_course {
    my ($course,$domain,$entity)=@_;
    &mset("course:$course:$domain",$entity,&lc_medium_expire());
    &mset("entitycourse:$entity:$domain",$course,&lc_medium_expire());
}

sub lookup_course_entity {
   my ($course,$domain)=@_;
   return &mget("course:$course:$domain");
}

sub lookup_entity_course {
   my ($entity,$domain)=@_;
   return &mget("entitycourse:$entity:$domain");
}

#
# Deal with current version cache
#
sub insert_current_version {
   my ($entity,$domain,$version)=@_;
   &mset("currentversion:$entity:$domain",$version,&lc_short_expire());
}

sub lookup_current_version {
   my ($entity,$domain)=@_;
   return &mget("currentversion:$entity:$domain");
}

#
# Deal with as-of version cache
#
sub insert_as_of_version {
   my ($entity,$domain,$date,$version)=@_;
   $date=~s/\s+/\_/gs;
   &mset("asofversion:$entity:$domain:$date",$version,&lc_long_expire());
}

sub lookup_as_of_version {
   my ($entity,$domain,$date)=@_;
   $date=~s/\s+/\_/gs;
   return &mget("asofversion:$entity:$domain:$date");
}

#
# Store all of the metadata
#
sub insert_metadata {
   my ($entity,$domain,$metadata)=@_;
   &mset("metadata:$entity:$domain",$metadata,&lc_short_expire());
}

sub lookup_metadata {
   my ($entity,$domain)=@_;
   return &mget("metadata:$entity:$domain");
}

#
# Tokens
#
sub insert_token {
   my ($token,$tokendata)=@_;
   &mset("token:$token",$tokendata,&lc_medium_expire());
}

sub lookup_token {
   my ($token)=@_;
   return &mget("token:$token");
}

#
# Caching table of contents
#
sub insert_toc {
   my ($entity,$domain,$toc)=@_;
   &mset("toc:$entity:$domain",$toc,&lc_short_expire());
}

sub lookup_toc {
   my ($entity,$domain)=@_;
   return &mget("toc:$entity:$domain");
}

sub insert_tocdigest {
   my ($uentity,$udomain,$centity,$cdomain,$toc)=@_;
   &mset("tocdigest:$uentity:$udomain:$centity:$cdomain",$toc,&lc_short_expire());
}

sub lookup_tocdigest {
   my ($uentity,$udomain,$centity,$cdomain)=@_;
   return &mget("tocdigest:$uentity:$udomain:$centity:$cdomain");
}

#
# Caching entity profiles
#
sub insert_profile {
   my ($entity,$domain,$profile)=@_;
   &mset("profile:$entity:$domain",$profile,&lc_medium_expire());
}

sub lookup_profile {
   my ($entity,$domain)=@_;
   return &mget("profile:$entity:$domain");
}

#
# Caching progress indicators
#
sub insert_progress {
   my ($entity,$domain,$which,$data)=@_;
   &mset("progress:$entity:$domain:$which",$data,&lc_long_expire());
}

sub lookup_progress {
   my ($entity,$domain,$which)=@_;
   return &mget("progress:$entity:$domain:$which");
}

# === Direct access
# You don't want to call these from outside
#
# Get key
sub mget {
   return $memd->get(@_[0]);
}

#
# Set key, value, expiration
sub mset {
   $memd->set(@_);
}
   


#
# Initialize the memd client, local host
#
sub init_memd {
   $memd=new Cache::Memcached({'servers' => ['127.0.0.1:11211']});
   if ($memd->set('connected','yes')) {
      &lognotice("Connected to memcached");
   } else {
      &logerror("Could not connect to memcached");
   } 
}

BEGIN {
   &init_memd();
}

1;
__END__
