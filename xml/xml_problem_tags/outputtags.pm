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
use Apache::lc_logs;
use Math::SigFigs;
use Number::Format qw(:subs);
use Locale::Currency::Format;
use Physics::Unit qw(:ALL);
use Number::FormatEng qw(:all);

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_num_html 
                 start_monetary_html
                 start_quantity_html
                );

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
sub format_scientific {
    my ($num,$formatstring)=@_;
    return sprintf('%.'.$formatstring,$num);
}

#
# Groups of three digits are separated by commas
#
sub format_comma {
    my ($number) = @_;
    return format_number($number);
}

#
# Format a number according to a formatting string, e.g., "3s"
# Also exported to safespace
#
sub format {
    my ($num,$formatstring)=@_;
    my ($result, $commamode, $alwaysperiod, $options);
    # Look for any non-digit starting characters which indicate options
    if ($formatstring =~ /^([^\d]*)(.*)/) { $options=$1; $formatstring=$2; }
    if ($options =~ /,/)  { $commamode=1; }
    if ($options =~ /\./) { $alwaysperiod=1; }
    if ($formatstring =~ /^(\d+)s$/is) { $num = &format_sigfigs($num,$1); } 
    # Otherwise process with "sprintf" (probably float or scientific notation)
    elsif ($formatstring) { $num = &format_scientific($num, $formatstring); }
    # Append a period with no trailing digits
    if ($alwaysperiod && $formatstring eq '0f') { $num .='.'; }
    # Change display format for scintific notation to use "x10^"
    # First identify the significand and exponent ($1 and $2)
    if ($num =~ /([\d\.\-\+]+)[eE]([\d\-\+]+)/i ) {
        my $frac=$1;
        if ($commamode) { $frac=&format_comma($frac); }
        my $exponent=$2;
        # Remove preceding zeros from the exponent
        $exponent=~s/^\+0*//; 
        $exponent=~s/^-0*/-/;
        if ($exponent eq '-') { undef($exponent); }
        if ($exponent) { $result=$frac.'&#215;10<sup>'.$exponent.'</sup>'; }
        # For an exponent of +/-0, just print the significand
        else { $result=$frac; } 
    } else {
        # No idea what the format is supposed to be, just return
        $result=$num;
        if ($commamode) { $result = &format_comma($result); }
    }
    return $result;
}

#
# Format a number with units.  If starting units are given, conversion is attempted
#
sub format_units {
    my ($num, $unitout, $formatstring) = @_;
    my ($result, $unitin);
    # Look for starting units
    if ($num =~ /^([\+\-\.\d]+[eE]?[\+\-\d]*)\s?([^\d]*)$/) {
        $num = $1;
        $unitin = $2;
    } else {
        # Invalid input, just return
        return $num;
    }
    # Convert units if input units are present and conversion is possible
    if ($unitin) {
        eval {$result = GetUnit("$num $unitin")->convert("$unitout") };
        # If conversion impossible, return original number with original units
        return "$num $unitin" if $@;
    } else { $result = $num; } # No starting units, skip conversion

    # If unitout is a base SI unit, add a metric prefix
    if ($unitout eq eval{GetUnit($unitout)->expanded}) {
        $result = format_pref($result);
        # If there is a metric prefix move it from the number string to the unit string
        if ($result =~ /^(.*\d)([a-zA-Z])$/) {
            $result = $1;
            $unitout = $2.$unitout;
        }
    }
    # Apply requested formatstring.  Default to "3g"
    if ($formatstring) { 
        $result = &format($result, $formatstring); 
    } else {
        $result = &format($result, "3g"); 
    }
    return "$result $unitout";
}

#
# Format currency with the appropriate symbol.  
# Valid currency codes are from ISO 4217, e.g. currency="USD".
#
sub format_currency {
    my ($num,$currencycode)=@_;
    return currency_format($currencycode, $num, FMT_SYMBOL);
}

sub start_num_html {
    my ($p,$safe,$stack,$token)=@_;
# Fetch everything up to </num> and clear the stack
    my $text=$p->get_text('/num');
    $p->get_token;
    pop(@{$stack->{'tags'}});
# Evaluate all variables that may be in there inside safespace, return formatted version
    return &format(&Apache::lc_asset_safeeval::texteval($safe,$text),
            $token->[2]->{'format'});
}

sub start_monetary_html {
    my ($p,$safe,$stack,$token)=@_;
# Fetch everything up to </monetary> and clear the stack
    my $text=$p->get_text('/monetary');
    $p->get_token;
    pop(@{$stack->{'tags'}});
# Evaluate all variables that may be in there inside safespace, return formatted version
    return &format_currency(&Apache::lc_asset_safeeval::texteval($safe,$text),
            $token->[2]->{'currency'});
}

sub start_quantity_html {
    my ($p,$safe,$stack,$token)=@_;
# Fetch everything up to </quantity> and clear the stack
    my $text=$p->get_text('/quantity');
    $p->get_token;
    pop(@{$stack->{'tags'}});
# Evaluate all variables that may be in there inside safespace, return formatted version
    return &format_units(&Apache::lc_asset_safeeval::texteval($safe,$text),
            $token->[2]->{'unit'},$token->[2]->{'format'});
}

1;
__END__
