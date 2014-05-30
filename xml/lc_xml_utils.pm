# The LearningOnline Network with CAPA - LON-CAPA
# Same useful tags
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
package Apache::lc_xml_utils;

use strict;
use Apache::lc_ui_localize;
use HTML::Entities();

# Produces an error message with the right style and localization
#
sub error_message {
   my ($message)=@_;
   return '<span class="lcerror">'.&mt($message).'</span>';
}

# Produces the less severe problem message
#
sub problem_message {
   my ($message)=@_;
   return '<span class="lcproblem">'.&mt($message).'</span>';
}

# Escape characters for use in a web form or query string
#
sub form_escape {
   return &HTML::Entities::encode_entities(@_[0]);
}
   
1;
__END__
