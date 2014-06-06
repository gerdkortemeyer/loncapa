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

sub sheet_column {
   if (@_[0]=~/^(.+)c(\d+)$/) {
      return ($1,$2);
   } else {
      return undef;
   }
}

sub incl_spreadsheet_finalize_items {
# Get posted content
   my %content=&Apache::lc_entity_sessions::posted_content();
# Who are we?
   my ($entity,$domain)=&Apache::lc_entity_sessions::user_entity_domain();
# See what we all learned
   my $associations;
# If we are getting fresh information, we need to flush old associations
   if ($content{'flush_associations'}) {
      $associations=undef;
      foreach my $key (keys(%content)) {
         if (($content{$key} eq 'username') ||
             ($content{$key} eq 'userpid') ||
             ($content{$key} eq 'useremail')) {
            ($associations->{'record'}->{'username'}->{'sheet'},
             $associations->{'record'}->{'username'}->{'column'})=&sheet_column($key);
         }
         if ($content{$key} eq 'firstname') {
            ($associations->{'record'}->{'name'}->{'firstname'}->{'sheet'},
             $associations->{'record'}->{'name'}->{'firstname'}->{'column'})=&sheet_column($key);
            $associations->{'record'}->{'name'}->{'mode'}='individual';
         }
         if ($content{$key} eq 'middlename') {
            ($associations->{'record'}->{'name'}->{'middlename'}->{'sheet'},
             $associations->{'record'}->{'name'}->{'middlename'}->{'column'})=&sheet_column($key);
            $associations->{'record'}->{'name'}->{'mode'}='individual';
         }
         if ($content{$key} eq 'lastname') {
            ($associations->{'record'}->{'name'}->{'lastname'}->{'sheet'},
             $associations->{'record'}->{'name'}->{'lastname'}->{'column'})=&sheet_column($key);
            $associations->{'record'}->{'name'}->{'mode'}='individual';
         }
         if ($content{$key} eq 'suffix') {
            ($associations->{'record'}->{'name'}->{'suffix'}->{'sheet'},
             $associations->{'record'}->{'name'}->{'suffix'}->{'column'})=&sheet_column($key);
            $associations->{'record'}->{'name'}->{'mode'}='individual';
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
         if ($content{$key} eq 'section') {
            ($associations->{'record'}->{'section'}->{'sheet'},
             $associations->{'record'}->{'section'}->{'column'})=&sheet_column($key);
         }
         if ($content{$key} eq 'domain') {
            ($associations->{'record'}->{'domain'}->{'sheet'},
             $associations->{'record'}->{'domain'}->{'column'})=&sheet_column($key);
            $associations->{'record'}->{'domain'}->{'mode'}='individual'
         }
         if ($content{$key} eq 'startdate') {
            ($associations->{'record'}->{'startdate'}->{'sheet'},
             $associations->{'record'}->{'startdate'}->{'column'})=&sheet_column($key);
            $associations->{'record'}->{'startdate'}->{'mode'}='individual'
         }
         if ($content{$key} eq 'enddate') {
            ($associations->{'record'}->{'enddate'}->{'sheet'},
             $associations->{'record'}->{'enddate'}->{'column'})=&sheet_column($key);
            $associations->{'record'}->{'enddate'}->{'mode'}='individual'
         }
         if ($content{$key} eq 'authmode') {
            ($associations->{'record'}->{'authmode'}->{'sheet'},
             $associations->{'record'}->{'authmode'}->{'column'})=&sheet_column($key);
            $associations->{'record'}->{'authmode'}->{'mode'}='individual'
         }
         if (($content{$key} eq 'password') ||
             ($content{$key} eq 'passwordpid')) {
            ($associations->{'record'}->{'password'}->{'sheet'},
             $associations->{'record'}->{'password'}->{'column'})=&sheet_column($key);
            $associations->{'record'}->{'password'}->{'mode'}='individual'
         }
         if ($content{$key} eq 'role') {
            ($associations->{'record'}->{'role'}->{'sheet'},
             $associations->{'record'}->{'role'}->{'column'})=&sheet_column($key);
            $associations->{'record'}->{'role'}->{'mode'}='individual'
         }
      }
      unless ($associations->{'record'}->{'domain'}->{'mode'}) {
         $associations->{'record'}->{'domain'}->{'default'}=$content{'defaultdomain'};
         $associations->{'record'}->{'domain'}->{'mode'}='default';
      }
      unless ($associations->{'record'}->{'password'}->{'mode'}) {
         $associations->{'record'}->{'password'}->{'default'}=$content{'defaultpassword'};
         $associations->{'record'}->{'password'}->{'mode'}='default';
      }
      unless ($associations->{'record'}->{'role'}->{'mode'}) {
         $associations->{'record'}->{'role'}->{'default'}=$content{'defaultrole'};
         $associations->{'record'}->{'role'}->{'mode'}='default';
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
   } else {
# Load the old stuff
      $associations=&Apache::lc_json_utils::json_to_perl(
                &Apache::lc_file_utils::readfile(
                   &Apache::lc_entity_urls::wrk_to_filepath($domain.'/'.$entity.'/uploaded_spreadsheet_associations.json')));
   }
# Load the spreadsheet itself
   my $sheets=&Apache::lc_json_utils::json_to_perl(
                &Apache::lc_file_utils::readfile(
                   &Apache::lc_entity_urls::wrk_to_filepath($domain.'/'.$entity.'/uploaded_spreadsheet.json')));
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

# Remember that we found it
               $found_corrected=1; 
            }
# Whatever it is, we need to move one further
            next;
         }
# This will now be an uncorrected record (which may or may not be fine as it is)
# Gather all of the information we have about this user and see if we have enough to do the enrollment
# If not, we need to ask
# Username/domain?
         my $username=
              $sheets->{$worksheet}->{'cells'}->{$row}->{$associations->{'record'}->{'username'}->{'column'}}->{'unformatted'};
         my $domain;
         if ($associations->{'record'}->{'domain'}->{'mode'} eq 'default') {
            $domain=$associations->{'record'}->{'domain'}->{'default'};
         } else {
            $domain=$sheets->{$worksheet}->{'cells'}->{$row}->{$associations->{'record'}->{'domain'}->{'column'}}->{'unformatted'};
         }
         unless (($username) && ($domain)) { next; }
# Try to determine entity to see if username exists
         my $entity=&Apache::lc_entity_users::username_to_entity($username,$domain);
# Load roles and profiles, if existing
         my $profile=undef;
         my $roles=undef;
         if ($entity) {
            $profile=&Apache::lc_entity_profile::dump_profile($entity,$domain);
            $roles=&Apache::lc_entity_roles::dump_roles($entity,$domain);
         }
#FIXME: debug
         $output.="<br />Record: $username domain $domain entity $entity <pre>".Dumper($profile)."\n".Dumper($roles)."</pre>";
# Flags if fixups are needed
         my $fixup_flag=0;
# Build the output, even if we might not need it
         $output.='<h3>'.join(' ',$profile->{'firstname'},$profile->{'middlename'},$profile->{'lastname'},$profile->{'suffix'}).'</h3>';
#FIXME: debug
         if ($entity) { $fixup_flag=1; }
         if ($fixup_flag) {
# Wow, there is a problem, we need to ask the user
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
# FIXME: better output
   return "<h1>Okay!</h1>";
}

sub handler {
   my $r=shift;
   $r->print(&incl_spreadsheet_finalize_items());
   return OK;
}

1;
__END__
