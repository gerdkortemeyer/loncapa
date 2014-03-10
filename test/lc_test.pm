# The LearningOnline Network with CAPA - LON-CAPA
# Test Module
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
use Apache::lc_entity_users();
use Apache::lc_entity_utils();

use Apache::lc_mongodb();

use Data::Dumper;

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;

   $r->print("Test Handler\n");
# Never do this in real life!
#
   $r->print("\nCleaning up\n");

   $Apache::lc_mongodb::roles->remove();
   $r->print("\nInsert roles\n");

   $r->print(Dumper(&Apache::lc_mongodb::insert_roles('test123','msu',{ 'course' => 13 })));
   $r->print("\nDump\n");
   $r->print(Dumper(&Apache::lc_mongodb::dump_roles('test123','msu')));

   $r->print("\nUpdate roles\n");
   $r->print(Dumper(&Apache::lc_mongodb::update_roles('test123','msu',{ 'test' => { 'courseentity' => '456', 'coursedomain' => 'msu' }}))."\n");
   $r->print("\nLook again, dump\n");
   $r->print(Dumper(&Apache::lc_mongodb::dump_roles('test123','msu')));

   $r->print("\nCleaning up\n");

   $Apache::lc_mongodb::profiles->remove();
   $r->print("\nInsert profile\n");

   $r->print(Dumper(&Apache::lc_mongodb::insert_profile('test123','msu',{ 'name' => 'Zaphod' })));
   $r->print("\nDump\n");
   $r->print(Dumper(&Apache::lc_mongodb::dump_profile('test123','msu')));

   $r->print("\nUpdate roles\n");
   $r->print(Dumper(&Apache::lc_mongodb::update_profile('test123','msu',{ 'test' => { 'status' => 'epic', 'stuff' => 'green' }}))."\n");
   $r->print("\nLook again, dump\n");
   $r->print(Dumper(&Apache::lc_mongodb::dump_profile('test123','msu')));

   



   return OK;
}

1;
__END__
