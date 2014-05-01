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
use Apache::lc_date_utils();
use Apache::lc_entity_sessions();
use Apache::lc_entity_urls();
use Apache::lc_entity_assessments();
use Apache::lc_asset_safeeval();
use Apache::lc_authorize;
use Apache::lc_entity_authentication();
use Apache::lc_spreadsheets();

use Data::Dumper;

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;

   $r->print("Test Handler\n");

   $r->print("\n==========\n".Dumper(&Apache::lc_spreadsheets::parse_spreadsheet('/home/www/Desktop/classlist.xls')));
   $r->print("\n==========\n".Dumper(&Apache::lc_spreadsheets::parse_spreadsheet('/home/www/Desktop/classlist.xlsx')));
   $r->print("\n==========\n".Dumper(&Apache::lc_spreadsheets::parse_spreadsheet('/home/www/Desktop/classlist.csv')));


return OK;

my $date='2015-01-20 04:05:06';

   $r->print($date.' -> '.&Apache::lc_date_utils::num2str(&Apache::lc_date_utils::str2num($date))."\n");

$date='2115-7-20 21:05:06';

   $r->print($date.' -> '.&Apache::lc_date_utils::num2str(&Apache::lc_date_utils::str2num($date))."\n");

my $startdate='2014-04-15 08:00:00';
my $enddate='2014-04-16 01:00:00';

   $r->print("$startdate - $enddate : ".&Apache::lc_date_utils::in_date_range($startdate,$enddate)."\n"); 

