# The LearningOnline Network with CAPA - LON-CAPA
# Numerical response 
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
package Apache::xml_problem_tags::numericalresponse;

use strict;

use aliased 'Apache::math::math_parser::CalcException';
use aliased 'Apache::math::math_parser::ParseException';
use aliased 'Apache::math::math_parser::Parser';
use aliased 'Apache::math::math_parser::ENode';
use aliased 'Apache::math::math_parser::CalcEnv';
use aliased 'Apache::math::math_parser::Quantity';

use Apache::lc_problem_const;

use Try::Tiny;

use Data::Dumper;
use Apache::lc_logs;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_numericalresponse_html  end_numericalresponse_html
                 start_numericalresponse_grade end_numericalresponse_grade 
                 start_numericalhintcondition_html end_numericalhintcondition_html);

sub start_numericalresponse_html {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_asset_xml::init_response($stack);
   return '';
}

sub start_numericalresponse_grade {
   return &start_numericalresponse_html(@_);
}

sub end_numericalresponse_html {
   my ($p,$safe,$stack,$token)=@_;
#FIXME: do stuff
#Debug only here
   my $answers=&Apache::lc_asset_xml::collect_responses($stack);
   return "Get: ".&Apache::lc_asset_xml::cascade_parameter('tol',$stack).'<br /><pre>'.Dumper($stack).'</pre>'.
          '<pre>'.Dumper($answers).'</pre>';
}

sub evaluate_answer {
   my ($stack)=@_;
   my $answer=&Apache::lc_asset_xml::open_tag_attribute('answer',$stack);
   my $expected='';
   my $expected='';
   if (ref($answer) eq 'ARRAY') {
# We have an array or a matrix
      $expected='[';
      if (ref($answer->[0]) eq 'ARRAY') {
         $expected.='[';
         my @rows=();
         foreach my $row (@{$answer}) {
            push(@rows,join(';',@{$row}));
         }
         $expected.=join('];[',@rows);
         $expected.=']';
      } else {
         $expected.=join(';',@{$answer});
      }
      $expected.=']';
   } else {
      $expected=$answer;
   }
   my $unit=&Apache::lc_asset_xml::open_tag_attribute('unit',$stack);
   if ($unit) {
      return $expected.' '.$unit;
   } else {
      return $expected;
   }
}

sub evaluate_responses {
   my ($stack)=@_;
   my $responses=&Apache::lc_asset_xml::collect_responses($stack);
   if ($#{$responses}>0) {
      return '['.join(';',@{$responses}).']';
   } else {
      return $responses->[0];
   }
}


sub end_numericalresponse_grade {
   my ($p,$safe,$stack,$token)=@_;
# Get student-entered answer
   my $responses=&evaluate_responses($stack);
# Get tolerance parameter
   my $tolerance=&Apache::lc_asset_xml::cascade_parameter('tol',$stack);
# Get the correct answer and unit
   my $expected=&evaluate_answer($stack);
# Special mode?
   my $mode=&Apache::lc_asset_xml::open_tag_attribute('mode',$stack);
# Initialize parser
   my $implicit_operators = 1;
   my $unit_mode = 1;
   my $parser = Parser->new($implicit_operators, $unit_mode);
   my $env = CalcEnv->new($unit_mode);
# See if we have custom units
   my $customunits=&Apache::lc_asset_xml::cascade_parameter('customunits',$stack);
   $customunits=~s/\s//gs;
   foreach my $cu (split(/\,/,$customunits)) {
      my ($new_unit,$new_definition)=split(/\=/,$cu);
      $env->setUnit($new_unit,$new_definition);
   }
# Do the actual grading
   my ($outcome,$message)=&answertest($parser,$env,$responses,$expected,$tolerance,$mode);
   &logdebug($outcome.' - '.$message.' - '.$responses.' - '.$expected.' - '.$tolerance.' - '.$mode);
}

sub start_numericalhintcondition_html {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_asset_xml::add_response_hint($stack);
   return '';
}

sub end_numericalhintcondition_html {
   my ($p,$safe,$stack,$token)=@_;
   return '';
}

sub evaluate_in_parser {
   my ($parser,$env,$term)=@_;
   try {
      my $result=$parser->parse($term)->calc($env);
      return(undef,$result);
   } catch {
      if (UNIVERSAL::isa($_,CalcException)) {
         return(&numerical_error(),undef);
      } elsif (UNIVERSAL::isa($_,ParseException)) {
         return(&bad_formula(),undef);
      } else {
         return(&internal_error(),$_);
      }
   }
}

