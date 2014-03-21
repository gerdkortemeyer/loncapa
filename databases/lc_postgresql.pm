# The LearningOnline Network with CAPA - LON-CAPA
# Deal with PostgreSQL
#
# Permanent data for entities is stored on their respective homeservers
#
# !!!
# !!! These are low-level routines. They do no sanity checking on parameters!
# !!! Do not call from higher level handlers, do no not use direct user input
# !!!
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
package Apache::lc_postgresql;

use strict;
use DBI;
use Hash::Merge;
use Apache::lc_logs;
use Apache::lc_date_utils();

use vars qw($merge $dbh);

#
# Deal with assessment data
#
# === Store data from one transaction
#
sub store_assessment_transaction {
   my ($courseentity,$coursedomain,
       $userentity,$userdomain,
       $resourceid,
       $partid,
       $scoretype,$score,
       $totaltries,$countedtries,
       $status,
       $responsedetailsjson)=@_;
# We need to see if this row exists already
   my $sth=$dbh->prepare(
    "select totaltries,responsedetailsjson from assessments where courseentity = ? and coursedomain = ? and userentity = ? and userdomain = ? and resourceid = ? and partid = ?"
                        );
   $sth->execute($courseentity,$coursedomain,
                 $userentity,$userdomain,
                 $resourceid,
                 $partid);
   my ($prev_totaltries,$oldresponsedetails)=$sth->fetchrow_array();
   if ($prev_totaltries) {
# Yes, this existed
      unless ($totaltries==$prev_totaltries+1) {
         &logwarning(
    "Checking number of tries failed for course ($courseentity) ($coursedomain) ($userentity) ($userdomain) ($resourceid) ($partid): $prev_totaltries/$totaltries");
         return -1;
      }
# Merge the new responsedetails into the old ones
      my $newresponsedetails=&Apache::lc_json_utils::perl_to_json($merge->merge(
                               (&Apache::lc_json_utils::json_to_perl($responsedetailsjson))[0],
                               (&Apache::lc_json_utils::json_to_perl($oldresponsedetails))[0]));
      $sth=$dbh->prepare(
    "update assessments set scoretype = ?, score = ?, totaltries = ?, countedtries = ?, status = ?, responsedetailsjson = ? where courseentity = ? and coursedomain = ? and userentity = ? and userdomain = ? and resourceid = ? and partid = ?");
      return $sth->execute($scoretype,$score,$totaltries,$countedtries,$status,$newresponsedetails,
                           $courseentity,$coursedomain,$userentity,$userdomain,$resourceid,$partid);
   } else {
# New record
      unless ($totaltries==1) {
         &logwarning("No existing record found for ($courseentity) ($coursedomain) ($userentity) ($userdomain) ($resourceid) ($partid)");
         return -1;
      }
      $sth=$dbh->prepare(
 "insert into assessments (courseentity,coursedomain,userentity,userdomain,resourceid,partid,scoretype,score,totaltries,countedtries,status,responsedetailsjson) values (?,?,?,?,?,?,?,?,?,?,?,?)");
      return $sth->execute($courseentity,$coursedomain,
       $userentity,$userdomain,
       $resourceid,
       $partid,
       $scoretype,$score,
       $totaltries,$countedtries,
       $status,
       $responsedetailsjson);
   }
}

#
# Get all data about one resource for one user
# returns a row for every part
# Called everytime that a problem needs to be brought up on the screen
#
sub get_one_student_assessment {
   my ($courseentity,$coursedomain,
       $userentity,$userdomain,
       $resourceid)=@_;
   my $sth=$dbh->prepare("select partid,scoretype,score,totaltries,countedtries,status,responsedetailsjson from assessments where courseentity = ? and coursedomain = ? and userentity = ? and userdomain = ? and resourceid = ?");
   my $rv=$sth->execute($courseentity,$coursedomain,
                        $userentity,$userdomain,
                        $resourceid);
   my $return;
   while (my @newrole=$sth->fetchrow_array()) {
      push(@{$return},\@newrole);
   }
   return $return;
}

#
# Get all assessment performance data for a class
# returns a row for every problem part
#
sub get_all_assessment_performance {
   my ($courseentity,$coursedomain)=@_;
   my $sth=$dbh->prepare("select userentity,userdomain,resourceid,partid,scoretype,score,totaltries,countedtries,status from assessments where courseentity = ? and coursedomain = ?");
   my $rv=$sth->execute($courseentity,$coursedomain);
   my $return;
   while (my @newrole=$sth->fetchrow_array()) {
      push(@{$return},\@newrole);
   }
   return $return;
}

#
# Deal with URLs
# - there is no "modify_url", since a URL once assigned stays with that entity
#
sub insert_url {
   my ($url,$entity)=@_;
# Commit this to the database return the return value
   my $sth=$dbh->prepare("insert into urls (url,entity) values (?,?)");
   return $sth->execute($url,$entity);
}

sub lookup_url_entity {
   my ($url)=@_;
# Do the query
   my $sth=$dbh->prepare("select entity from urls where url = ?");
   my $rv=$sth->execute($url);
   return $sth->fetchrow_array();
}

#
# Deal with homeservers
#
sub insert_homeserver {
   my ($entity,$domain,$homeserver)=@_;
# Commit this to the database return the return value
   my $sth=$dbh->prepare("insert into homeserverlookup (entity,domain,homeserver) values (?,?,?)");
   return $sth->execute($entity,$domain,$homeserver);
}

sub lookup_homeserver {
   my ($entity,$domain)=@_;
# Do the query
   my $sth=$dbh->prepare("select homeserver from homeserverlookup where entity = ? and domain = ?");
   my $rv=$sth->execute($entity,$domain);
   return $sth->fetchrow_array();
}

