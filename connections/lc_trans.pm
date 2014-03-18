# The LearningOnline Network with CAPA - LON-CAPA
#
# URL translation handler
# Handles incoming requests for URLs
# Translates path into entity form, starts replication if necessary
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
use Apache::lc_entity_urls();

sub handler {
    my $r = shift;
# We care about assets
    if ($r->uri=~/^\/asset\//) {
# First check if we can even find this
       my $filepath=&Apache::lc_entity_urls::url_to_filepath($r->uri);
       unless ($filepath) {
# Nope, this does not exist anywhere
          return HTTP_NOT_FOUND;
       }
# Is this locally present?
       unless (-e $filepath) {
# Nope, we don't have it yet, let's try to get it
          unless (&Apache::lc_entity_urls::replicate($r->uri)) {
# Wow, something went wrong, not sure why we can't get it
             return HTTP_SERVICE_UNAVAILABLE; 
          }
       }
# Bend the filepath to point to the asset entity
       $r->filename($filepath);
       return OK;
    } elsif ($r->uri=~/^\/raw\//) {
       $r->filename(&Apache::lc_entity_urls::raw_to_filepath($r->uri));
       return OK;
    } 
# None of our business, no need to translate URL
    return DECLINED; 
}

1;
__END__
