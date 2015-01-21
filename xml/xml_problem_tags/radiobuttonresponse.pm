# The LearningOnline Network with CAPA - LON-CAPA
# Radiobuttonresponse 
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
package Apache::xml_problem_tags::radiobuttonresponse;

use strict;

use Apache::lc_math_parser();
use Apache::lc_problem_const;
use Apache::xml_problem_tags::hints();
use Apache::lc_logs;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_radiobuttonresponse_html  end_radiobuttonresponse_html
                 start_radiobuttonresponse_grade end_radiobuttonresponse_grade);

#
# Just start the numerical response environment.
# Everything happens at the end tag
#
sub start_radiobuttonresponse_html {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_asset_xml::init_response_html($token->[2]->{'id'},$stack);
   return '';
}

sub start_radiobuttonresponse_grade {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_asset_xml::init_response($token->[2]->{'id'},$stack);
}


#
# Output
#
sub end_radiobuttonresponse_html {
   my ($p,$safe,$stack,$token)=@_;
   return '';
}

#
# This is where the grading is happening
#
sub end_radiobuttonresponse_grade {
   my ($p,$safe,$stack,$token)=@_;
# ID
   my $id=&Apache::lc_asset_xml::open_tag_attribute('id',$stack);
# Special mode?
   my $mode=&Apache::lc_asset_xml::open_tag_attribute('mode',$stack);
# Get student response
   my $responses=&evaluate_responses($stack,$mode);
# Get ourselves a numerical parser and environment
   my ($parser,$env)=&Apache::lc_math_parser::new_numerical_parser($customunits);
# Get the old response details
   my $responsedetails=&Apache::lc_asset_xml::get_response_details($id,$stack);
# Did we get anything new?
   unless ($stack->{'context'}->{'newsubmission'}) {
# Nope? Store that there was nothing
   }
my $output;
my $message;
# Log this
   &Apache::lc_asset_xml::add_response_details($id,
                                               { 'type'        => 'radiobutton',
                                                 'mode'        => $mode,
                                                 'status'      => $outcome,
                                                 'message'     => $message},
                                               $stack);
# Put that on the grading stack to look at end_part_grade
   &Apache::lc_asset_xml::add_response_grade($id,$outcome,$message,$previously,$stack);
# Finally, deal with the hints
}

1;
__END__
