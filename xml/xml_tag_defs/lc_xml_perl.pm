# The LearningOnline Network with CAPA - LON-CAPA
# Implements the <perl>-block
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
package Apache::lc_xml_perl;

use strict;
use Apache::lc_asset_safeeval;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_perl_html start_perl_tex);

sub start_perl_html {
   return &perl_eval(@_);
}

sub start_perl_tex {
   return &perl_eval(@_);
}

sub perl_eval {
   my ($p,$safe,$stack,$token)=@_;
   my $text=$p->get_text('/perl');
   $p->get_token;
   pop(@{$stack->{'tags'}});
   &Apache::lc_asset_safeeval::codeeval($safe,$text);
   return '';
}



1;
__END__
