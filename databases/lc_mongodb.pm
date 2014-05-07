# The LearningOnline Network with CAPA - LON-CAPA
# Deal with MongoDB
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
package Apache::lc_mongodb;

use strict;
use MongoDB;

use Apache::lc_logs;
use Hash::Merge;
use Data::Dumper;

use vars qw($merge $client $database $roles $profiles $sessions $auth $metadata);

#
# Make a new profile
#
sub insert_profile {
   my ($entity,$domain,$data)=@_;
   unless ($profiles) { &init_mongo(); }
   my $newdata->{'entity'}=$entity;
   $newdata->{'domain'}=$domain;
   $newdata->{'profile'}=$data;
   return $profiles->insert($newdata)->{'value'};
}

sub update_profile {
   my ($entity,$domain,$data)=@_;
   unless ($profiles) { &init_mongo(); }
   my $olddata=$profiles->find_one({ entity => $entity, domain => $domain });
   my $newdata->{'profile'}=$merge->merge($data,$olddata->{'profile'});
   $newdata->{'entity'}=$entity;
   $newdata->{'domain'}=$domain;
   delete($newdata->{'_id'});
   return $profiles->update({ entity => $entity, domain => $domain },$newdata);
}

sub dump_profile {
   my ($entity,$domain)=@_;
   unless ($profiles) { &init_mongo(); }
   my $result=$profiles->find_one({ entity => $entity, domain => $domain });
   if ($result) {
      return $result->{'profile'};
   } else {
      return undef;
   }
}

#
# Query for entry
#
sub query_user_profiles {
   my ($term1,$term2)=@_;
   unless ($term1) { $term1=''; }
   unless ($term2) { $term2=''; }
   unless ($profiles) { &init_mongo(); }
   if ($term2) {
      return $profiles->find({ '$or' => [{'profile.firstname' => qr/\Q$term1\E/i,
                                          'profile.lastname'  => qr/\Q$term2\E/i},
                                         {'profile.firstname' => qr/\Q$term2\E/i,
                                          'profile.lastname'  => qr/\Q$term1\E/i}] })->all;
   } else {
      return $profiles->find({ '$or' => [{'profile.firstname' => qr/\Q$term1\E/i},
                                         {'profile.lastname'  => qr/\Q$term1\E/i}] })->all;
   }
}

sub query_course_profiles {
   my ($term)=@_;
   unless ($profiles) { &init_mongo(); }
   return $profiles->find({'profile.title' => qr/\Q$term\E/i})->all;
}

#
# Metadata
#
sub insert_metadata {
   my ($entity,$domain,$data)=@_;
   unless ($metadata) { &init_mongo(); }
   my $newdata->{'entity'}=$entity;
   $newdata->{'domain'}=$domain;
   $newdata->{'metadata'}=$data;
   return $metadata->insert($newdata)->{'value'};
}

sub update_metadata {
   my ($entity,$domain,$data)=@_;
   unless ($metadata) { &init_mongo(); }
   my $olddata=$metadata->find_one({ entity => $entity, domain => $domain });
   my $newdata->{'metadata'}=$merge->merge($data,$olddata->{'metadata'});
   $newdata->{'entity'}=$entity;
   $newdata->{'domain'}=$domain;
   delete($newdata->{'_id'});
   return $metadata->update({ entity => $entity, domain => $domain },$newdata);
}

sub dump_metadata {
   my ($entity,$domain)=@_;
   unless ($metadata) { &init_mongo(); }
   my $result=$metadata->find_one({ entity => $entity, domain => $domain });
   if ($result) {
      return $result->{'metadata'};
   } else {
      return undef;
   }
}

#
# Insert something into the roles collection
#
sub insert_roles {
   my ($entity,$domain,$data)=@_;
   unless ($roles) { &init_mongo(); }
   my $newdata->{'entity'}=$entity;
   $newdata->{'domain'}=$domain;
   $newdata->{'roles'}=$data;
   return $roles->insert($newdata)->{'value'};
}

