# The LearningOnline Network with CAPA - LON-CAPA
# Parameters
# $Id: lc_parameters.pm,v 1.1 2014/02/13 20:14:06 www Exp $
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
package Apache::lc_parameters;

use strict;
use Apache2::RequestRec();
use Apache2::RequestIO();
use Apache2::Const qw(:common);

require Exporter;
our @ISA = qw (Exporter);
our @EXPORT = qw(lc_home_dir lc_certs_dir);

sub version {
   return q$Id: lc_parameters.pm,v 1.1 2014/02/13 20:14:06 www Exp $;
}

sub lc_home_dir {
   return '/home/loncapa/';
}

sub lc_certs_dir {
   return '/home/loncapa/certs/';
}

1;
__END__
