# The LearningOnline Network with CAPA - LON-CAPA
# Get the results from asyncronous transactions 
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
package Apache::lc_ui_asyncresults;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common);
use Apache::lc_entity_sessions();
use Apache::lc_entity_users();
use Apache::lc_json_utils();
use Apache::lc_logs;
use Apache::lc_authorize;

my $job;

# ==== Main handler
# Just takes the job, remembers it, and says "ok"
# The actual work is done asynchronously
#
sub handler {
# Get request object
   my $r = shift;
   $r->content_type('application/json; charset=utf-8');
   my %content=&Apache::lc_entity_sessions::posted_content();
# The job must include the command and all needed parameters
   $job=undef;
   foreach my $key (keys(%content)) {
      $job->{$key}=$content{$key};
   }
# Did we get anything?
   if ($job->{'command'} eq 'usersearch') {
      if (&allowed_domain('search_users',undef,$job->{'domain'})) {
         $r->print(&Apache::lc_json_utils::perl_to_json(&Apache::lc_entity_users::query_user_profiles_result($job->{'domain'},$job->{'term'}))); 
      } else {
         $r->print('{ "count" : "0" }');
      }
   } elsif ($job->{'command'} eq 'coursesearch') {
      $r->print(&Apache::lc_json_utils::perl_to_json(&Apache::lc_entity_courses::query_course_profiles_result($job->{'domain'},$job->{'term'})));
   } else {
      $r->print('{ "error" : "1"} ');
   }
   return OK;
}

1;
__END__
