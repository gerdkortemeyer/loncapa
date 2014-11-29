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

#
# Just start the numerical response environment.
# Everything happens at the end tag
#
sub start_numericalresponse_html {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_asset_xml::init_response($stack);
   return '';
}

sub start_numericalresponse_grade {
   return &start_numericalresponse_html(@_);
}


#
# Output
#
sub end_numericalresponse_html {
   my ($p,$safe,$stack,$token)=@_;
#FIXME: do stuff
#Debug only here
   my $answers=&Apache::lc_asset_xml::collect_responses($stack);
   return "Get: ".&Apache::lc_asset_xml::cascade_parameter('tol',$stack).'<br /><pre>'.Dumper($stack).'</pre>'.
          '<pre>'.Dumper($answers).'</pre>';
}

#
# This evaluates the computer answer
# If an array is passed, it is turned into a string for sets or vectors
# If a string is passed, it is returned
# Units are attached to the end
#
sub evaluate_answer {
   my ($stack,$special)=@_;
   my $answer=&Apache::lc_asset_xml::open_tag_attribute('answer',$stack);
   my $expected='';
   my $expected='';
   if (ref($answer) eq 'ARRAY') {
      if ($special eq 'sets') {
# The array contains elements of a set
         $expected='{'.join(';',@{$answer}).'}';
      } else {
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
      }
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

#
# This collects the learner responses
# If there is only one answer field, it is returned
# If there are multiple answer fields, they are concatinated into
# a string for sets or vectors
#
sub evaluate_responses {
   my ($stack,$special)=@_;
   my $responses=&Apache::lc_asset_xml::collect_responses($stack);
   if ($#{$responses}>0) {
# There was more than one answer field
      if ($special eq 'sets') {
# Must be elements in a set
         return '{'.join(';',@{$responses}).'}';
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
# Get tolerance parameter
   my $tolerance=&Apache::lc_asset_xml::cascade_parameter('tol',$stack);
# Special mode?
   my $mode=&Apache::lc_asset_xml::open_tag_attribute('mode',$stack);
# Get the correct answer and unit
   my $expected=&evaluate_answer($stack,$mode);
# Get student-entered answer
   my $responses=&evaluate_responses($stack,$mode);
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

sub evaluate_intervals {
   my ($parser,$env,$term)=@_;
# Turn the sequence of intervals into a vector of vectors ("matrix"),
# so we can evaluate units, etc.
   my $vector=$term;
   $vector=~s/\(/\[/gs;
   $vector=~s/\)/\]/gs;
   $vector=~s/\s*u\s*/\;/gs;
   unless ($vector=~/^\[\[/) {
      $vector='['.$vector;
      $vector=~s/([\)\]])([^\)\]]+)$/$1\]$2/s;
   }
# See if this works
   my ($vectorerror,$vector)=&evaluate_in_parser($parser,$env,$vector);
   if ($vectorerror) {
      return($vectorerror,undef,undef);
   }
# Now we have an evaluated vector of vectors and the original
   $vector=~s/^\[//;
   $vector=~s/\]$//;
   $term=~s/^\[//;
   $term=~s/\]$//;
# Split into chunks - should get the same number of chunks
   my @vectorchunks=split(/\s*\;\s*/,$vector);
   my @termchunks=split(/\s*[u\;]\s*/,$term);
   my @intervals;
   for (my $i=0; $i<$#vectorchunks; $i+=2) {
       &logdebug("Start: ".$vectorchunks[$i].' - '.$termchunks[$i]);
       &logdebug("End: ".$vectorchunks[$i+1].' - '.$termchunks[$i+1]);
       $vectorchunks[$i]=~s/^\s*\[\s*//s;
       $vectorchunks[$i+1]=~s/\s*\]\s*$//s;
       my ($lowervalue,$lowerunit)=&value_unit($vectorchunks[$i]);
       my ($uppervalue,$upperunit)=&value_unit($vectorchunks[$i+1]);
       if ($lowerunit ne $upperunit) {
          return(&wrong_unit_dimension,undef);
       }
       if ($lowervalue>$uppervalue) {
          return(&bad_formula,undef);
       }
       my $lefttype;
       if ($termchunks[$i]=~/\(/) {
          $lefttype='open';
       } elsif ($termchunks[$i]=~/\[/) {
          $lefttype='closed';
       }
       unless ($lefttype) {
          return(&bad_formula,undef);
       }
       my $righttype;
       if ($termchunks[$i+1]=~/\)/) {
          $righttype='open';
       } elsif ($termchunks[$i+1]=~/\]/) {
          $righttype='closed';
       }
       unless ($righttype) {
          return(&bad_formula,undef);
       }
       push(@intervals,{ 'leftvalue' => $lowervalue,
                         'leftunit' => $lowerunit,
                         'lefttype' => $lefttype,
                         'rightvalue' => $uppervalue,
                         'rightunit' => $upperunit,
                         'righttype' => $righttype });
   }
 use Data::Dumper;
&logdebug("Found: ".Dumper(\@intervals));
# Now collapse overlapping intervals
   for (my $i=0;$i<=$#intervals;$i++) {
      for (my $j=0;$j<=$#intervals;$j++) {

      }
   }
   return(undef,undef,undef);
}

# Turn a set into a uniquified vector
# {3;4;5;6;4}={3;4;5;6}
#
sub evaluate_as_set {
   my ($parser,$env,$term)=@_;
# This comes in as a set, but we don't care
   $term=~s/\{/\[/gs;
   $term=~s/\}/\]/gs;
# Unified: just toss them all together
   $term=~s/\]\s*u\s*\[/\;/gsi;
   my ($termerror,$termeval)=&evaluate_in_parser($parser,$env,$term);
   if ($termerror) {
      return($termerror,$termeval);
   }
# Now uniquify
   $termeval=~s/\[//gs;
   $termeval=~s/\]//gs;
   my %set=();
   foreach my $member (split(/\;/,$termeval)) {
       $member=~s/^\s*//gs;
       $member=~s/\s*$//gs;
       $set{$member}=1;
   }
# Put back together
   return(undef,'['.join(';',keys(%set)).']');
}


# A numeric comparison of $expression and $expected
#
sub answertest {
    my ($parser,$env,$expression, $expected, $tolerance, $special)=@_;

&logdebug("Answertest [$expression] [$expected] [$special]");
# Norm the input of multiple responses and answers, make array default
    if (($expression=~/\;/) && ($expression!~/^\s*[\[\{\(]/)) {
       $expression='['.$expression.']';
    }
    if (($expected=~/\;/) && ($expected!~/^\s*[\[\{\(]/)) {
       $expected='['.$expected.']';
    }
# No tolerance? Be absolutely tolerant!
    if (!defined $tolerance) {
        $tolerance = 1e-5;
    }
# Nothing specified? Nothing we can do.
    unless ($expression=~/\S/) {
       return(&no_valid_response(),undef);
    }
    unless ($expected=~/\S/) {
       return(&no_valid_answer(),undef);
    }
# This is where the evaluation starts
    if ($special eq 'sets') {
# Sets as answers
       my ($responseerror,$response)=&evaluate_as_set($parser,$env,$expression);
       if ($responseerror) {
          return($responseerror,$response);
       }
       my ($answererror,$answer)=&evaluate_as_set($parser,$env,$expected);
       if ($answererror) {
          return($answererror,$answer);
       }
# Should be uniquified vectors now, but not ordered
       return &answertest($parser,$env,$response,$answer,$tolerance,'unordered');
    } elsif ($special eq 'unordered') {
# [2;42;17]=[42;2;17]
# Evaluate response
       my ($responseerror,$response)=&evaluate_in_parser($parser,$env,$expression);
       if ($responseerror) {
          return($responseerror,$response);
       }
       $response=~s/[\[\]]//gs;
       my $sortedresponse='['.join(';',sort { (&value_unit($a))[0] <=> (&value_unit($b))[0] } (split(/\;/,$response))).']';
# Evaluate answer
       my ($answererror,$answer)=&evaluate_in_parser($parser,$env,$expected);
       if ($answererror) {
          return($answererror,$answer);
       }
       $answer=~s/[\[\]]//gs;
       my $sortedanswer='['.join(';',sort { (&value_unit($a))[0] <=> (&value_unit($b))[0] } (split(/\;/,$answer))).']';
       return &answertest($parser,$env,$sortedresponse,$sortedanswer,$tolerance);
    } elsif ($special eq 'intervals') {
# Intervals
# (2;42]u(17;56]=(2;56]
        my ($responsecode,$responsesequence,$responsevector)=&evaluate_intervals($parser,$env,$expression);
        if ($responsecode) { return($responsecode,undef); }
        my ($answercode,$answersequence,$answervector)=&evaluate_intervals($parser,$env,$expected);
        if ($answercode) { return($answercode,undef); }
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
       if ($answererror) {
          return($answererror,$answer);
       }
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
# Evaluate the answer
       my ($error,$answer)=&evaluate_in_parser($parser,$env,$expected);
       if ($error) {
          return($error,$answer);
       }
# This only works if the problem provides upper and lower limits
       unless ($answer=~/\;/) {
          return(&answer_array_required(),undef);
       }
# Answer seems to be clean, split it
       $answer=~s/[\[\]]//gs;
       my ($lower,$upper)=split(/\;/,$answer);
# Figure out the boundary relationship
       my ($lowerbound,$upperbound);
       if ($special eq 'insideopen') {
          $lowerbound='gt';
          $upperbound='lt';
       }
       if ($special eq 'outsideopen') {
          $lowerbound='le';
          $upperbound='ge';
       }
       if ($special eq 'insideclosed') {
          $lowerbound='ge';
          $upperbound='le';
       }
       if ($special eq 'outsideclosed') {
          $lowerbound='lt';
          $upperbound='gt';
       }
# Do the evaluation
       my ($lowercode,$lowermessage)=&answertest($parser,$env,$expression,$lower,undef,$lowerbound);
       my ($uppercode,$uppermessage)=&answertest($parser,$env,$expression,$upper,undef,$upperbound);
# Both correct: great!
       if (($lowercode eq &correct()) && ($uppercode eq &correct())) {
          return (&correct(),undef);
       }
# Both incorrect: not good
       if (($lowercode eq &incorrect()) && ($uppercode eq &incorrect())) {
          return (&incorrect(),undef);
       }
# One right, one wrong, or both wrong: depends!
       if ((($lowercode eq &incorrect()) && ($uppercode eq &correct())) ||
           (($lowercode eq &correct()) && ($uppercode eq &incorrect()))) {
          if ($special=~/inside/) {
             return (&incorrect(),undef);
          } else {
             return (&correct(),undef);
          }
       }
# By now it's neither right nor wrong
# Both have the same problem
       if ($lowercode eq $uppercode) { return($lowercode,undef); }
# No idea what's wrong
       return(&no_valid_response(),undef);
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
