# The LearningOnline Network with CAPA - LON-CAPA
# The Cluster Connections Module
# This takes incoming commands and routes them to handlers if allowed
# Except for the cluster table handler (which is special), all other
# requests will go through this module
#
# Routines that need to be called remotely must register with this module
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
package Apache::lc_connection_handle;

use strict;
use Apache2::RequestRec();
use Apache2::RequestIO();
use Apache2::Const qw(:common :http);

use Apache::lc_parameters;
use Apache::lc_json_utils();
use Apache::lc_connection_utils();

use Apache::lc_logs;

# All the handled commands
#
use vars qw($cmds);


# Register a subroutine with the handler
# WARNING: routines registered here can be called remotely
# Arguments:
# - command: what the URL includes
# - permtype: permission type (optional)
# - permargdomain: permission domain argument, to be pulled from JSON (optional)
# - permargentity: permission entity argument, to be pulled from JSON (optional)
# - subptr: pointer to the subroutine
# - args: arguments of subroutine in order, to be pulled out of JSON (optional)
#
sub register {
   my ($command,$permtype,$permargdomain,$permargentity,$subptr,@args)=@_;
   $cmds->{$command}->{'permtype'}=$permtype;
   $cmds->{$command}->{'permargdomain'}=$permargdomain;
   $cmds->{$command}->{'permargentity'}=$permargentity;
   $cmds->{$command}->{'subptr'}=$subptr;
   $cmds->{$command}->{'args'}=\@args;
}


# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
# Requests need to come in as /connection_handle/host/command
# host needs to be the host as which this one is addressed (in case one server serves more than one host; currently not used)
# command is the command which would need to be registered with the register-subroutine
   my $uri=$r->uri;
   $uri=~s/^\/*//;
   $uri=~s/\/+/\//g;
   my (undef,$host,$command)=split(/\//,$uri);
# Does the command even exist?
   if ($cmds->{$command}) {
      no strict 'refs';
# Make sure this is a code reference
      if (ref($cmds->{$command}->{'subptr'}) eq 'CODE') {
# Extract posted data
         my $data=&Apache::lc_json_utils::json_to_perl(&Apache::lc_connection_utils::extract_content($r));
# Stack up the call arguments in the order required
         my @call_args=();
         foreach my $arg (@{$cmds->{$command}->{'args'}}) {
            push(@call_args,$data->{$arg});
         }
# Now call the subroutine with the arguments, send reply
         $r->print(&{$cmds->{$command}->{'subptr'}}(@call_args));
         return OK;
      } else {
         &logerror("Cannot process ($command), subroutine not defined");
         return HTTP_SERVICE_UNAVAILABLE;
      }
      use strict 'refs';
   } else {
      &logwarning("Got unrecognized command ($command)");
      return HTTP_BAD_REQUEST;
   }
}

1;
__END__
