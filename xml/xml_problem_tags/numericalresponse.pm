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

use Data::Dumper;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_numericalresponse_html start_numericalresponse_tex 
                   end_numericalresponse_html   end_numericalresponse_tex
                 start_numericalhintcondition_html start_numericalhintcondition_tex
                   end_numericalhintcondition_html   end_numericalhintcondition_tex);

sub start_numericalresponse_html {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_asset_xml::init_response($stack);
   return '';
}

sub start_numericalresponse_tex {
   return &start_numericalresponse_html(@_);
}

sub end_numericalresponse_html {
   my ($p,$safe,$stack,$token)=@_;
#FIXME: do stuff
   return "Get: ".&Apache::lc_asset_xml::cascade_parameter('tol',$stack).'<br /><pre>'.Dumper($stack).'</pre>';
}

sub end_numericalresponse_tex {
   my ($p,$safe,$stack,$token)=@_;
#FIXME
   return '';
}

sub start_numericalhintcondition_html {
   my ($p,$safe,$stack,$token)=@_;
   &Apache::lc_asset_xml::add_response_hint($stack);
   return '';
}

sub start_numericalhintcondition_tex {
   return &start_numericalhintcondition_html(@_);
}

sub end_numericalhintcondition_html {
   my ($p,$safe,$stack,$token)=@_;
#FIXME actually evaluate
   return '';
}


sub end_numericalhintcondition_tex {
   return &end_numericalhintcondition_html(@_);
}



1;
__END__
