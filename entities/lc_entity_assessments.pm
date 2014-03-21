# The LearningOnline Network with CAPA - LON-CAPA
# Deal with everything having to do with assessments
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
package Apache::lc_entity_assessments;

use strict;

use Apache::lc_logs;
use Apache::lc_connection_handle();
use Apache::lc_json_utils();

use Apache::lc_dispatcher();
use Apache::lc_postgresql();
use Apache::lc_entity_utils();
use Apache2::Const qw(:common :http);

sub local_store_assessment {
   return (!(&Apache::lc_postgresql::store_assessment_transaction(@_)<0));
}

sub remote_store_assessment {
   my ($host,
       $courseentity,$coursedomain,
       $userentity,$userdomain,
       $resourceid,
       $partid,
       $scoretype,$score,
       $totaltries,$countedtries,
       $status,
       $responsedetailsjson)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'store_assessment',
       &Apache::lc_json_utils::perl_to_json({'courseentity' => $courseentity, 'coursedomain' => $coursedomain,
                                            'userentity' => $userentity, 'userdomain' => $userdomain,
                                            'resourceid' => $resourceid,
                                            'partid' => $partid,
                                            'scoretype' => $scoretype, 'score' => $score,
                                            'totaltries' => $totaltries, 'countedtries' => $countedtries,
                                            'status' => $status,
                                            'responsedetailsjson' => $responsedetailsjson}));
   if ($code eq HTTP_OK) {
      return $response;
   } else {
      return undef;
   }
}

sub store_assessment {
   my ($courseentity,$coursedomain,
       $userentity,$userdomain,
       $resourceid,
       $partid,
       $scoretype,$score,
       $totaltries,$countedtries,
       $status,
       $responsedetailsjson)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($courseentity,$coursedomain)) {
      return &local_store_assessment($courseentity,$coursedomain,
                                     $userentity,$userdomain,
                                     $resourceid,
                                     $partid,
                                     $scoretype,$score,
                                     $totaltries,$countedtries,
                                     $status,
                                     $responsedetailsjson);
   } else {
      return &remote_store_assessment(&Apache::lc_entity_utils::homeserver($courseentity,$coursedomain),
                                     $courseentity,$coursedomain,
                                     $userentity,$userdomain,
                                     $resourceid,
                                     $partid,
                                     $scoretype,$score,
                                     $totaltries,$countedtries,
                                     $status,
                                     $responsedetailsjson);
   }
}

#
# Assessment data from one asset
#
sub local_get_one_user_assessment {
   return &Apache::lc_postgresql::get_one_user_assessment(@_);
}

sub local_json_get_one_user_assessment {
   return &Apache::lc_json_utils::perl_to_json(&local_get_one_user_assessment(@_));
}

sub remote_get_one_user_assessment {
   my($host,
      $courseentity,$coursedomain,
      $userentity,$userdomain,
      $resourceid)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'get_one_user_assessment',
       &Apache::lc_json_utils::perl_to_json({'courseentity' => $courseentity, 'coursedomain' => $coursedomain,
                                            'userentity' => $userentity, 'userdomain' => $userdomain,
                                            'resourceid' => $resourceid}));
   if ($code eq HTTP_OK) {
      return &Apache::lc_json_utils::json_to_perl($response);
   } else {
      return undef;
   }
}

sub get_one_user_assessment {
   my ($courseentity,$coursedomain,
       $userentity,$userdomain,
       $resourceid,
       $partid)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($courseentity,$coursedomain)) {
      return &local_get_one_user_assessment($courseentity,$coursedomain,
                                     $userentity,$userdomain,
                                     $resourceid);
   } else {
      return &remote_get_one_user_assessment(&Apache::lc_entity_utils::homeserver($courseentity,$coursedomain),
                                     $courseentity,$coursedomain,
                                     $userentity,$userdomain,
                                     $resourceid);
   }
}

#
# Get data for all course assessments
#
sub local_get_all_assessment_performance {
   return &Apache::lc_postgresql::get_all_assessment_performance(@_);
}

sub local_json_get_all_assessment_performance {
   return &Apache::lc_json_utils::perl_to_json(&local_get_all_assessment_performance(@_));
}

sub remote_get_all_assessment_performance {
   my($host,
      $courseentity,$coursedomain)=@_;
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'get_all_assessment_performance',
       &Apache::lc_json_utils::perl_to_json({'courseentity' => $courseentity, 'coursedomain' => $coursedomain}));
   if ($code eq HTTP_OK) {
      return &Apache::lc_json_utils::json_to_perl($response);
   } else {
      return undef;
   }
}

sub get_all_assessment_performance {
   my ($courseentity,$coursedomain)=@_;
   if (&Apache::lc_entity_utils::we_are_homeserver($courseentity,$coursedomain)) {
      return &local_get_all_assessment_performance($courseentity,$coursedomain);
   } else {
      return &remote_get_all_assessment_performance(&Apache::lc_entity_utils::homeserver($courseentity,$coursedomain),
                                     $courseentity,$coursedomain);
   }
}


BEGIN {
   &Apache::lc_connection_handle::register('store_assessment',undef,undef,undef,\&local_store_assessment,
                                           'courseentity','coursedomain','userentity','userdomain','resourceid','partid',
                                           'scoretype','score','totaltries','countedtries','status','responsedetailsjson');
   &Apache::lc_connection_handle::register('get_one_user_assessment',undef,undef,undef,\&local_json_get_one_user_assessment,
                                           'courseentity','coursedomain','userentity','userdomain','resourceid');
   &Apache::lc_connection_handle::register('get_all_assessment_performance',undef,undef,undef,\&local_json_get_all_assessment_performance,
                                           'courseentity','coursedomain');

}

1;
__END__
