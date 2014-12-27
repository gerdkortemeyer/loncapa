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

use Apache::lc_math_parser();
use Apache::lc_problem_const;
use Apache::xml_problem_tags::hints();

use Apache::lc_logs;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_numericalresponse_html  end_numericalresponse_html
                 start_numericalresponse_grade end_numericalresponse_grade 
                 start_numericalhintcondition_html end_numericalhintcondition_html
                 start_numericalhintcondition_grade end_numericalhintcondition_grade);

#
# Just start the numerical response environment.
# Everything happens at the end tag
#
sub start_numericalresponse_html {
   my ($p,$safe,$stack,$token)=@_;
   return '';
}

sub start_numericalresponse_grade {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_asset_xml::init_response($token->[2]->{'id'},$stack);
}


#
# Output
#
sub end_numericalresponse_html {
   my ($p,$safe,$stack,$token)=@_;
   return '';
}

#
# This evaluates the computer answer
# If an array is passed, it is turned into a string for sets or vectors
# If a string is passed, it is returned
# Units are attached to the end
#
sub evaluate_answer {
   my ($stack,$mode)=@_;
   my $answer=&Apache::lc_asset_xml::open_tag_attribute('answer',$stack);
   my $unit=&Apache::lc_asset_xml::open_tag_attribute('unit',$stack);
   unless ($unit) { $unit=''; }
   my $expected='';
   if (ref($answer) eq 'ARRAY') {
      if ($mode eq 'sets') {
# The array contains elements of a set
         $expected='{'.join(';',@{$answer}).'} '.$unit;
      } elsif ($#{$answer}>0) {
# We have an array or a matrix with more than one element
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
         $expected.='] '.$unit;
      } else {
# We have an array, but it has only one element
         $expected='('.$answer->[0].') '.$unit;
      }
   } else {
# We have a string as answer
     $expected='('.$answer.')'.$unit;
   }
   return $expected;
}

#
# This collects the learner responses
# If there is only one answer field, it is returned
# If there are multiple answer fields, they are concatinated into
# a string for sets or vectors
#
sub evaluate_responses {
   my ($stack,$mode)=@_;
   my $responses=&Apache::lc_asset_xml::collect_response_inputs($stack);
   if ($#{$responses}>0) {
# There was more than one answer field
      if ($mode eq 'sets') {
# Must be elements in a set
         return '{'.join(';',@{$responses}).'}';
      } elsif ($mode eq 'intervals') {
         return join('+',@{$responses});
      } else {
# Just a normal array 
         return '['.join(';',@{$responses}).']';
      }
   } else {
      return $responses->[0];
   }
}

