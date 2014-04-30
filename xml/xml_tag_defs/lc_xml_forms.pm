# The LearningOnline Network with CAPA - LON-CAPA
# XML definitions for form elements
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
package Apache::lc_xml_forms;

use strict;
use Apache::lc_ui_localize;
use Apache::lc_ui_utils;
use Apache::lc_date_utils;
use Apache::lc_ui_localize();
use DateTime;
use DateTime::TimeZone;
use DateTime::Format::RFC3339;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_lcform_html end_lcform_html start_lcformtable_html end_lcformtable_html start_lcformtableinput_html
                 start_lcforminput_html start_lcfileupload_html
                 start_lcformtrigger_html start_lcformcancel_html);

sub start_lcform_html {
   my ($p,$safe,$stack,$token)=@_;
   my $name=$token->[2]->{'name'};
   unless ($name) { $name=$token->[2]->{'id'}; }
   return '<form class="lcform" id="'.$token->[2]->{'id'}.'" name="'.$name.'"><input type="hidden" id="postdata" name="postdata" value="" />';
}

sub end_lcform_html {
   my ($p,$safe,$stack,$token)=@_;
   return '</form>';
}

sub start_lcformtable_html {
   my ($p,$safe,$stack,$token)=@_;
   return '<table class="lcformtable">';
}

sub end_lcformtable_html {
   my ($p,$safe,$stack,$token)=@_;
   return '</table>';
}

sub start_lcformtableinput_html {
   my ($p,$safe,$stack,$token)=@_;
   my $id=$token->[2]->{'id'};
   my $name=$token->[2]->{'name'};
   unless ($name) { $name=$id; }
   my $output='<tr><td class="lcformtabledescription"><label for="'.$id.'">'.
                  &mt($token->[2]->{'description'}).
                  '</label></td><td class="lcformtablefield">'.
                  &inputfield($token->[2]->{'type'},
                              $id,$name,
                              $token->[2]->{'size'},
                              $token->[2]->{'default'}).
                  '</td></tr>';
   return $output;
}

sub start_lcforminput_html {
   my ($p,$safe,$stack,$token)=@_;
   my $id=$token->[2]->{'id'};
   my $name=$token->[2]->{'name'};
   unless ($name) { $name=$id; }
   return &inputfield($token->[2]->{'type'},
                              $id,$name,
                              $token->[2]->{'size'},
                              $token->[2]->{'default'});
}


sub start_lcformtrigger_html {
   my ($p,$safe,$stack,$token)=@_;
   return '<span class="lcformtrigger"><a href="#" id="'.$token->[2]->{'id'}.'">'.
          &mt($token->[2]->{'description'}).'</a></span>';
}

sub start_lcformcancel_html {
   my ($p,$safe,$stack,$token)=@_;
   return '<span class="lcformcancel"><a href="#" id="'.$token->[2]->{'id'}.'">'.
          &mt('Cancel').'</a></span>';
}


# === Generate a single input field

sub inputfield {
   my ($type,$id,$name,$size,$default)=@_;
   if ($type eq 'text') {
      unless ($size) { $size=40; }
      return '<input class="lcformtextinput" type="text" id="'.$id.'" name="'.$name.'" size="'.$size.'" />';
   } elsif ($type eq 'textarea') {
      return '<textarea class="ckeditor" id="'.$id.'" name="'.$name.'">'.$default.'</textarea>';
   } elsif ($type eq 'username') {
      unless ($size) { $size=40; }
      return '<input class="lcformusernameinput" type="text" id="'.$id.'" name="'.$name.'" size="'.$size.'" />';
   } elsif ($type eq 'password') {
      unless ($size) { $size=40; }
      return '<input class="lcformpasswordinput" type="password" id="'.$id.'" name="'.$name.'" size="'.$size.'" />';
   } elsif ($type eq 'hosteddomain') {
      my ($defaultdomain,$domain_short,$domain_name)=&domain_choices('hosted');
      unless ($default) { $default=$defaultdomain; }
      return &selectfield($id,$name,$domain_short,$domain_name,$default);
   } elsif ($type eq 'language') {
      my ($default,$language_short,$language_name)=&language_choices($default);
      return &selectfield($id,$name,$language_short,$language_name,$default);
   } elsif ($type eq 'timezone') {
      my ($default,$timezones)=&timezone_choices($default);
      return &selectfield($id,$name,$timezones,$timezones,$default);
   } elsif ($type eq 'datetime') {
#FIXME: y2038?
      unless ($default) { $default=time; }
      return &datetimefield($id,$name,$default);
   }
}

