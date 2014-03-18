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

use Data::Dumper;

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;

   $r->print("Test Handler\n");
   my $entity;
   my $courseentity;

   $r->print(&Apache::lc_entity_users::make_new_user('test171','msu')."\n");
   $entity=&Apache::lc_entity_users::username_to_entity('test171','msu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'msu')."\n");

   $r->print(&Apache::lc_entity_courses::make_new_course('test155','msu')."\n");
   $courseentity=&Apache::lc_entity_courses::course_to_entity('test155','msu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'msu')."\n");


   &Apache::lc_entity_roles::modify_role($entity,'msu', # who gets the role?
       'course', # system, domain, course, user
       $courseentity,'msu','31fq', # what's the realm?
       'student', # what role is this?
       '1998-01-08 04:05:06','1929-01-08 04:05:06', # duration
       'ggf21wqffas','msu');

   &Apache::lc_entity_roles::modify_role($entity,'msu', # who gets the role?
       'domain', # system, domain, course, user
       undef,'msu',undef, # what's the realm?
       'domaincoordinator', # what role is this?
       '1299-01-08 04:05:06','1929-01-08 04:05:06', # duration
       'qhhhf21wqffas','msu');

   &Apache::lc_entity_profile::modify_profile($entity,'msu',{ lastname => "Beeblebrox" });

   $r->print(Dumper(&Apache::lc_entity_roles::dump_roles($entity,'msu')));
   $r->print(Dumper(&Apache::lc_entity_profile::dump_profile($entity,'msu')));

   $r->print(":".&Apache::lc_entity_authentication::set_authentication($entity,'msu',{ mode => 'internal', password => 'zaphodB' })."\n");

   my $sessionid=&Apache::lc_entity_sessions::open_session( 'test171','msu','zaphodB' );

   $r->print("Have $sessionid: ".Dumper(&Apache::lc_entity_sessions::dump_session($sessionid))."\n");

   &Apache::lc_entity_sessions::update_session ($sessionid, { color => 'pink', taste => 'sweet' });

   $r->print(Dumper(&Apache::lc_entity_sessions::dump_session($sessionid)));

   $r->print(&Apache::lc_mongodb::close_session($sessionid));

   $r->print(Dumper(&Apache::lc_entity_sessions::dump_session($sessionid)));


   my $wrk_url='/wrk/msu/'.$entity.'/rqdqweq/fqweq.html';

   &Apache::lc_entity_urls::local_publish($wrk_url);   

   my $url='/asset/-/-/msu/'.$entity.'/rqdqweq/fqweq.html';
#
#   &Apache::lc_entity_urls::make_new_url($url);

   my $urlentity=&Apache::lc_entity_urls::url_to_entity($url);

   $r->print("\nURL: $url.\nUrlentity: $urlentity");

   $r->print("\n".Dumper(&Apache::lc_entity_urls::subscriptions($urlentity,'msu')));

   &Apache::lc_entity_urls::remote_notify_subscribed($urlentity,'msu');

return OK;

   $r->print(&Apache::lc_entity_users::make_new_user('test155','msu')."\n");
   $entity=&Apache::lc_entity_users::username_to_entity('test155','msu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'msu')."\n");

   $r->print(&Apache::lc_entity_users::make_new_user('test156','msu')."\n");
   $entity=&Apache::lc_entity_users::username_to_entity('test156','msu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'msu')."\n");

   $r->print(&Apache::lc_entity_users::make_new_user('test157','msu')."\n");
   $entity=&Apache::lc_entity_users::username_to_entity('test157','msu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'msu')."\n");

   $r->print(&Apache::lc_entity_users::make_new_user('test154','sfu')."\n");
   $entity=&Apache::lc_entity_users::username_to_entity('test154','sfu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'sfu')."\n");

   $r->print(&Apache::lc_entity_users::make_new_user('test155','sfu')."\n");
   $entity=&Apache::lc_entity_users::username_to_entity('test155','sfu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'sfu')."\n");

   $r->print(&Apache::lc_entity_users::make_new_user('test156','ostfalia')."\n");
   $entity=&Apache::lc_entity_users::username_to_entity('test156','ostfalia');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'ostfalia')."\n");

   $r->print(&Apache::lc_entity_users::make_new_user('test157','ostfalia')."\n");
   $entity=&Apache::lc_entity_users::username_to_entity('test157','ostfalia');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'ostfalia')."\n");


   $r->print(&Apache::lc_entity_courses::make_new_course('test156','sfu')."\n");
   $entity=&Apache::lc_entity_courses::course_to_entity('test156','sfu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'sfu')."\n");


   return OK;
}

1;
__END__
