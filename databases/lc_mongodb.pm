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

use vars qw($merge $client $database $roles $profiles);

#
# Make a new profile
#
sub insert_profile {
   my ($entity,$domain,$data)=@_;
   my $newdata->{'entity'}=$entity;
   $newdata->{'domain'}=$domain;
   $newdata->{'profile'}=$data;
   return $profiles->insert($newdata)->{'value'};
}

sub update_profile {
   my ($entity,$domain,$data)=@_;
   my $olddata=$profiles->find_one({ entity => $entity, domain => $domain });
   my $newdata->{'profile'}=$merge->merge($data,$olddata->{'profile'});
   $newdata->{'entity'}=$entity;
   $newdata->{'domain'}=$domain;
   delete($newdata->{'_id'});
   return $profiles->update({ entity => $entity, domain => $domain },$newdata);
}

sub dump_profile {
   my ($entity,$domain)=@_;
   my $result=$profiles->find_one({ entity => $entity, domain => $domain });
   if ($result) {
      return $result->{'profile'};
   } else {
      return undef;
   }
}


#
# Insert something into the roles collection
#
sub insert_roles {
   my ($entity,$domain,$data)=@_;
   my $newdata->{'entity'}=$entity;
   $newdata->{'domain'}=$domain;
   $newdata->{'roles'}=$data;
   return $roles->insert($newdata)->{'value'};
}

sub update_roles {
   my ($entity,$domain,$data)=@_;
   my $olddata=$roles->find_one({ entity => $entity, domain => $domain });
   my $newdata->{'roles'}=$merge->merge($data,$olddata->{'roles'});
   $newdata->{'entity'}=$entity;
   $newdata->{'domain'}=$domain;
   delete($newdata->{'_id'});
   return $roles->update({ entity => $entity, domain => $domain },$newdata);
}

sub dump_roles {
   my ($entity,$domain)=@_;
   my $result=$roles->find_one({ entity => $entity, domain => $domain });
   if ($result) { 
      return $result->{'roles'}; 
   } else {
      return undef;
   } 
}

#
# 
#


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
}

BEGIN {
   &init_mongo();
   $merge=Hash::Merge->new();
}

1;
__END__