#
# Deal with student personal ID numbers
#
sub insert_pid {
   my ($pid,$domain,$entity)=@_;
# Commit this to the database return the return value
   my $sth=$dbh->prepare("insert into pidlookup (pid,domain,entity) values (?,?,?)");
   return $sth->execute($pid,$domain,$entity);
}

#
# Modify a PID assignment
# This should hardly ever happen!!!
# It means that a PID gets assigned from one individual to another - likely only the case if there
# was an error in the original assignment!!!
#
sub modify_pid {
   my ($pid,$domain,$entity)=@_;
   my $sth=$dbh->prepare("update pidlookup set entity = ? where pid = ? and domain = ?");
   return $sth->execute($entity,$pid,$domain);
}

#
# Delete a PID assignment
# This should hardly ever happen!!!
# It means that a PID gets deleted - likely only the case if there
# was an error in the original assignment!!!
#
sub delete_pid {
   my ($pid,$domain)=@_;
   my $sth=$dbh->prepare("delete from pidlookup where pid = ? and domain = ?");
   return $sth->execute($pid,$domain);
}


sub lookup_pid_entity {
   my ($pid,$domain)=@_;
# Do the query
  my $sth=$dbh->prepare("select entity from pidlookup where pid = ? and domain = ?");
  my $rv=$sth->execute($pid,$domain);
  return $sth->fetchrow_array();
}

#
# Deal with usernames
#
sub insert_username {
   my ($username,$domain,$entity)=@_;
# Commit this to the database return the return value
   my $sth=$dbh->prepare("insert into userlookup (username,domain,entity) values (?,?,?)");
   return $sth->execute($username,$domain,$entity);
}

sub lookup_username_entity {
   my ($username,$domain)=@_;
# Do the query
   my $sth=$dbh->prepare("select entity from userlookup where username = ? and domain = ?");
   my $rv=$sth->execute($username,$domain);
   return $sth->fetchrow_array();
}

#
# Deal with course IDs
#
sub insert_course {
   my ($courseid,$domain,$entity)=@_;
# Commit this to the database return the return value
   my $sth=$dbh->prepare("insert into courselookup (courseid,domain,entity) values (?,?,?)");
   return $sth->execute($courseid,$domain,$entity);
}

sub lookup_course_entity {
   my ($courseid,$domain)=@_;
# Do the query
   my $sth=$dbh->prepare("select entity from courselookup where courseid = ? and domain = ?");
   my $rv=$sth->execute($courseid,$domain);
   return $sth->fetchrow_array();
}

#
# Insert a new role into the rolelist
#
sub insert_into_rolelist {
   my ($roleentity,$roledomain,$rolesection,
       $userentity,$userdomain,
       $role,
       $startdate,$enddate,
       $manualenrollentity,$manualenrolldomain)=@_;
   my $sth=$dbh->prepare("insert into rolelist (roleentity,roledomain,rolesection,userentity,userdomain,role,startdate,enddate,manualenrollentity,manualenrolldomain) values (?,?,?,?,?,?,?,?,?,?)");
   return $sth->execute($roleentity,$roledomain,$rolesection,
       $userentity,$userdomain, 
       $role, 
       $startdate,$enddate,
       $manualenrollentity,$manualenrolldomain);
}

#
# Modify a user in rolelist
#
sub modify_rolelist {
   my ($roleentity,$roledomain,$rolesection,
       $userentity,$userdomain, 
       $role, 
       $startdate,$enddate,
       $manualenrollentity,$manualenrolldomain)=@_; 
   my $sth=$dbh->prepare("update rolelist set startdate = ?, enddate = ?, manualenrollentity = ?, manualenrolldomain = ? where roleentity = ? and roledomain = ? and rolesection = ? and userentity = ? and userdomain = ? and role = ?");
   return $sth->execute($startdate,$enddate,$manualenrollentity,$manualenrolldomain,$roleentity,$roledomain,$rolesection,$userentity,$userdomain,$role);
}

#
# Lookup if a particular role is already set
#
sub role_exists_rolelist {
   my ($roleentity,$roledomain,$rolesection,
       $userentity,$userdomain,
       $role)=@_;
   my $sth=$dbh->prepare("select * from rolelist where roleentity = ? and roledomain = ? and rolesection = ? and userentity = ? and userdomain = ? and role = ?");
   my $rv=$sth->execute($roleentity,$roledomain,$rolesection,
                        $userentity,$userdomain,
                        $role);
   return $sth->fetchrow_array();
}

#
# Lookup all roles for a particular entity
# e.g, a courselist
#
sub lookup_entity_rolelist {
   my ($roleentity,$roledomain)=@_;
   my $sth=$dbh->prepare("select * from rolelist where roleentity = ? and roledomain = ?");
   my $rv=$sth->execute($roleentity,$roledomain);
   my $return;
   while (my @newrole=$sth->fetchrow_array()) {
      push(@{$return},\@newrole);
   }
   return $return;
}

#
# Initialize the postgreSQL handle, local host
#
sub init_postgres {
   if ($dbh=DBI->connect('DBI:Pg:dbname=loncapa;host=127.0.0.1;port=5432','loncapa','loncapa',{ RaiseError => 0 })) {
      &lognotice("Connected to PostgreSQL");
   } else {
      &logerror("Could not connect to PostgreSQL, ".$DBI::errstr);
   } 
}

BEGIN {
   &init_postgres();
   $merge=Hash::Merge->new();
}

1;
__END__
