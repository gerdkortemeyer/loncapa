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
use Apache::lc_file_utils();
use Apache::lc_entity_sessions();
use Apache::lc_entity_urls();
use Apache::lc_entity_assessments();
use Apache::lc_asset_safeeval();
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

   $r->print(&Apache::lc_entity_courses::make_new_course('test205','msu')."\n");
   $courseentity=&Apache::lc_entity_courses::course_to_entity('test205','msu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'msu')."\n");


   $r->print(">".Dumper(&Apache::lc_entity_courses::load_contents($courseentity,'msu'))."\n");

   $r->print(">".Dumper(&Apache::lc_entity_courses::publish_contents($courseentity,'msu',[42]))."\n");


   $r->print(">".Dumper(&Apache::lc_entity_courses::load_contents($courseentity,'msu'))."\n");

   $r->print("Course: ".join(',',&Apache::lc_entity_sessions::course_entity_domain()));

   &Apache::lc_entity_sessions::enter_course($courseentity,'msu');


   $r->print(">".Dumper(&Apache::lc_entity_assessments::store_assessment(
       $courseentity,'msu',
       'userEN','userDO',
       'theResID','thePartID',
       'abs','1.4',
       '1','1','incorrect','{ color : "green" }')));

   $r->print(">".Dumper(&Apache::lc_entity_assessments::store_assessment(
       $courseentity,'msu',
       'userEN','userDO',
       'theResID','thePartID',
       'abs','1.6',
       '2','1','incorrect','{ color : "red", foo : "bar" }')));

   $r->print(">".Dumper(&Apache::lc_entity_assessments::store_assessment(
       $courseentity,'msu',
       'userEN','userDO',
       'theResID','thePartID',
       'abs','1.8',
       '3','2','incorrect','{ color : "yellow" }')));

   $r->print(">".Dumper(&Apache::lc_entity_assessments::store_assessment(
       $courseentity,'msu',
       'userEN','userDO',
       'theResID','thePartID',
       'abs','1.8',
       '4','2','incorrect','{ foo : "foobar" }')));

   $r->print(">".Dumper(&Apache::lc_entity_assessments::store_assessment(
       $courseentity,'msu',
       'userEN','userDO',
       'theResID','thePartID',
       'abs','2.1',
       '5','2','incorrect','{ color : "blue" }')));



   $r->print(">".Dumper(&Apache::lc_entity_assessments::store_assessment(
       $courseentity,'msu',
       'userEN','userDO',
       'theResID','anotherPartID',
       'abs','1.4',
       '1','1','correct','{ color : "pink" }')));

   $r->print(">".Dumper(&Apache::lc_entity_assessments::store_assessment(
       $courseentity,'msu',
       'userEN','userDO',
       'theResID','anotherPartID',
       'abs','4.4',
       '2','1','correct','{ temperature : "hot" }')));


   $r->print(">".Dumper(&Apache::lc_entity_assessments::get_one_user_assessment(
       $courseentity,'msu',
       'userEN','userDO',
       'theResID')));

   $r->print(">".Dumper(&Apache::lc_entity_assessments::get_all_assessment_performance(
       $courseentity,'msu')));

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



   my $wrk_url='/wrk/msu/'.$entity.'/rqdqweq/fqweqc.html';

   my $url='/asset/-/-/msu/'.$entity.'/rqdqweq/fqweqc.html';
 
   &Apache::lc_entity_urls::transfer_uploaded($url);
   &Apache::lc_entity_urls::save($url);
   &Apache::lc_entity_urls::publish($url);

#
#   &Apache::lc_entity_urls::make_new_url($url);

   my $urlentity=&Apache::lc_entity_urls::url_to_entity($url);


   $r->print("\n=====\n".&Apache::lc_file_utils::readurl($url)."\n=====\n");

   $r->print("\nURL: $url.\nUrlentity: $urlentity");


   $r->print("\n".Dumper(&Apache::lc_entity_urls::dump_metadata($urlentity,'msu')));


   $r->print("\n".Dumper(&Apache::lc_entity_urls::dir_list("msu/".$entity."/rqdqweq")));

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
