# The LearningOnline Network with CAPA - LON-CAPA
# Calls to the math parser 
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
package Apache::lc_math_parser;

use strict;

use aliased 'Apache::math::math_parser::CalcException';
use aliased 'Apache::math::math_parser::ParseException';
use aliased 'Apache::math::math_parser::Parser';
use aliased 'Apache::math::math_parser::ENode';
use aliased 'Apache::math::math_parser::CalcEnv';
use aliased 'Apache::math::math_parser::Quantity';

use Apache::lc_problem_const;

use Try::Tiny;

use Apache::lc_logs;

#
# Generate a numerical parser with
# units and custom units
#
sub new_numerical_parser {
   my ($customunits)=@_;
   my $parser = Parser->new(1,1);
   my $env = CalcEnv->new(1);
   $customunits=~s/\s//gs;
   foreach my $cu (split(/\,/,$customunits)) {
      my ($new_unit,$new_definition)=split(/\=/,$cu);
      $env->setUnit($new_unit,$new_definition);
   }
   return($parser,$env);
}


#
# See if we have an error message
#
sub message {
   my ($message)=@_;
   unless ($message) { return undef; }
   if ($message->can('getLocalizedMessage')) {
      return $message->getLocalizedMessage();
   } else {
      return $message;
   }
}

#
# Evaluate a term in the parser
# Return error code and result
#
sub evaluate_in_parser {
   my ($parser,$env,$term)=@_;
   try {
      my $result=$parser->parse($term)->calc($env);
      return(undef,$result);
   } catch {
      if (UNIVERSAL::isa($_,CalcException)) {
         return(&numerical_error(),&message($_));
      } elsif (UNIVERSAL::isa($_,ParseException)) {
         return(&bad_formula(),&message($_));
      } else {
         return(&internal_error(),&message($_));
      }
   }
}

#
# Compare two terms in the parser
# Return correct or error code and error message
#
sub compare_in_parser {
   my ($parser,$env,$expression, $expected, $tolerance, $mode)=@_;
&logdebug("Compare: Input:[$expression] Answer:[$expected]");
   try {
      my $expected_quantity = $parser->parse($expected)->calc($env);
      my $input_quantity = $parser->parse($expression)->calc($env);
      my $code;
      if ($mode=~/^(ne|gt|ge|lt|le|unordered|contained)$/) {
         if ($mode eq 'ne') {
            $code = $expected_quantity->ne($input_quantity, $tolerance);
         } elsif ($mode eq 'gt') {
            $code = $expected_quantity->gt($input_quantity, $tolerance);
         } elsif ($mode eq 'ge') {
            $code = $expected_quantity->ge($input_quantity, $tolerance);
         } elsif ($mode eq 'lt') {
            $code = $expected_quantity->lt($input_quantity, $tolerance);
         } elsif ($mode eq 'le') {
            $code = $expected_quantity->le($input_quantity, $tolerance);
         } elsif ($mode eq 'unordered') {
            $code = $expected_quantity->compare_unordered($input_quantity, $tolerance);
         } elsif ($mode eq 'contained') {
            $code = $expected_quantity->contains($input_quantity);
         }
         if ($code) {
            return(&correct,undef);
         } else {
            return(&incorrect,undef);
         }
      } else {
# Normal comparison for equality
         $code = $expected_quantity->compare($input_quantity, $tolerance);
         if ($code == Quantity->IDENTICAL) {
            return(&correct(),undef);
         } elsif ($code == Quantity->WRONG_TYPE) {
            return(&wrong_type(),&message($_));
         } elsif ($code == Quantity->WRONG_DIMENSIONS) {
            return(&wrong_dimension(),&message($_));
         } elsif ($code == Quantity->MISSING_UNITS) {
            return(&unit_missing(),&message($_));
         } elsif ($code == Quantity->ADDED_UNITS) {
            return(&no_unit_required(),&message($_));
         } elsif ($code == Quantity->WRONG_UNITS) {
            return(&wrong_unit_dimension,&message($_));
         } elsif ($code == Quantity->WRONG_VALUE) {
            return(&incorrect(),undef);
         }
      }
   } catch {
      if (UNIVERSAL::isa($_,CalcException)) {
          return(&numerical_error(),&message($_));
      } elsif (UNIVERSAL::isa($_,ParseException)) {
          return(&bad_formula(),&message($_));
      } else {
          return(&internal_error(),&message($_));
      }
   }
}

1;
__END__