sub update_roles {
   my ($entity,$domain,$data)=@_;
   unless ($roles) { &init_mongo(); }
   my $olddata=$roles->find_one({ entity => $entity, domain => $domain });
   my $newdata->{'roles'}=$merge->merge($data,$olddata->{'roles'});
   $newdata->{'entity'}=$entity;
   $newdata->{'domain'}=$domain;
   delete($newdata->{'_id'});
   return $roles->update({ entity => $entity, domain => $domain },$newdata);
}

sub dump_roles {
   my ($entity,$domain)=@_;
   unless ($roles) { &init_mongo(); }
   my $result=$roles->find_one({ entity => $entity, domain => $domain });
   if ($result) { 
      return $result->{'roles'}; 
   } else {
      return undef;
   } 
}

#
# Authentication data
#

sub insert_auth {
   my ($entity,$domain,$data)=@_;
   unless ($auth) { &init_mongo(); }
   my $newdata->{'entity'}=$entity;
   $newdata->{'domain'}=$domain;
   $newdata->{'auth'}=$data;
   return $auth->insert($newdata)->{'value'};
}

sub update_auth {
   my ($entity,$domain,$data)=@_;
   unless ($auth) { &init_mongo(); }
   my $olddata=$auth->find_one({ entity => $entity, domain => $domain });
   my $newdata->{'auth'}=$merge->merge($data,$olddata->{'auth'});
   $newdata->{'entity'}=$entity;
   $newdata->{'domain'}=$domain;
   delete($newdata->{'_id'});
   return $auth->update({ entity => $entity, domain => $domain },$newdata);
}

sub dump_auth {
   my ($entity,$domain)=@_;
   unless ($auth) { &init_mongo(); }
   my $result=$auth->find_one({ entity => $entity, domain => $domain });
   if ($result) {
      return $result->{'auth'};
   } else {
      return undef;
   }
}

#
# Sessions 
#

sub open_session {
   my ($entity,$domain,$sessionid,$data)=@_;
   unless ($sessions) { &init_mongo(); }
   $sessions->remove({ entity => $entity, domain => $domain});
   my $newdata->{'entity'}=$entity;
   $newdata->{'domain'}=$domain;
   $newdata->{'sessionid'}=$sessionid;
   $newdata->{'sessiondata'}=$data;
   return $sessions->insert($newdata)->{'value'};
}

sub update_session {
   my ($sessionid,$data)=@_;
   unless ($sessions) { &init_mongo(); }
   my $olddata=$sessions->find_one({ sessionid => $sessionid });
   my $newdata=$olddata;
   $newdata->{'sessiondata'}=$merge->merge($data,$olddata->{'sessiondata'});
   delete($newdata->{'_id'});
   return $sessions->update({ sessionid => $sessionid },$newdata);
}

sub replace_session_key {
   my ($sessionid,$key,$data)=@_;
   unless ($sessions) { &init_mongo(); }
   my $olddata=$sessions->find_one({ sessionid => $sessionid });
   $olddata->{'sessiondata'}->{$key}=$data;
   delete($olddata->{'_id'});
   return $sessions->update({ sessionid => $sessionid },$olddata);
}


sub dump_session {
   my ($sessionid)=@_;
   unless ($sessions) { &init_mongo(); }
   my $result=$sessions->find_one({ sessionid => $sessionid });
   if ($result) {
      return $result;
   } else {
      return undef;
   }
}

sub close_session {
   my ($sessionid)=@_;
   unless ($sessions) { &init_mongo(); }
   return $sessions->remove({ sessionid => $sessionid });
}



#
# Initialize the MongoDB client, local host
#
sub init_mongo {
# Open the client. If fail, will likely take down Apache child,
# but that's okay - we need the database to run
   if ($client=MongoDB::MongoClient->new()) {
      &lognotice("Connected to MongoDB");
   } else {
      &logerror("Could not connect to MongoDB");
   }
# Get the LON-CAPA database in MongoDB
   $database=$client->get_database('loncapa');
# Get handles on all the collections we maintain
   $roles=$database->get_collection('roles');
   $profiles=$database->get_collection('profiles');
   $sessions=$database->get_collection('sessions');
   $auth=$database->get_collection('auth');
   $metadata=$database->get_collection('metadata');
}

BEGIN {
   $merge=Hash::Merge->new();
}

1;
__END__
