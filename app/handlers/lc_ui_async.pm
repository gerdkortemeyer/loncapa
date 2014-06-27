# The LearningOnline Network with CAPA - LON-CAPA
# Start asyncronous transactions 
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
package Apache::lc_ui_async;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common);
use Apache::lc_entity_sessions();

use Apache::lc_logs;

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
   if ($job->{'command'}) {
      $r->print("ok");
   } else {
      $r->print("error");
   }
   return OK;
}

# === The commands
#
sub usersearch {
   my ($term)=@_;
   &logdebug("Got search term $term");
}

#
# ==== The actual business logic
# This gets called as a cleanup action, so it will run in the background
#
sub main_actions {
# Pick up the job ticket and see if we can do it
   if ($job->{'command'} eq 'usersearch') {
      &usersearch($job->{'term'});
   } else {
      &logwarning("Unknown asynchronous job command: [".$job->{'command'}."]");
   }
}



1;
__END__
