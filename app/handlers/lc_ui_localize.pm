# The LearningOnline Network with CAPA - LON-CAPA
# Localization Module
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
package Apache::lc_ui_localize;

use strict;
use Apache::lc_localize;
use Apache::lc_date_utils();
use Apache::lc_entity_sessions();
use DateTime;
use DateTime::TimeZone;
use DateTime::Format::RFC3339;

require Exporter;

our @ISA = qw (Exporter);
our @EXPORT = qw(mt);

# ========================================================= The language handle

use vars qw($lh $current_language $mtcache %known_languages);

sub locallocaltime {
   my ($thistime) = @_;
   my $timezone=&context_timezone();
   my $dt = DateTime->from_epoch(epoch => $thistime)
                    ->set_time_zone($timezone);
   my $format=$lh->maketext('date_locale');
   my $f=DateTime::Format::RFC3339->new();
   if ($format!~/\$/) {
      return ($dt->strftime("%a %b %e %I:%M:%S %P %Y (%Z)"),$f->format_datetime($dt));
   }
   my $time_zone  = $dt->time_zone_short_name();
   my $seconds    = $dt->second();
   my $minutes    = $dt->minute();
   my $twentyfour = $dt->hour();
   my $day        = $dt->day_of_month();
   my $mon        = $dt->month()-1;
   my $year       = $dt->year();
   my $wday       = $dt->wday();                            	    			   
   if ($wday==7) { $wday=0; }
   my $month  =(split(/\,/,$lh->maketext('date_months')))[$mon];
   my $weekday=(split(/\,/,$lh->maketext('date_days')))[$wday];
   if ($seconds<10) { $seconds='0'.$seconds; }
   if ($minutes<10) { $minutes='0'.$minutes; }
   my $twelve=$twentyfour;
   my $ampm;
   if ($twelve>12) {
      $twelve-=12;
      $ampm=$lh->maketext('date_pm');
   } else {
      $ampm=$lh->maketext('date_am');
   }
   foreach ('seconds','minutes','twentyfour','twelve','day','year','month','weekday','ampm') {
      $format=~s/\$$_/eval('$'.$_)/gse;
   }
   return ($format." $time_zone",$f->format_datetime($dt));
}

sub inputdate_to_timestamp {
   my ($date,$hour,$min,$sec,$ampm,$timezone)=@_;
   my ($day,$month,$year)=&Apache::lc_date_utils::str2date($date);
   if (&mt('date_format') eq '12') {
      if ($ampm eq 'pm') {
         $hour+=12;
      }
   }
   if ($hour<10) { $hour='0'.$hour; }
   if ($min<10)  { $min='0'.$min;   }
   if ($sec<10)  { $sec='0'.$sec;   }
   my $datetime;
   eval {
      $datetime=DateTime->new(
      year       => $year,
      month      => $month,
      day        => $day,
      hour       => $hour,
      minute     => $min,
      second     => $sec,
      time_zone  => $timezone)->epoch();
   };
   return $datetime;
}

sub print_number {
   my ($num)=@_;
#FIXME
   return $num;
}

sub human_readable_size {
   my ($size)=@_;
   if ($size>1024*1024) {
      return &print_number(int(10.*$size/(1024*1024)+0.5)/10.).' MB';
   } elsif ($size>1024) {
      return &print_number(int(10.*$size/1024+0.5)/10.).' KB';
   } else {
      return $size.' B';
   }
}



sub all_languages {
   return %known_languages;
}

sub all_timezones {
   return DateTime::TimeZone->all_names;
}
 
sub mt {
   if ($lh) {
      if ($#_>0) { return $lh->maketext(@_); }
      if ($mtcache->{$current_language}->{$_[0]}) {
         return $mtcache->{$current_language}->{$_[0]};
      }
      my $translation=$lh->maketext(@_);
      $mtcache->{$current_language}->{$_[0]}=$translation;
      return $translation;
   } else {
      return $_[0];
   }
}

#
# Cascade down to set the language
#
sub context_language {
   my $language=&Apache::lc_entity_sessions::userlanguage();
   unless ($language) {
      $language=&Apache::lc_connection_utils::domain_locale(&Apache::lc_entity_sessions::user_domain());
   }
   unless ($language) {
      $language=&Apache::lc_connection_utils::domain_locale(&Apache::lc_connection_utils::default_domain());
   }
# Maybe we don't know the "sublanguage"
   unless ($known_languages{$language}) {
      $language=(split(/[\-\_]/,$language))[0];
   }
   return $language;
}

sub determine_language {
   &set_language(&context_language());
}

#
# Which timezone to use?
#
sub context_timezone {
   my $timezone=&Apache::lc_entity_sessions::usertimezone();
   if ($timezone) { return $timezone; }
   $timezone=&Apache::lc_connection_utils::domain_timezone(&Apache::lc_entity_sessions::user_domain());
   if ($timezone) { return $timezone; }
   return &Apache::lc_connection_utils::domain_locale(&Apache::lc_connection_utils::default_domain());
}

#
# Actually set the language for this request cycle
#
sub set_language {
   my ($lang)=@_;
   undef $lh;
   unless ($known_languages{$lang}) {
# Maybe we just don't have a special case 
      $lang=~s/\-\w+$//;
      unless ($known_languages{$lang}) { 
# Give up
         return undef; 
      }
   }
# Okay, we got this
   $lh=Apache::lc_localize->get_handle($lang);
   $current_language=$lang;
}

#
# Set the default language for the server
#
sub reset_language {
   &set_language(&Apache::lc_connection_utils::domain_locale(&Apache::lc_connection_utils::default_domain()));
}

BEGIN {
   %known_languages=(
       'de' => 'German',
       'en' => 'English',
       'x-bork' => 'Swedish Chef',
       'x-pig' => 'Pig Latin'
                    );
}
1;
__END__
