# The LearningOnline Network with CAPA - LON-CAPA
# XML Localization Module
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
package Apache::lc_xml_localize;

use strict;
use Apache::lc_ui_localize;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_localize_html start_localize_tex);

sub start_localize_html {
   my ($p,$safe,$stack,$token)=@_;
   my $text=$p->get_text('/localize');
   $p->get_token;
   pop(@{$stack->{'tags'}});
   return &mt($text,
              split(/\s*\,\s*/,&Apache::lc_asset_safeeval::texteval($safe,$token->[2]->{'parameters'})));
}

sub start_localize_tex {
   my ($p,$safe,$stack,$token)=@_;
   return &mt($p->get_text('/localize'),
              split(/\s*\,\s*/,&Apache::lc_asset_safeeval::texteval($safe,$token->[2]->{'parameters'})));
}

1;
__END__
