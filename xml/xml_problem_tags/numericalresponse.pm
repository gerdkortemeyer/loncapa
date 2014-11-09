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
   my ($outcome,$message)=&answertest($parser,$env,$responses,$expected,$tolerance);
   &logdebug($outcome.' - '.$message.' - '.$responses.' - '.$expected.' - '.$tolerance);
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


# A numeric comparison of $expression and $expected
#
sub answertest {
    my ($parser,$env,$expression, $expected, $tolerance, $special)=@_;
    if (!defined $tolerance) {
        $tolerance = 1e-5;
    }
    unless ($expression=~/\S/) {
       return(&no_response(),undef);
    }
    unless ($expected=~/\S/) {
       return(&no_answer(),undef);
    }
    if ($special eq 'sets') {
# We are dealing with sets and intervals as answers
    } elsif ($special=~/(gt|ge|lt|le)/) {
# Number greater than, less than, etc
    } elsif ($special=~/(inside|outside)/) {
# Inside or outside an interval
    
    } else {
# We are dealing with scalars or vectors
# Do the dimensions fit?
       my $num1;
       my $num2;
       $num1++ while ($expression =~ m/;/g);
       $num2++ while ($expected =~ m/;/g);
       if ($num1!=$num2) {
          return(&wrong_dimension(),undef);
       }
       try {
           my $quantity = $parser->parse($expression)->calc($env);
           my $expected_quantity = $parser->parse($expected)->calc($env);
           if (!$quantity->equals($expected_quantity, $tolerance)) {
               return(&incorrect(),undef);
           }
           return(&correct(),undef);
       } catch {
           if (UNIVERSAL::isa($_,CalcException) || UNIVERSAL::isa($_,ParseException)) {
               return(&could_not_evaluate(),$_->getLocalizedMessage());
           } else {
               return(&internal_error(),$_);
           }
       }
    }
}

1;
__END__
