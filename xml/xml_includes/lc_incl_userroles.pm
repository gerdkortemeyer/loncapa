# The LearningOnline Network with CAPA - LON-CAPA
# Include handlers for user roles
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
package Apache::lc_incl_userroles;

use strict;
use Apache::lc_json_utils();
use Apache::lc_file_utils();
use Apache::lc_xml_utils();
use Apache::lc_xml_forms();
use Apache::lc_entity_users();
use Apache::lc_entity_roles();
use Apache::lc_entity_profile();
use Apache2::Const qw(:common);


use Data::Dumper;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(incl_spreadsheet_finalize_items);

sub incl_spreadsheet_finalize_items {
# Get posted content
   my %content=&Apache::lc_entity_sessions::posted_content();
# See what we all learned
   my $associations;
# If we are getting fresh information, we need to flush old associations
   if ($content{'flush_associations'}) {
      $associations=&evaluate_associations(%content);
   } else {
# Load the old stuff
      $associations=&load_associations();
   }
# Load the spreadsheet itself
   my $sheets=&load_sheets();
# Keep moving through all sheets, in order, so we can pick up where we left off
   my $found_corrected=0;
   foreach my $worksheet (sort(keys(%{$sheets}))) {
      my $minrow=$sheets->{$worksheet}->{'row_min'};
      if ($content{'ignorefirstrow'}) {
         $minrow++;
      }
# ... and all rows, each of them representing a user
# This is the big loop going through all users
      foreach my $row ($minrow .. $sheets->{$worksheet}->{'row_max'}) {
         my $output='';
         if (($content{'corrected_record'}) && (!$found_corrected)) {
# We need to pick up where we left off
            if (($content{'corrected_record_sheet'} eq $worksheet) &&
                ($content{'corrected_record_row'} eq $row)) { 
# Deal with it, evaluate corrections and enroll
#FIXME
# Remember that we found it
               $found_corrected=1; 
            }
# Whatever it is, we need to move one further
            next;
         }
# This will now be an uncorrected record (which may or may not be fine as it is)
# Gather all of the information we have about this user and see if we have enough to do the enrollment
# If not, we need to ask
# First, gather everything we can from the spreadsheet row
         my ($username,$domain,$userrecord)=&evaluate_row($sheets->{$worksheet}->{'cells'}->{$row},$associations);
# No username? Bad, skip this
         unless ($username) { next; }
# Flags if fixups are needed
         my $fixup_flag=0;
         my $problems='';
# Collect all we know from the spreadsheet
         my $userrecord=&evaluate_row($sheets->{$worksheet}->{'cells'}->{$row},$associations);
# Collect what we already know, if anything
         my $entity=&Apache::lc_entity_users::username_to_entity($username,$domain);
         if ($entity) {
            my $profile=&Apache::lc_entity_profile::dump_profile($entity,$domain);
# Merge, according to settings and privileges
            foreach my $namepart ('firstname','middlename','lastname','suffix') {
               if ($userrecord->{$namepart}) {
                  unless (&allowed_course('modify_name',undef,&Apache::lc_entity_sessions::course_entity_domain())) {
                     $userrecord->{$namepart}=$profile->{$namepart};
                  }
               } else {
                  $userrecord->{$namepart}=$profile->{$namepart};
               }
            }
            
$content{'overrideauth'};
$content{'overridepid'};
$content{'overridename'};
         }
# Prepare problem output, even though we might not need it
         $problems.="<h2>$username $domain ".$userrecord->{'firstname'}.' '.$userrecord->{'lastname'}."</h2>";
         unless ($userrecord->{'lastname'}) {
            $problems.='lastnameinput';
            $fixup_flag=1;
         }
         unless ($userrecord->{'firstname'}) {
            $problems.='firstnameinput';
            $fixup_flag=1;
         }
         unless ($entity) {
            unless ($userrecord->{'$password'}) {
               $problems.='passwordinput';
               $fixup_flag=1;
            }
         }

         if ($fixup_flag) {
# Wow, there is a problem, we need to ask the user
            $output.=$problems;
# Okay, remember where we were, and we are out of here
            $output.=&Apache::lc_xml_forms::hidden_field('corrected_record_sheet',$worksheet).
                     &Apache::lc_xml_forms::hidden_field('corrected_record_row',$row);
            $output.='<br />'.
                     &Apache::lc_xml_forms::cancelbutton('cancel','Cancel').'&nbsp;'.
                     &Apache::lc_xml_forms::cancelbutton('skip','Skip').'&nbsp;'.
                     &Apache::lc_xml_forms::triggerbutton('continue','Continue');
            return $output;
         } else {
# Cool, we have everything we need, let's store and then more on
#FIXME           &store_record($username,$domain,$newroles,$newprofile); 
         }
      }
   }
# Successfully finished everything!
   return &Apache::lc_xml_utils::success_message('Upload complete.');
}