# ==== Generate a select field
#
sub selectfield {
   my ($id,$name,$values,$choices,$default)=@_;
   my $selectfield='<select class="lcformselectinput" id="'.$id.'" name="'.$name.'">';
   for (my $i=0;$i<=$#{$values};$i++) {
          $selectfield.='<option value="'.$values->[$i].'"'.($values->[$i] eq $default?' selected="selected"':'').'>'.
                         $choices->[$i].'</option>';
   }
   $selectfield.='</select>';
   return $selectfield;
}

# ==== Generate a select field with a hidden label
#
sub hidden_label_selectfield {
   my ($id,$name,$values,$choices,$default,$description)=@_;
   return &hidden_label($id,$description).
          &selectfield($id,$name,$values,$choices,$default);
}

# ==== Hidden label for screenreaders
#
sub hidden_label {
   my ($id,$description)=@_;
   return  '<label for="'.$id.'" class="hidden">'.&mt($description).'</label>';
}

# ==== File upload
#
sub start_lcfileupload_html {
   my ($p,$safe,$stack,$token)=@_;
   my $id=$token->[2]->{'id'};
   my $name=$token->[2]->{'name'};
   my $description=$token->[2]->{'description'};
   my $success=$token->[2]->{'successcall'};
   my $fail=$token->[2]->{'failurecall'};
   unless ($name) { $name=$id; }
   unless ($description) { $description="Upload file"; }
   my $output='<label class="lcfileuploadlabel" for="'.$id.'" id="'.$id.'label">'.&mt($description).'</label>';
   $output.='<input id="'.$id.'" name="'.$name.'" class="lcinnerfileupload" type="file" onChange="do_upload(this.form,event,'."'$id','$success','$fail'".')" />';
   return $output;
}

# ==== Datetime
#
sub datetimefield {
   my ($id,$name,$default)=@_;
   my $timezone=&Apache::lc_ui_localize::context_timezone();
   my $dt = DateTime->from_epoch(epoch => $default)
                    ->set_time_zone($timezone);
   my $f=DateTime::Format::RFC3339->new();
   my $time_zone  = $dt->time_zone_short_name();
   my $seconds    = $dt->second();
   my $minutes    = $dt->minute();
   my $twentyfour = $dt->hour();
   my $day        = $dt->day_of_month();
   my $month      = $dt->month();
   my $year       = $dt->year();
# The date field
   my $dateid=$id.'_date';
   my $datename=$name.'_name';
   my $lang=&mt('language_code');
   if ($lang eq 'en') { $lang=''; }
   my $short_locale=&mt('date_short_locale');
   foreach ('day','year','month') {
      $short_locale=~s/\$$_/eval('$'.$_)/gse;
   }
   my $output="<fieldset><time datetime='".$f->format_datetime($dt)."'>";
   $output.=&hidden_label($dateid,'Date format month/day/year');
   $output.="<script>\$(function(){\$('#$dateid').datepick();\$('#$dateid').datepick('option',\$.datepick.regionalOptions['$lang']);})</script><input type='text' id='$dateid' name='$datename' value='$short_locale' size='10' />";
# The time fields
   my $timeformat=&mt('date_format');
   my $hourselect;
   my $hour;
   my $ampm;
   if ($timeformat eq '24') {
      $hourselect=[0..23];
      $hour=$twentyfour;
   } else {
      $hourselect=[1..12];
      if ($twentyfour>12) {
         $hour=$twentyfour-12;
         $ampm='pm';
      } else {
         $hour=$twentyfour;
         $ampm='am';
      }
   }
   $output.=&hidden_label_selectfield($id.'_time_hour',$name.'_time_hour',$hourselect,$hourselect,$hour,'Hour').':'.
            &hidden_label_selectfield($id.'_time_min',$name.'_time_min',[0..59],[0..59],$minutes,'Minute').':'.
            &hidden_label_selectfield($id.'_time_sec',$name.'_time_sec',[0..59],[0..59],$seconds,'Second');
   unless ($timeformat eq '24') {
      my $am=&mt('date_am');
      if ($am eq 'date_am') { $am='am'; }
      my $pm=&mt('date_pm');
      if ($pm eq 'date_pm') { $pm='pm'; }
      unless ($timeformat eq '24') {
         $output.=&hidden_label_selectfield($id.'_time_ampm',$name.'_time_ampm',['am','pm'],[$am,$pm],$ampm,'Before/after midday');
      }
   }
   $output.=$time_zone."</time></fieldset>";
   return $output;
}

1;
__END__
