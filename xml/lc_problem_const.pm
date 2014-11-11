# The LearningOnline Network with CAPA - LON-CAPA
# Define the constants for problem outcomes
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
package Apache::lc_problem_const;

use strict;
use Apache2::RequestRec();
use Apache2::RequestIO();
use Apache2::Const qw(:common);

require Exporter;
our @ISA = qw (Exporter);
our @EXPORT = qw(correct incorrect numerical_error bad_formula wrong_dimension no_unit_required unit_missing wrong_unit_dimension no_valid_answer no_valid_response internal_error);

sub correct {
   return 'correct';
}

sub incorrect {
   return 'incorrect';
}

sub numerical_error {
   return 'numerical_error';
}

sub bad_formula {
   return 'bad_formula';
}

sub unit_missing {
   return 'unit_missing';
}

sub no_unit_required {
   return 'no_unit_required';
}

sub wrong_unit_dimension {
   return 'wrong_unit_dimension';
}

sub no_valid_answer {
   return 'no_valid_answer';
}

sub no_valid_response {
   return 'no_valid_response';
}

sub internal_error {
   return 'internal_error';
}

sub wrong_dimension {
   return 'wrong_dimension';
}

sub tries_charged {
   my ($code)=@_;
   if (($code eq &correct()) || ($code eq &incorrect())) {
      return 1;
   }
   return 0; 
}

sub get_credit {
   my ($code)=@_;
   if ($code eq &correct()) { return 1; }
   return 0;
}

1;
__END__
