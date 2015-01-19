# The LearningOnline Network with CAPA - LON-CAPA
# Outputtags
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
package Apache::xml_problem_tags::outputtags;

use strict;
use Apache::lc_asset_safeeval();
use Math::SigFigs;

use Apache::lc_logs;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_num_html);

#
# Turn something into the right number of significant digits
# Using Math::SigFigs
# Format like '3s'
#
sub format_sigfigs {
   my ($num,$digits)=@_;
   return Math::SigFigs::FormatSigFigs($num,$digits);
}

#
# Turn something into scientific notation
# Using Number::Format
# Format like '3e' 
#
#sub format_scientific {
#   my ($num,$digits)=@_;
#   return sprintf("%.$digits"."e", $num);
#}

#
# Format a number according to a formatting string, e.g., "3s"
# Also exported to safespace
#
#sub format {
#   my ($num,$formatstring)=@_;
#   if ($formatstring=~/^(\d+)s$/is) {
#      return &format_sigfigs($num,$1);
#   } elsif ($formatstring=~/^(\d+)e$/is) {
#      return &format_scientific($num,$1);
#   } else {
## No idea what the format is supposed to be, just return
#      return $num;
#   }
#}
 



sub format {
    my ($value,$fmt)=@_;
    my $result;
    #if ($fmt =~ /chem/i) { return(&chemparse($value)); }
    my ($dollarmode,$commamode,$alwaysperiod,$options);
    if ($fmt =~ /^([^\d]*)(.*)/) { $options=$1; $fmt=$2; }
    if ($options =~ /\$/) { $dollarmode=1; }
    if ($options =~ /,/)  { $commamode=1; }
    if ($options =~ /\./) { $alwaysperiod=1; }
    if ($fmt=~/^(\d+)s$/is) {
       $value=&format_sigfigs($value,$1);
    } elsif ($fmt) {
       $value=sprintf('%.'.$fmt,$value);
    }
    if ($alwaysperiod && $fmt eq '0f') {
       #if ($target eq 'tex') {
       #   $value .='\\ensuremath{.}';
       #} else {
          $value .='.';
       #}
    }
    if ($value =~ /([0-9\.\-\+]+)[eE]([0-9\-\+]+)/i ) {
       my $frac=$1;
       if ($dollarmode) { $frac=&dollarformat($frac); }
       if ($commamode) { $frac=&commaformat($frac); }
       my $exponent=$2;
       $exponent=~s/^\+0*//;
       $exponent=~s/^-0*/-/;
       $exponent=~s/^-0*/-/;
       if ($exponent eq '-') { undef($exponent); }
       if ($exponent) {
          #if ($target eq 'web') {
             $result=$frac.'&#215;10<sup>'.$exponent.'</sup>';
          #} elsif ($target eq 'tex') {
          #   $result='\ensuremath{'.$frac.'\times 10^{'.$exponent.'}}';
          #} else {
          #   $result=$value;
          #}
       } else {
          $result=$frac;
       }
    } else {
       $result=$value;
       #if    ($dollarmode) { $result=&dollarformat($result,$target); }
       #elsif ($commamode)  { $result=&commaformat($result,$target); }
    }
    return $result;
}

#
sub start_num_html {
   my ($p,$safe,$stack,$token)=@_;
# Fetch everything up to </num> and clear the stack
   my $text=$p->get_text('/num');
   $p->get_token;
   pop(@{$stack->{'tags'}});
# Evaluate all variables that may be in there inside safespace, return formatted version
   #return &format(&Apache::lc_asset_safeeval::texteval($safe,$text),$token->[2]->{'format'});
   return &format(&Apache::lc_asset_safeeval::texteval($safe,$text),$token->[2]->{'format'});
}

1;
__END__
