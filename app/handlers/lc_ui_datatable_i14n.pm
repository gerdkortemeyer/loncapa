# The LearningOnline Network with CAPA - LON-CAPA
# JSON for the internationalization of data tables
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
package Apache::lc_ui_datatable_i14n;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common);

use Apache::lc_ui_localize;
use Apache::lc_json_utils();

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
   $r->content_type('application/json; charset=utf-8');
   my $items={
    "sEmptyTable"    => &mt("No data available in table"),
    "sInfo"          => &mt("Showing [_1] to [_2] of [_3] entries",'_START_','_END_','_TOTAL_'),
    "sInfoEmpty"     => &mt("Showing 0 to 0 of 0 entries"),
    "sInfoFiltered"  => &mt("(filtered from [_1] total entries)",'_MAX_'),
    "sInfoPostFix"   => "",
    "sInfoThousands" => &mt(","),
    "sLengthMenu"    => &mt("Show [_1] entries",'_MENU_'),
    "sLoadingRecords"=> &mt("Loading..."),
    "sProcessing"    => &mt("Processing..."),
    "sSearch"        => &mt("Search:"),
    "sZeroRecords"   => &mt("No matching records found"),
    "oPaginate" => {
        "sFirst"    => &mt("First"),
        "sLast"     => &mt("Last"),
        "sNext"     => &mt("Next"),
        "sPrevious" => &mt("Previous")
                   },
    "oAria" => {
        "sSortAscending"  => &mt(": activate to sort column ascending"),
        "sSortDescending" => &mt(": activate to sort column descending")
               }
   };
   $r->print(&Apache::lc_json_utils::perl_to_json($items));
   return OK;
}
1;
__END__
