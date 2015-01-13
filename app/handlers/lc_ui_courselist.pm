# The LearningOnline Network with CAPA - LON-CAPA
# Serves up various elements of the portfolio page
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
package Apache::lc_ui_courselist;

use strict;
use Apache2::Const qw(:common);
use Apache::lc_entity_courses();
use Apache::lc_entity_users();
use Apache::lc_entity_roles();
use Apache::lc_ui_localize;
use Apache::lc_ui_utils;
use Apache::lc_json_utils();
use Apache::lc_entity_urls();
use Apache::lc_entity_sessions();
use Apache::lc_entity_profile();
use Apache::lc_date_utils();
use Apache::lc_authorize;
use Apache::lc_xml_forms();
use Apache::lc_logs;
use Data::Dumper;


# Returns an array of the fields for one record
sub record_output {
  my $record = shift;
# Only show the roles that we are allowed to see
  unless (&allowed_section('view_role',$record->{'role'},&Apache::lc_entity_sessions::course_entity_domain(),$record->{'section'})) {
    return undef;
  }
# Translate date format for localized viewing and sorting
  my $display_startdate;
  my $sort_startdate;
  if ($record->{'startdate'}) {
          ($display_startdate,$sort_startdate)=&Apache::lc_ui_localize::locallocaltime(
                                        &Apache::lc_date_utils::str2num($record->{'startdate'}));
  } else {
          $display_startdate=&mt('Never');
          $sort_startdate=0;
  }
  my $display_enddate;
  my $sort_enddate;
  if ($record->{'enddate'}) {
          ($display_enddate,$sort_enddate)=&Apache::lc_ui_localize::locallocaltime(
                                        &Apache::lc_date_utils::str2num($record->{'enddate'}));
  } else {
      $display_enddate=&mt('Never');
      $sort_enddate=0;
  }
# Figure out who put this role into the classlist, and if it will be automatically maintained
  my $enrollment_mode;
  my $enrolling_user;
  if (($record->{'manualenrollentity'}) && ($record->{'manualenrolldomain'})) {
      $enrollment_mode=&mt('Manual');
      my ($firstname,$middlename,$lastname,$suffix)=&Apache::lc_entity_users::full_name($record->{'manualenrollentity'},$record->{'manualenrolldomain'});
      $enrolling_user=$firstname.' '.$lastname;
  } else {
      $enrollment_mode=&mt('Automatic');
      $enrolling_user='';
  }
# What is the status of the role? Active now?
  my $active_status;
  my $status_code=&Apache::lc_date_utils::status_date_range($sort_startdate,$sort_enddate);
  if ($status_code eq 'active') {
      $active_status=&mt('Active');
  } elsif ($status_code eq 'future') {
      $active_status=&mt('Future');
  } else {
      $active_status=&mt('Past');
  }
# Return an array of the fields
  return([ &Apache::lc_json_utils::perl_to_json({entity => $record->{'entity'}, domain => $record->{'domain'}}),
# removed so that we can use entity,domain as a unique id       role => $record->{'role'}, section => $record->{'section'}}),
          $record->{'firstname'},
          $record->{'middlename'},
          $record->{'lastname'},
          $record->{'suffix'},
          $record->{'username'},
          $record->{'domain'},
          $record->{'pid'},
          $record->{'role'} ? &Apache::lc_entity_roles::plaintext($record->{'role'}) : '',
          $record->{'section'},
          ($sort_startdate?'<time datetime="'.$sort_startdate.'">':'').
            $display_startdate.($sort_startdate?'</time>':''),
          $sort_startdate,
          ($sort_enddate?'<time datetime="'.$sort_enddate.'">':'').
            $display_enddate.($sort_enddate?'</time>':''),
          $sort_enddate,
          $enrollment_mode,
          $enrolling_user,
          $active_status
        ]);
}

#
# Returns a JSON string with all course/community participants, in the aaData property
#
sub json_courselist {
  my $output;
  $output->{'aaData'}=[];
  my @courselist=&Apache::lc_entity_courses::courselist(&Apache::lc_entity_sessions::course_entity_domain());
  foreach my $record (@courselist) {
    my $fields = record_output($record);
    if (!defined $fields) {
      next;
    }
    push(@{$output->{'aaData'}}, $fields);
  }
  return &Apache::lc_json_utils::perl_to_json($output);
}

# Returns a JSON string with a list of the selected users
# @param {Array<Hash<string,string>>} users - list of user identifications (entity, domain, role, section)
sub json_selection {
  my $users = shift;
  
  my $output = [];
  my @courselist = &Apache::lc_entity_courses::courselist(&Apache::lc_entity_sessions::course_entity_domain());
  # NOTE: this is not efficient, getting the right records from a list of entities would be better
  foreach my $user (@{$users}) {
    foreach my $record (@courselist) {
      if ($user->{'entity'} eq $record->{'entity'} && $user->{'domain'} eq $record->{'domain'}) {
        my $fields = record_output($record);
        if (!defined $fields) {
          next;
        }
        push(@{$output}, $fields);
        last;
      }
    }
  }
  return &Apache::lc_json_utils::perl_to_json($output);
}


sub handler {
  my $r = shift;
  $r->content_type('application/json; charset=utf-8');
  unless (&allowed_course('view_role',undef,&Apache::lc_entity_sessions::course_entity_domain())) { $r-print('[]'); return OK; }
  my %content = &Apache::lc_entity_sessions::posted_content();
  if ($content{'postdata'}) {
    my $users = &Apache::lc_json_utils::json_to_perl($content{'postdata'});
    $r->print(&json_selection($users));
  } else {
    $r->print(&json_courselist());
  }
  return OK;
}

1;
__END__

