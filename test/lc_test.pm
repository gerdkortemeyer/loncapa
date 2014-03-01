# The LearningOnline Network with CAPA - LON-CAPA
# Test Module
# $Id: lc_test.pm,v 1.3 2014/02/14 13:17:12 www Exp $
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
package Apache::lc_test;

use strict;
use Apache2::RequestRec();
use Apache2::RequestIO();
use Apache2::Const qw(:common);

use Apache::lc_parameters;
use Apache::lc_connections();
use Apache::lc_connection_utils();
use Apache::lc_postgresql;

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;

   $r->print("Test Handler\n");

   &Apache::lc_postgresql::insert_url("msu/kortemey/testing/test.html","abcdef");
   $r->print("result:".&Apache::lc_postgresql::lookup_url_entity("msu/kortemey/testing/test.html")."\n");

   &Apache::lc_postgresql::insert_pid("a31412414","msu","cdefgh");

   &Apache::lc_postgresql::insert_username("kortemey","msu","dhrqfq");
   $r->print("result:".&Apache::lc_postgresql::lookup_username_entity("kortemey","msu")."\n");

   &Apache::lc_postgresql::insert_course("phy231c","msu","fasfhae");
   $r->print("result:".&Apache::lc_postgresql::lookup_course_entity("phy231c","msu")."\n");

   &Apache::lc_postgresql::insert_homeserver("abcdef","msu","lc1");
 
   return OK;
}

1;
__END__
