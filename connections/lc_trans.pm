# The LearningOnline Network with CAPA - LON-CAPA
#
# URL translation handler
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
package Apache::lc_trans;

use strict;
use Apache2::RequestRec();
use Apache2::RequestIO();
use Apache2::Const qw(:common :http);


sub handler {
    my $r = shift;
#    if ($r->uri=~/^\/(asset|local_asset_entity)\/([^\/]+)\/([^\/]+)\/([^\/]+)\/(.+)$/) {
#       my $type=$1;
#       my $version_type=$2;
#       my $version_arg=$3;
#       my $domain=$4;
#       my $path=$5;
#       my $found;
# Assets need to be translated to entities
#       if ($type eq 'asset') {
# Before we go out to the net, let's see if we already know locally
#          $found=&Apache::cw_core_entity::local_uri_to_entity('asset',$domain,$path);
#          unless ($found) {
# Out to the net we go!
#             $found=&Apache::cw_core_entity::uri_to_entity('asset',$domain,
#                          &Apache::cw_core_utils::escape($path));
#          }
#       } else {
# local_asset_entity does not to be translated
#          $found=$path;
#       }
#       unless ($found) { return HTTP_NOT_FOUND; }
#       my $filepath=&Apache::cw_core_asset::entity_to_filepath($domain,$found,$version_type,$version_arg);
# Is this locally present?
#       unless (-e $filepath) {
#          if ($type eq 'asset') {
# Try to replicate an asset if needed
#             unless (&Apache::cw_core_asset::replicate($domain,$found,$version_type,$version_arg)) { 
#                return HTTP_NOT_FOUND; 
#             }
#          } else {
# local_asset: hopeless if not present
#             return HTTP_NOT_FOUND;
#          }
#       }
#       $r->filename($filepath);
#    } else { 
# None of our business
      return DECLINED; 
#    }
#    return OK;
}

1;
__END__