#
# Load associations from disk
#
sub load_associations {
   my ($entity,$domain)=&Apache::lc_entity_sessions::user_entity_domain();
   return &Apache::lc_json_utils::json_to_perl(
          &Apache::lc_file_utils::readfile(
          &Apache::lc_entity_urls::wrk_to_filepath($domain.'/'.$entity.'/uploaded_spreadsheet_associations.json')));
}

#
# Load the spreadsheet
#
sub load_sheets {
   my ($entity,$domain)=&Apache::lc_entity_sessions::user_entity_domain();
   return &Apache::lc_json_utils::json_to_perl(
          &Apache::lc_file_utils::readfile(
          &Apache::lc_entity_urls::wrk_to_filepath($domain.'/'.$entity.'/uploaded_spreadsheet.json')));
}
#
# Pull the association rules out of the web form
#
sub sheet_column {
   if (@_[0]=~/^(.+)c(\d+)$/) {
      return ($1,$2);
   } else {
      return undef;
   }
}
#
sub evaluate_associations {
   my (%content)=@_;
   my $associations=undef;
   foreach my $key (keys(%content)) {
      if (($content{$key} eq 'username') ||
          ($content{$key} eq 'userpid') ||
          ($content{$key} eq 'useremail')) {
         ($associations->{'record'}->{'username'}->{'sheet'},
         $associations->{'record'}->{'username'}->{'column'})=&sheet_column($key);
      }
      foreach my $namepart ('firstname','middlename','lastname','suffix') {
         if ($content{$key} eq $namepart) {
            ($associations->{'record'}->{'name'}->{$namepart}->{'sheet'},
             $associations->{'record'}->{'name'}->{$namepart}->{'column'})=&sheet_column($key);
            $associations->{'record'}->{'name'}->{'mode'}='individual';
         }
      }
      if ($content{$key} eq 'namecombi') {
         ($associations->{'record'}->{'name'}->{'namecombi'}->{'sheet'},
          $associations->{'record'}->{'name'}->{'namecombi'}->{'column'})=&sheet_column($key);
         $associations->{'record'}->{'name'}->{'mode'}='combi';
      }
      if (($content{$key} eq 'email') ||
          ($content{$key} eq 'useremail')) {
         ($associations->{'record'}->{'email'}->{'sheet'},
          $associations->{'record'}->{'email'}->{'column'})=&sheet_column($key);
      }
      if (($content{$key} eq 'pid') ||
          ($content{$key} eq 'userpid') ||
          ($content{$key} eq 'passwordpid')) {
         ($associations->{'record'}->{'pid'}->{'sheet'},
          $associations->{'record'}->{'pid'}->{'column'})=&sheet_column($key);
      }
      foreach my $param ('section','domain','startdate','enddate','authmode','role') { 
         if ($content{$key} eq $param) {
            ($associations->{'record'}->{$param}->{'sheet'},
             $associations->{'record'}->{$param}->{'column'})=&sheet_column($key);
            $associations->{'record'}->{$param}->{'mode'}='individual';
         }
      }
      if (($content{$key} eq 'password') ||
          ($content{$key} eq 'passwordpid')) {
         ($associations->{'record'}->{'password'}->{'sheet'},
          $associations->{'record'}->{'password'}->{'column'})=&sheet_column($key);
         $associations->{'record'}->{'password'}->{'mode'}='individual'
      }
   }
   foreach my $param ('domain','password','role','section') {
      unless ($associations->{'record'}->{$param}->{'mode'}) {
         $associations->{'record'}->{$param}->{'default'}=$content{'default'.$param};
         $associations->{'record'}->{$param}->{'mode'}='default';
      }
   }
   unless ($associations->{'record'}->{'startdate'}->{'mode'}) {
      $associations->{'record'}->{'startdate'}->{'default'}=
          &Apache::lc_ui_localize::inputdate_to_timestamp(
              $content{'defaultstartdate_date'},
              $content{'defaultstartdate_time_hour'},
              $content{'defaultstartdate_time_min'},
              $content{'defaultstartdate_time_sec'},
              $content{'defaultstartdate_time_ampm'},
              $content{'defaultstartdate_time_zone'});
      $associations->{'record'}->{'startdate'}->{'mode'}='default';
   }
   unless ($associations->{'record'}->{'enddate'}->{'mode'}) {
      $associations->{'record'}->{'enddate'}->{'default'}=
          &Apache::lc_ui_localize::inputdate_to_timestamp(
              $content{'defaultenddate_date'},
              $content{'defaultenddate_time_hour'},
              $content{'defaultenddate_time_min'},
              $content{'defaultenddate_time_sec'},
              $content{'defaultenddate_time_ampm'},
              $content{'defaultenddate_time_zone'});
      $associations->{'record'}->{'enddate'}->{'mode'}='default';
   }
   return $associations;
}
#
# Evaluate a row in a spreadsheet based on association rules
#
sub evaluate_row {
   my ($row,$associations)=@_;
# Where the user record goes
   my $userrecord;
# Get the username
   my $username=$row->{$associations->{'record'}->{'username'}->{'column'}}->{'unformatted'};
# Get the domain
   my $domain;
   if ($associations->{'record'}->{'domain'}->{'mode'} eq 'default') {
      $domain=$associations->{'record'}->{'domain'}->{'default'};
   } else {
      $domain=$row->{$associations->{'record'}->{'domain'}->{'column'}}->{'unformatted'};
   }
# If we do not have at least a username and domain, we give up
   unless (($username) && ($domain)) { return undef }
# Get the name, individual or combi
   if ($associations->{'record'}->{'name'}->{'mode'} eq 'individual') {
      $userrecord->{'firstname'}=$row->{$associations->{'record'}->{'name'}->{'firstname'}->{'column'}}->{'unformatted'};
      $userrecord->{'middlename'}=$row->{$associations->{'record'}->{'name'}->{'middlename'}->{'column'}}->{'unformatted'};
      $userrecord->{'lastname'}=$row->{$associations->{'record'}->{'name'}->{'lastname'}->{'column'}}->{'unformatted'};
      $userrecord->{'suffix'}=$row->{$associations->{'record'}->{'name'}->{'suffix'}->{'column'}}->{'unformatted'};
   } else {
      ($userrecord->{'lastname'},$userrecord->{'firstname'},$userrecord->{'middlename'})
      =($row->{$associations->{'record'}->{'name'}->{'namecombi'}->{'column'}}->{'unformatted'}=~/^\s*(.+)\s*\,\s*(\S+)\s*(.*)$/);
   }
# Get section
   if ($associations->{'record'}->{'section'}->{'mode'} eq 'default') {
      $userrecord->{'section'}=$associations->{'record'}->{'section'}->{'default'};
   } else {
      $userrecord->{'section'}=$row->{$associations->{'record'}->{'section'}->{'column'}}->{'unformatted'};
   }
# Get startdate
   if ($associations->{'record'}->{'startdate'}->{'mode'} eq 'default') {
      $userrecord->{'startdate'}=$associations->{'record'}->{'startdate'}->{'default'};
   } else {
      $userrecord->{'startdate'}=&Apache::lc_date_utils::guess_str2num(
           (($row->{$associations->{'record'}->{'startdate'}->{'column'}}->{'type'}=~/date/i)?
            $row->{$associations->{'record'}->{'startdate'}->{'column'}}->{'value'}:
            $row->{$associations->{'record'}->{'startdate'}->{'column'}}->{'unformatted'}));
   }
# Get enddate
   if ($associations->{'record'}->{'enddate'}->{'mode'} eq 'default') {
      $userrecord->{'enddate'}=$associations->{'record'}->{'enddate'}->{'default'};
   } else {
      $userrecord->{'enddate'}=&Apache::lc_date_utils::guess_str2num(
           (($row->{$associations->{'record'}->{'enddate'}->{'column'}}->{'type'}=~/date/i)?
            $row->{$associations->{'record'}->{'enddate'}->{'column'}}->{'value'}:
            $row->{$associations->{'record'}->{'enddate'}->{'column'}}->{'unformatted'}));

   }
   return ($username,$domain,$userrecord);
}

sub handler {
   my $r=shift;
   $r->print(&incl_spreadsheet_finalize_items());
   return OK;
}

1;
__END__
