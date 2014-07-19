# The LearningOnline Network with CAPA - LON-CAPA
# Include handler modifying course users
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
package Apache::lc_incl_modify_courseusers;

use strict;
use Apache::lc_json_utils();
use Apache::lc_file_utils();
use Apache::lc_xml_utils();
use Apache::lc_authorize;
use Apache::lc_ui_localize;
use Apache::lc_xml_forms();
use Apache::lc_xml_gadgets();
use Apache::lc_entity_users();
use Apache::lc_entity_roles();
use Apache::lc_entity_profile();
use Apache::lc_logs;
use Apache2::Const qw(:common);


use Data::Dumper;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(incl_modify_courseusers_finalize);

sub incl_modify_courseusers_finalize {
# Get posted content
   my %content=&Apache::lc_entity_sessions::posted_content();
   my $output='';
# Storage or display stage?
   if ($content{'stage_three'}) {
      my ($entity,$domain)=&Apache::lc_entity_sessions::user_entity_domain();
      my $modifyusers=&Apache::lc_json_utils::json_to_perl(
            &Apache::lc_file_utils::readfile(
               &Apache::lc_entity_urls::wrk_to_filepath($domain.'/'.$entity.'/modify_users.json')));
      unless ($modifyusers) {
         return '<script>followup=0;error=1;</script>';
      }
# Work through the records, one by one
      foreach my $userrecord (@{$modifyusers}) {
         if (&changerecord($userrecord,\%content)) {
            &Apache::lc_entity_sessions::inc_progress('modifyuserfinalize','success');
         } else {
            &Apache::lc_entity_sessions::inc_progress('modifyuserfinalize','fail');
         }
      }
   } elsif ($content{'stage_two'}) {
# We actually store things
# Load the user information
      my ($entity,$domain)=&Apache::lc_entity_sessions::user_entity_domain();
      my $modifyusers=&Apache::lc_json_utils::json_to_perl(
            &Apache::lc_file_utils::readfile(
               &Apache::lc_entity_urls::wrk_to_filepath($domain.'/'.$entity.'/modify_users.json')));
      unless ($modifyusers) {
         return '<script>followup=0;error=1;</script>';
      }

      my %setfields;
      foreach my $field ('firstname','middlename','lastname','suffix','pid',
                         'password','role','section') {
          if (($content{$field}=~/\S/) && (!$content{$field.'_locked'})) {
             $setfields{$field}=$content{$field};
          }
      }
      foreach my $field ('startdate','enddate') {
         if (($content{$field.'_date'}) && (!$content{$field})) {
            $setfields{$field}=&Apache::lc_ui_localize::inputdate_to_timestamp(
                                   $content{$field.'_date'},
                                   $content{$field.'_time_hour'},
                                   $content{$field.'_time_min'},
                                   $content{$field.'_time_sec'},
                                   $content{$field.'_time_ampm'},
                                   $content{$field.'_time_zone'});
         }
      }
# How many do we have?
      my $number=$#{$modifyusers};
      if ($number>0) {
# If we have more than one, bring up a progress bar and do things asyncronously
# Reset counter for progressbar
         &Apache::lc_entity_sessions::reset_progress('modifyuserfinalize');
         &Apache::lc_entity_sessions::set_progress_total('modifyuserfinalize',$number+1);
# Remember stuff for the background process
         foreach my $key (keys(%setfields)) {
            $output.=&Apache::lc_xml_forms::hidden_field($key,$setfields{$key});
         }
# Bring up progress bar and fire up background process
         $output.=&Apache::lc_xml_gadgets::progressbar('modifyuserfinalize','modifyuserfinalize').
                  '<div id="messages"></div>'.
                  '<script>followup=0;showhide();runbackground();</script>';
      } else {
# Just do it, there's only one entry!
         if (&changerecord($modifyusers->[0],\%setfields)) {
            $output.=&Apache::lc_xml_utils::success_message('Success.').
                     '<script>error=0;success=1;followup=0;</script>';
         } else {
            $output.=&Apache::lc_xml_utils::standard_message('Failure.').
                     '<script>error=0;success=0;followup=0;</script>';
         }
      }
   } else {
# We are presenting data
      my $modifyusers;
# Is this just one user or possibly multiple?
      if (($content{'user_username'}=~/\w/) && ($content{'user_domain'}=~/\w/)) {
# Just one
         $modifyusers->[0]->{'username'}=$content{'user_username'};
         $modifyusers->[0]->{'domain'}=$content{'user_domain'};
# This may or may not succeed. For new users, it won't
         $modifyusers->[0]->{'entity'}=&Apache::lc_entity_users::username_to_entity($content{'user_username'},$content{'user_domain'});
      } else {
# Possibly multiple
         $modifyusers=&Apache::lc_json_utils::json_to_perl($content{'postdata'});
      }
# Do we have any data? If not, we have a problem
      if ($modifyusers) {
# Store it
         my ($entity,$domain)=&Apache::lc_entity_sessions::user_entity_domain();
         &Apache::lc_file_utils::writefile(
            &Apache::lc_entity_urls::wrk_to_filepath($domain.'/'.$entity.'/modify_users.json'),
            &Apache::lc_json_utils::perl_to_json($modifyusers));
      } else {
         return '<script>followup=0;error=1;</script>'; 
      }
      my $number=$#{$modifyusers};
      my $locked=1;
      my $profile;
      if ($number==0) {
         if ($modifyusers->[0]->{'entity'}) {
            $profile=&Apache::lc_entity_profile::dump_profile($modifyusers->[0]->{'entity'},
                                                       $modifyusers->[0]->{'domain'});
            $output.=&Apache::lc_xml_utils::standard_message('Existing user [_1]',
                                '<tt>'.$modifyusers->[0]->{'username'}.':'.$modifyusers->[0]->{'domain'}.'</tt>');
            $output.='<br />'.
                     &Apache::lc_xml_utils::standard_message($profile->{'firstname'}.' '.$profile->{'middlename'}.' '.$profile->{'lastname'}.' '.$profile->{'suffix'});
         } else {
            $locked=0;
            $output.=&Apache::lc_xml_utils::standard_message('New user [_1]',
                                '<tt>'.$modifyusers->[0]->{'username'}.':'.$modifyusers->[0]->{'domain'}.'</tt>');
         }
      }
      $output.='<br />'.&Apache::lc_xml_forms::form_table_start();
      if ($number==0) {
# Do we have to enter a name or are we allowed to?
         if ((&allowed_course('modify_name',undef,&Apache::lc_entity_sessions::course_entity_domain())) || 
             (!$modifyusers->[0]->{'entity'})) {
            $output.=&Apache::lc_xml_forms::table_input_field(
                 'firstname','firstname',
                 'First Name',
                 'text',
                 40,
                 $profile->{'firstname'},$locked);
            $output.=&Apache::lc_xml_forms::table_input_field(
                 'middlename','middlename',
                 'Middle Name',
                 'text',
                 40,
                 $profile->{'middlename'},$locked);
            $output.=&Apache::lc_xml_forms::table_input_field(
                 'lastname','lastname',
                 'Last Name',
                 'text',
                 40,
                 $profile->{'lastname'},$locked);
            $output.=&Apache::lc_xml_forms::table_input_field(
                 'suffix','suffix',
                 'Suffix',
                 'text',
                 20,
                 $profile->{'suffix'},$locked);
         }
         if ((&allowed_course('modify_pid',undef,&Apache::lc_entity_sessions::course_entity_domain())) ||
             (!$modifyusers->[0]->{'entity'})) {
            $output.=&Apache::lc_xml_forms::table_input_field(
                 'pid','pid',
                 'ID Number',
                 'text',
                 20,
                 &Apache::lc_entity_users::entity_to_pid($modifyusers->[0]->{'entity'},
                                                       $modifyusers->[0]->{'domain'}),
                 $locked);
          }
# End of only one student
      } else {
          $output.=&Apache::lc_xml_utils::standard_message('[_1] users selected',$number+1).'<br />';
      }
# The following would apply to all students
      if (&allowed_course('modify_auth',undef,&Apache::lc_entity_sessions::course_entity_domain())) {
#FIXME: missing authmode
         $output.=&Apache::lc_xml_forms::table_input_field(
                 'password','password',
                 'Password',
                 'text',
                 20,undef,$locked);
      }
      $output.=&Apache::lc_xml_forms::table_input_field(
                 'startdate','startdate',
                 'Start Date',
                 'datetime',undef,undef,$locked);
      $output.=&Apache::lc_xml_forms::table_input_field(
                 'enddate','enddate',
                 'End Date',
                 'datetime',undef,undef,$locked);
      $output.=&Apache::lc_xml_forms::table_input_field(
                 'role','role',
                 'Role',
                 'modifiablecourseroles',
                 undef,'student',$locked);
      $output.=&Apache::lc_xml_forms::table_input_field(
                 'section','section',
                 'Section/Group',
                 'text',
                 20,undef,$locked);
# End of the form table
      $output.=&Apache::lc_xml_forms::form_table_end().'<script>error=0;followup=1;</script>';
   }
   return $output;
}

sub changerecord {
   my ($userrecord,$setfields)=@_;
# New values override old ones
   foreach my $field ('firstname','middlename','lastname','suffix',
                      'password','role','section','pid','startdate','enddate') {
      if ($setfields->{$field}) {
         $userrecord->{$field}=$setfields->{$field};
      }
   }
   return &Apache::lc_entity_roles::enroll($userrecord,1,1,1);
}

sub handler {
   my $r=shift;
   $r->print(&incl_modify_courseusers_finalize());
   return OK;
}

1;
__END__
