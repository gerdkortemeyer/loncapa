# The LearningOnline Network with CAPA - LON-CAPA
# Pig Latin Localization Module for Testing
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
#
package Apache::lc_localize::x_pig;
use base qw(Apache::lc_localize);
use Lingua::PigLatin();

sub init {
   my $lh = $_[0];
   $lh->SUPER::init();
   $lh->fail_with(\&fail);
   return;
}

sub fail {
   my ($lh,$key,@params)=@_;
   my $value=$lh->_compile(&pig($key));
   return $$value if ref($value) eq 'SCALAR';
   return $value unless ref($value) eq 'CODE'; 
   { 
     local $SIG{'__DIE__'};
     eval { $value = &$value($lh, @params) };
   }
   return $value;
}

sub pig {
   my ($key)=@_;
   return &Lingua::PigLatin::piglatin($key);
}

%Lexicon=(
'language_code'      => 'x-pig',
'language_direction' => 'rtl',
'language_description' => 'Pig Latin',
'date_short_locale' => '$year/$month/$day',
);

1;
__END__
