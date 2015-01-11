# The LearningOnline Network with CAPA - LON-CAPA
# Test Module publishing content
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
use Apache::lc_mongodb();
use Apache::lc_entity_namespace();
use Apache::lc_asset_xml();
use Apache::lc_metadata();
use utf8;

use Data::Dumper;

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;

   $r->print("Test Handler Tästing\n\n");

   my $kortemeyer=&Apache::lc_entity_users::username_to_entity('kortemeyer','msu');
   my $phy233b=&Apache::lc_entity_courses::course_to_entity('phy233bss05','msu');
   my $phy234b=&Apache::lc_entity_courses::course_to_entity('phy234bss05','msu');
   $r->print("[$kortemeyer] [$phy233b] [$phy234b]\n");


my $contenttext='';
open(IN,"/home/korte/phy233b.json");
while (my $line=<IN>) {
   $contenttext.=$line;
}
close(IN);

   $r->print('<pre>'.$contenttext.'</pre>');

return OK;

   $r->print(">".Dumper(&Apache::lc_entity_courses::publish_contents($phy233b,'msu',
                                                                     &Apache::lc_json_utils::json_to_perl($contenttext))."\n"));


return OK;

}

1;
__END__
