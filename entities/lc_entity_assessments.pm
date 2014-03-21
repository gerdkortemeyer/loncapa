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

BEGIN {
   &Apache::lc_connection_handle::register('store_assessment',undef,undef,undef,\&local_store_assessment,
                                           'courseentity','coursedomain','userentity','userdomain','resourceid','partid',
                                           'scoretype','score','totaltries','countedtries','status','responsedetailsjson');
}

1;
__END__