#
# This is where the grading is happening
#
sub end_numericalresponse_grade {
   my ($p,$safe,$stack,$token)=@_;
# ID
   my $id=&Apache::lc_asset_xml::open_tag_attribute('id',$stack);
# Special mode?
   my $mode=&Apache::lc_asset_xml::open_tag_attribute('mode',$stack);
# Get student response
   my $responses=&evaluate_responses($stack,$mode);
# Did we get anything?
   unless ($responses=~/\S/s) {
# Nope? Well, nothing to do here.
      &Apache::lc_asset_xml::add_response_grade($id,&no_valid_response(),undef,undef,$stack);
      return;
   }
# Get tolerance parameter
   my $tolerance=&Apache::lc_asset_xml::cascade_parameter('tol',$stack);
# Or?
   my $or=&Apache::lc_asset_xml::open_tag_switch('or',$stack);
# Get the correct answer and unit
   my $expected=&evaluate_answer($stack,$mode);
# Get custom units 
   my $customunits=&Apache::lc_asset_xml::cascade_parameter('customunits',$stack);
# Get ourselves a numerical parser and environment
   my ($parser,$env)=&Apache::lc_math_parser::new_numerical_parser($customunits);
# Do the actual grading
   my ($outcome,$message)=&answertest($parser,$env,$responses,$expected,$tolerance,$mode,$or);
# Did we have this answer before?
   my $responsedetails=&Apache::lc_asset_xml::get_response_details($id,$stack);
# See if we had this before and came to the same conclusion
   my $previously=0;
   if (ref($responsedetails) eq 'ARRAY') {
      foreach my $previous (@{$responsedetails}) {
         if ($responses eq $previous->{'responses'}) {
# Yes, we had it before. If the author fixed something in the problem,
# we might get a different status this time around.
            if ($outcome eq $previous->{'status'}) {
# Nope, same thing
               $previously=1;
               last;
            }
         }
      }
   }
# Log this
   &Apache::lc_asset_xml::add_response_details($id,
                                               { 'type'        => 'numerical',
                                                 'answer'      => $expected,
                                                 'responses'   => $responses,
                                                 'or'          => $or,
                                                 'tol'         => $tolerance,
                                                 'customunits' => $customunits,
                                                 'mode'        => $mode,
                                                 'status'      => $outcome,
                                                 'message'     => $message},
                                               $stack);
# Put that on the grading stack to look at end_part_grade
   &Apache::lc_asset_xml::add_response_grade($id,$outcome,$message,$previously,$stack);
# Now deal with the numerical hints
   foreach my $hintcondition (@{$stack->{'response_hints'}->{$id}}) {
      unless ($hintcondition->{'name'} eq 'numericalhintcondition') {
#FIXME: better message
         next;
      }
      my ($hout,$hmsg)=&answertest($parser,$env,$responses,$hintcondition->{'args'}->{'expected'},
                                                           $hintcondition->{'parameters'}->{'tol'},
                                                           $hintcondition->{'args'}->{'mode'},
                                                           $hintcondition->{'args'}->{'or'});
&logdebug("Returns [".$hintcondition->{'args'}->{'name'}."]:".$hout);
   }
}

sub start_numericalhintcondition_grade {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_asset_xml::add_response_hint($stack);
   return '';
}

sub end_numericalhintcondition_grade {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_asset_xml::add_response_hint_parameters($stack,'tol');
   &Apache::lc_asset_xml::add_response_hint_attribute($stack,'expected',
                                                      &evaluate_answer($stack,&Apache::lc_asset_xml::open_tag_attribute('mode',$stack)));
   return '';
}

sub start_numericalhintcondition_html {
   return '';
}

sub end_numericalhintcondition_html {
   return '';
}

#
# A numeric comparison of $expression and $expected
#
sub answertest {
    my ($parser,$env,$expression, $expected, $tolerance, $mode, $or)=@_;
# No tolerance? Be absolutely tolerant!
    if (!defined $tolerance) {
        $tolerance = 1e-5;
    }
# Nothing specified? Nothing we can do.
    unless ($expression=~/\S/s) {
       return(&no_valid_response(),undef);
    }
    unless ($expected=~/\S/s) {
       return(&no_valid_answer(),undef);
    }
# Everything is ready now, let's see what we have
    if ($or) {
# Evaluate the instructor answers, will result in vector
       my ($error,$answers)=&Apache::lc_math_parser::evaluate_in_parser($parser,$env,$expected);
       if ($error) {
          return($error,$answers);
       }
# Split the vector, test each component
       $answers=~s/[\[\]]//gs;
       foreach my $attempt (split(/\;/,$answers)) {
          my ($code,$message)=&answertest($parser,$env,$expression,$attempt,$tolerance,$mode);
# If it's not incorrect, return it
          if ($code ne &incorrect()) {
             return($code,$message);
          }
       }
# Nothing found
       return(&incorrect,undef);
    } else {
# There's only one answer
       my ($code,$message)=&Apache::lc_math_parser::compare_in_parser($parser,$env,$expression,$expected,$tolerance,$mode);
       return($code,$message);
    }
}

1;
__END__