sub value_unit {
   my ($term)=@_;
   my ($termvalue,$termunit)=($term=~/^\s*(\S*)\s*(.*)$/);
   $termunit=~s/^\s+//gs;
   $termunit=~s/\s+$//gs;
   return($termvalue,$termunit);
}

# A numeric comparison of $expression and $expected
#
sub answertest {
    my ($parser,$env,$expression, $expected, $tolerance, $special)=@_;
    if (!defined $tolerance) {
        $tolerance = 1e-5;
    }
    unless ($expression=~/\S/) {
       return(&no_valid_response(),undef);
    }
    unless ($expected=~/\S/) {
       return(&no_valid_answer(),undef);
    }
    if ($special eq 'sets') {
# We are dealing with sets and intervals as answers
    } elsif ($special=~/^(gt|ge|lt|le)$/) {
# Number greater than, less than, etc
# We can only do this for scalars
       if ($expression=~/\;/) {
          return(&response_scalar_required(),undef);
       }
       if ($expected=~/\;/) {
          return(&answer_scalar_required(),undef);
       }
# Evalute both scalars
# Student response
       $expression=~s/[\[\]]//gs;
       my ($responseerror,$response)=&evaluate_in_parser($parser,$env,$expression);
       if ($responseerror) {
          return($responseerror,$response);
       }
       my ($responsevalue,$responseunit)=&value_unit($response);
# Problem answer
       $expected=~s/[\[\]]//gs;
       my ($answererror,$answer)=&evaluate_in_parser($parser,$env,$expected);
       my ($answervalue,$answerunit)=&value_unit($answer);
# If the units do not come out the same, there is a problem
       unless ($responseunit eq $answerunit) {
          return(&wrong_unit_dimension,undef);
       }
# Now it's up to comparing the numerical values
       if ($special eq 'gt') {
          if ($responsevalue>$answervalue) { return(&correct(),undef); }
       }
       if ($special eq 'ge') {
          if ($responsevalue>$answervalue) { return(&correct(),undef); }
       }
       if ($special eq 'lt') {
          if ($responsevalue<$answervalue) { return(&correct(),undef); }
       }
       if ($special eq 'le') {
          if ($responsevalue<=$answervalue) { return(&correct(),undef); }
       }
# Nope
       return(&incorrect(),undef);
    } elsif ($special=~/^(insideopen|outsideopen|insideclosed|outsideclosed)$/) {
# Inside or outside an open or closed interval
    } elsif ($special eq 'or') {
# One of the values in an array
       if ($expression=~/\;/) {
          return(&response_scalar_required(),undef);
       }
# Evaluate the instructor answers, will result in vector
       my ($error,$answers)=&evaluate_in_parser($parser,$env,$expected);
       if ($error) {
          return($error,$answers);
       }
# Split the vector, test each component
       $answers=~s/[\[\]]//gs;
       foreach my $attempt (split(/\;/,$answers)) {
          my ($code,$message)=&answertest($parser,$env,$expression,$attempt,$tolerance);
# If it's not incorrect, return it
          if ($code ne &incorrect()) {
             return($code,$message);
          }
       }
# Nothing found
       return(&incorrect,undef);
    } else {
# We are dealing with scalars or vectors
       try {
          my $expected_quantity = $parser->parse($expected)->calc($env);
          my $input_quantity = $parser->parse($expression)->calc($env);
          my $code = $expected_quantity->compare($input_quantity, $tolerance);
          if ($code == Quantity->IDENTICAL) {
             return(&correct(),undef);
          } elsif ($code == Quantity->WRONG_TYPE) {
             return(&wrong_dimension(),undef);
          } elsif ($code == Quantity->WRONG_DIMENSIONS) {
             return(&wrong_dimension(),undef);
          } elsif ($code == Quantity->MISSING_UNITS) {
             return(&unit_missing(),undef);
          } elsif ($code == Quantity->ADDED_UNITS) {
              return(&no_unit_required(),undef);
          } elsif ($code == Quantity->WRONG_UNITS) {
              return(&wrong_unit_dimension,undef);
          } elsif ($code == Quantity->WRONG_VALUE) {
              return(&incorrect(),undef);
          }
       } catch {
          if (UNIVERSAL::isa($_,CalcException)) {
              return(&numerical_error(),undef);
          } elsif (UNIVERSAL::isa($_,ParseException)) {
              return(&bad_formula(),undef);
          } else {
              return(&internal_error(),$_);
          }
       }
    }
}

1;
__END__