my $comparedate='2014-04-16 01:00:01';

   $r->print("$startdate - $enddate - $comparedate: ".&Apache::lc_date_utils::in_date_range($startdate,$enddate,$comparedate)."\n");


   my $entity;
   my $courseentity;

   $r->print(&Apache::lc_entity_users::make_new_user('zaphod','msu')."\n");
   $entity=&Apache::lc_entity_users::username_to_entity('zaphod','msu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'msu')."\n");

   $r->print("Reverse: ".&Apache::lc_entity_users::entity_to_username($entity,'msu')."\n");


   $r->print(&Apache::lc_entity_courses::make_new_course('test205','msu')."\n");
   $courseentity=&Apache::lc_entity_courses::course_to_entity('test205','msu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'msu')."\n");

   $r->print("Reverse: ".&Apache::lc_entity_courses::entity_to_course($courseentity,'msu')."\n");

   $r->print(&Apache::lc_entity_users::assign_pid($entity,'msu','z12345678'));

   $r->print("Forward: ".&Apache::lc_entity_users::pid_to_entity('z12345678','msu')."\n");

   $r->print("Reverse: ".&Apache::lc_entity_users::entity_to_pid($entity,'msu')."\n");


   &Apache::lc_entity_users::set_full_name($entity,'msu',"Zaphod","Klausdieter","Beeblebrox","Sr.");
   &Apache::lc_entity_authentication::set_authentication($entity,'msu',{ mode => 'internal', password => 'zaphodB' });

   $r->print(join(' ',&Apache::lc_entity_users::full_name($entity,'msu'))."\n");

   $r->print("Profile: ".Dumper(&Apache::lc_entity_profile::dump_profile($entity,'msu'))."\n");

   &Apache::lc_entity_courses::set_course_title($courseentity,'msu','Intro Physics 17');
   &Apache::lc_entity_courses::set_course_type($courseentity,'msu','regular');

   $r->print(&Apache::lc_entity_courses::course_title($courseentity,'msu')."\n");
   $r->print(&Apache::lc_entity_courses::course_type($courseentity,'msu')."\n");

   $r->print("Profile: ".Dumper(&Apache::lc_entity_profile::dump_profile($courseentity,'msu'))."\n");

# =====
   $r->print(&Apache::lc_entity_courses::make_new_course('test206','msu')."\n");
   $courseentity=&Apache::lc_entity_courses::course_to_entity('test206','msu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'msu')."\n");

   &Apache::lc_entity_courses::set_course_title($courseentity,'msu','Calculus Based Physics 2014/15');
   &Apache::lc_entity_courses::set_course_type($courseentity,'msu','regular');


   &Apache::lc_entity_roles::modify_role($entity,'msu', # who gets the role?
       'course', # system, domain, course, user
       $courseentity,'msu','007', # what's the realm?
       'instructor', # what role is this?
       '1998-01-08 04:05:06','2015-01-08 04:05:06', # duration
       'ggf21wqffas','msu');

   &Apache::lc_entity_roles::modify_role($entity,'msu', # who gets the role?
       'course', # system, domain, course, user
       $courseentity,'msu','008', # what's the realm?
       'teaching_assistant', # what role is this?
       '1998-01-08 04:05:06','2005-01-08 04:05:06', # duration
       'ggf21wqffas','msu');
# =====
   $r->print(&Apache::lc_entity_courses::make_new_course('test207','msu')."\n");
   $courseentity=&Apache::lc_entity_courses::course_to_entity('test207','msu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'msu')."\n");

   &Apache::lc_entity_courses::set_course_title($courseentity,'msu','Algebra Based Physics 2014/15');
   &Apache::lc_entity_courses::set_course_type($courseentity,'msu','regular');


   &Apache::lc_entity_roles::modify_role($entity,'msu', # who gets the role?
       'course', # system, domain, course, user
       $courseentity,'msu','006', # what's the realm?
       'instructor', # what role is this?
       '1998-01-08 04:05:06','2015-01-08 04:05:06', # duration
       'ggf21wqffas','msu');

   &Apache::lc_entity_roles::modify_role($entity,'msu', # who gets the role?
       'course', # system, domain, course, user
       $courseentity,'msu','010', # what's the realm?
       'teaching_assistant', # what role is this?
       '1998-01-08 04:05:06','2017-01-08 04:05:06', # duration
       'ggf21wqffas','msu');

# =====
   $r->print(&Apache::lc_entity_courses::make_new_course('test208','msu')."\n");
   $courseentity=&Apache::lc_entity_courses::course_to_entity('test208','msu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'msu')."\n");

   &Apache::lc_entity_courses::set_course_title($courseentity,'msu','Underwater Basket Weaving 2014/15');
   &Apache::lc_entity_courses::set_course_type($courseentity,'msu','regular');
   
       
   &Apache::lc_entity_roles::modify_role($entity,'msu', # who gets the role?
       'course', # system, domain, course, user
       $courseentity,'msu',undef, # what's the realm?
       'course_coordinator', # what role is this?
       '1998-01-08 04:05:06','2018-01-08 04:05:06', # duration
       'ggf21wqffas','msu');

# =====

   $r->print(&Apache::lc_entity_courses::make_new_course('test209','msu')."\n");
   $courseentity=&Apache::lc_entity_courses::course_to_entity('test209','msu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'msu')."\n");

   &Apache::lc_entity_courses::set_course_title($courseentity,'msu','Advanced Introductory Special Topics 2014/15');
   &Apache::lc_entity_courses::set_course_type($courseentity,'msu','regular');


   &Apache::lc_entity_roles::modify_role($entity,'msu', # who gets the role?
       'course', # system, domain, course, user
       $courseentity,'msu',undef, # what's the realm?
       'course_coordinator', # what role is this?
       '1998-01-08 04:05:06','2018-01-08 04:05:06', # duration
       'ggf21wqffas','msu');

   &Apache::lc_entity_roles::modify_role($entity,'msu', # who gets the role?
       'course', # system, domain, course, user
       $courseentity,'msu','007', # what's the realm?
       'instructor', # what role is this?
       '1998-01-08 04:05:06','2018-01-08 04:05:06', # duration
       'ggf21wqffas','msu');

   my $arthurentity=&Apache::lc_entity_users::username_to_entity('arthur','msu');

   &Apache::lc_entity_users::set_full_name($arthurentity,'msu',"Arthur","Philip","Dent","17th");


   &Apache::lc_entity_roles::modify_role($arthurentity,'msu', # who gets the role?
       'course', # system, domain, course, user
       $courseentity,'msu','007', # what's the realm?
       'student', # what role is this?
       '1998-01-08 04:05:06','2018-01-08 04:05:06', # duration
       'ggf21wqffas','msu');




# =====

   $r->print(&Apache::lc_entity_courses::make_new_course('test210','msu')."\n");
   $courseentity=&Apache::lc_entity_courses::course_to_entity('test210','msu');
   $r->print(&Apache::lc_entity_utils::homeserver($entity,'msu')."\n");

   &Apache::lc_entity_courses::set_course_title($courseentity,'msu','The greatest committee of all 2014/15');
   &Apache::lc_entity_courses::set_course_type($courseentity,'msu','community');


   &Apache::lc_entity_roles::modify_role($entity,'msu', # who gets the role?
       'course', # system, domain, course, user
       $courseentity,'msu',undef, # what's the realm?
       'member', # what role is this?
       '1998-01-08 04:05:06','2018-01-08 04:05:06', # duration
       'ggf21wqffas','msu');

   $r->print("\nClasslist:\n".Dumper(&Apache::lc_entity_roles::lookup_entity_rolelist($courseentity,'msu'))."\n");


return OK;

   &Apache::lc_entity_roles::modify_role($entity,'msu', # who gets the role?
       'domain', # system, domain, course, user
       undef,'msu',undef, # what's the realm?
       'domain_coordinator', # what role is this?
       '1299-01-08 04:05:06','2016-01-08 04:05:06', # duration
       'qhhhf21wqffas','msu');

  &Apache::lc_entity_roles::modify_role($entity,'msu', # who gets the role?
       'system', # system, domain, course, user
       undef,undef,undef, # what's the realm?
       'superuser', # what role is this?
       '1299-01-08 04:05:06','2016-01-08 04:05:06', # duration
       'qhhhf21wqffas','msu');


   $r->print("All Roles: ".Dumper(&Apache::lc_entity_roles::dump_roles($entity,'msu'))."\n");

   $r->print("Roles: ".Dumper(&Apache::lc_entity_roles::active_roles($entity,'msu'))."\n");


   $r->print(&allowed_domain('modify_role','domain_coordinator','msu')."\n");
   $r->print(&allowed_domain('modify_role','course_coordinator','msu')."\n");
   $r->print(&allowed_domain('modify_role',undef,'msu')."\n");
   $r->print(&allowed_domain('modify_role','superconductor','msu')."\n");



return OK;


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
