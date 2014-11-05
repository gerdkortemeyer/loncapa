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

use Try::Tiny;

use Data::Dumper;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_numericalresponse_html end_numericalresponse_html
                 end_numericalresponse_grade 
                 start_numericalhintcondition_html end_numericalhintcondition_html);

sub start_numericalresponse_html {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_asset_xml::init_response($stack);
   return '';
}

sub end_numericalresponse_html {
   my ($p,$safe,$stack,$token)=@_;
#FIXME: do stuff
   my $answers=&Apache::lc_asset_xml::collect_responses($stack);
   return "Get: ".&Apache::lc_asset_xml::cascade_parameter('tol',$stack).'<br /><pre>'.Dumper($stack).'</pre>'.
          '<pre>'.Dumper($answers).'</pre>';
}

sub end_numericalresponse_grade {
   my ($p,$safe,$stack,$token)=@_;
# Get student-entered answer
   my $answers=&Apache::lc_asset_xml::collect_responses($stack);
# Get tolerance parameter
   my $tolerance=&Apache::lc_asset_xml::cascade_parameter('tol',$stack);
# Get the correct answer and unit
#FIXME: could be array
   my $answer=&Apache::lc_asset_xml::open_tag_attribute('answer',$stack);
   my $unit=&Apache::lc_asset_xml::open_tag_attribute('unit',$stack);
   my $expected=$answer.' '.$unit;
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
#FIXME: could be multiple answers
use Apache::lc_logs;
   &logdebug("Grading: ".$answers->[0]);
   &logdebug('Grading target '.&answertest($parser,$env,$answers->[0],$expected,$tolerance));
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

sub answertest {
    my ($parser,$env,$expression, $expected, $tolerance)=@_;
    if (!defined $tolerance) {
        $tolerance = 1e-5;
    } 
    try {
        my $quantity = $parser->parse($expression)->calc($env);
        my $expected_quantity = $parser->parse($expected)->calc($env);
        if (!$quantity->equals($expected_quantity, $tolerance)) {
            return "Wrong result: ".$quantity." instead of ".$expected_quantity." within ".$tolerance;
        }
        return "CORRECT: ".$quantity." is ".$expected_quantity." within ".$tolerance;
    } catch {
        if (UNIVERSAL::isa($_,CalcException) || UNIVERSAL::isa($_,ParseException)) {
            return "Error for $expression: ".$_->getLocalizedMessage();
        } else {
            return "Internal error for $expression: $_";
        }
    }
}

1;
__END__
