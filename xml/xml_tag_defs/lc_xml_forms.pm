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
use Apache::lc_file_utils;
use Apache::lc_json_utils;
use Apache::lc_parameters;
use Apache::lc_ui_localize;
use Apache::lc_ui_utils;
use Apache::lc_date_utils;
use Apache::lc_ui_localize();
use DateTime;
use DateTime::TimeZone;
use DateTime::Format::RFC3339;
use Apache::lc_xml_utils();
use Apache::lc_entity_sessions();
use Apache::lc_entity_users();

#
# Screen defaults
#
my $screen_form_defaults;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_lcform_html end_lcform_html start_lcformtable_html end_lcformtable_html start_lcformtableinput_html
                 start_lcforminput_html start_lcfileupload_html
                 start_lcformtrigger_html start_lcformcancel_html
                 start_lcspreadsheetassign_html end_lcspreadsheetassign_html start_lcselectoption_html);

#
# LC's version of forms
# takes name, id, and "screendefaults" which are used to load default value from previous submissions
#
sub start_lcform_html {
   my ($p,$safe,$stack,$token)=@_;
   my $id=$token->[2]->{'id'};
   my $name=$token->[2]->{'name'};
   unless ($name) { $name=$id; }
# Load screendefaults, if there are any
   undef $screen_form_defaults;
   my $screendefaults=$token->[2]->{'screendefaults'};
   if ($screendefaults) {
      $screen_form_defaults=&Apache::lc_entity_users::screen_form_defaults(&Apache::lc_entity_sessions::user_entity_domain(),$screendefaults);
   }
# Actually start the form
   &form_start($id,$name,$screendefaults);
}

sub form_start {
   my ($id,$name,$screendefaults)=@_;
   return '<form class="lcform" id="'.$id.'" name="'.$name.'"'.
   ($screendefaults?' onsubmit="screendefaults(\''.$id."','".$screendefaults.'\')"':'').
   '>'.&hidden_field('postdata','');
}

sub end_lcform_html {
   my ($p,$safe,$stack,$token)=@_;
   return &form_end();
}

sub form_end {
   return '</form>';
}


sub start_lcformtable_html {
   my ($p,$safe,$stack,$token)=@_;
   return &form_table_start();
}

sub form_table_start {
   return '<table class="lcformtable">';
}


sub end_lcformtable_html {
   my ($p,$safe,$stack,$token)=@_;
   return &form_table_end();
}

sub form_table_end {
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
   return &triggerbutton($token->[2]->{'id'},$token->[2]->{'description'});
}

sub triggerbutton {
   my ($id,$text)=@_;
   return '<span class="lcformtrigger"><a href="#" id="'.$id.'">'.&mt($text).'</a></span>';
}

sub start_lcformcancel_html {
   my ($p,$safe,$stack,$token)=@_;
   return &cancelbutton($token->[2]->{'id'},'Cancel');
}

sub cancelbutton {
   my ($id,$text)=@_;
   return '<span class="lcformcancel"><a href="#" id="'.$id.'">'.&mt($text).'</a></span>';
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
   } elsif ($type eq 'checkbox') {
      return '<input class="lcformcheckbox" type="checkbox" id="'.$id.'" name="'.$name.'" />';
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
      unless ($default) { 
         if (($screen_form_defaults->{$id.'_date'}) && ($screen_form_defaults->{$id.'_time_zone'})) {
            $default=&Apache::lc_ui_localize::inputdate_to_timestamp(
                  $screen_form_defaults->{$id.'_date'},
                  $screen_form_defaults->{$id.'_time_hour'},
                  $screen_form_defaults->{$id.'_time_min'},
                  $screen_form_defaults->{$id.'_time_sec'},
                  $screen_form_defaults->{$id.'_time_ampm'},
                  $screen_form_defaults->{$id.'_time_zone'});
         }
      }
      unless ($default) { $default=time; }
      return &datetimefield($id,$name,$default);
   } elsif ($type eq 'modifiablecourseroles') {
      my ($role_short,$role_name)=&modifiable_role_choices('course');
      return &selectfield($id,$name,$role_short,$role_name,$default);
   } elsif ($type eq 'symbolic') {
      return &math_editor($id,$name,'symbolic',$default);
   } elsif ($type eq 'numeric') {
      return &math_editor($id,$name,'numeric',$default);
   }
}

# ==== Bring up a math editor field
# 
sub math_editor {
   my ($id,$name,$mode,$default)=@_;
   unless ($name) {
      $name=$id;
   }
   my $output='<div class="eqnbox">';
   $output.='<textarea id="'.$id.'" name="'.$name.'" data-implicit_operators="true" spellcheck="false" class="math"';
   if ($mode eq 'numeric') {
      my $constants_txt = Apache::lc_file_utils::readfile(Apache::lc_parameters::lc_conf_dir()."constants.json");
      my $constants = Apache::lc_json_utils::json_to_perl($constants_txt);
      $output.=' data-constants="'.join(',', keys %{$constants}).'" data-unit_mode="true"';
   }
   $output.='>'.$default.'</textarea></div>';
   return $output;
}

# ==== Generate a select field
#
sub selectfield {
   my ($id,$name,$values,$choices,$default,$onchange)=@_;
   unless ($default) {
      $default=$screen_form_defaults->{$id};
   }
   my $changecall='';
   if ($onchange) {
      $changecall=' onChange="'.$onchange.'"';
   }
   my $selectfield='<select class="lcformselectinput" id="'.$id.'" name="'.$name.'"'.$changecall.'>';
   for (my $i=0;$i<=$#{$values};$i++) {
          $selectfield.='<option value="'.$values->[$i].'"'.($values->[$i]=~/^($default)$/?' selected="selected"':'').'>'.
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

# ==== Hidden field
#
sub hidden_field {
   my ($id,$value,$name)=@_;
   unless ($name) { $name=$id; }
   return "<input type='hidden' id='$id' name='$name' value='".&Apache::lc_xml_utils::form_escape($value)."' />";
}

# ==== Turn a hash into hidden fields
#
sub hidden_vars {
   my (%content)=@_;
   return join("\n",map { &hidden_field($_,$content{$_},$_) } keys(%content));
}

# ==== File upload
#
sub start_lcfileupload_html {
   my ($p,$safe,$stack,$token)=@_;
   my $id=$token->[2]->{'id'};
   my $name=$token->[2]->{'name'};
   my $target=$token->[2]->{'target'};
   my $description=$token->[2]->{'description'};
   my $success=$token->[2]->{'successcall'};
   my $fail=$token->[2]->{'failurecall'};
   unless ($name) { $name=$id; }
   unless ($description) { $description="Upload file"; }
   my $output='<label class="lcfileuploadlabel" for="'.$id.'" id="'.$id.'label">'.&mt($description).'</label>';
   $output.='<input id="'.$id.'" name="'.$name.'" class="lcinnerfileupload" type="file" onChange="do_upload(this.form,event,'."'$target','$id','$success','$fail'".')" />';
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
   my $time_zone_long = $dt->time_zone_long_name();
   my $seconds    = $dt->second();
   my $minutes    = $dt->minute();
   my $twentyfour = $dt->hour();
   my $day        = $dt->day_of_month();
   my $month      = $dt->month();
   my $year       = $dt->year();
# The date field
   my $dateid=$id.'_date';
   my $datename=$name.'_date';
   my $lang=&mt('language_code');
   if ($lang eq 'en') { $lang=''; }
   my $short_locale=&mt('date_short_locale');
   foreach ('day','year','month') {
      $short_locale=~s/\$$_/eval('$'.$_)/gse;
   }
   my $output="<fieldset id='".$id."'><time datetime='".$f->format_datetime($dt)."'>";
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
   $output.=&hidden_field($id.'_time_zone',$time_zone_long).$time_zone."</time></fieldset>";
   return $output;
}

sub start_lcselectoption_html {
   my ($p,$safe,$stack,$token)=@_;
   push(@{$stack->{'tags'}->[-2]->{'options'}},{value=>$token->[2]->{'value'},label=>$token->[2]->{'label'}});
   return '';
}

sub start_lcspreadsheetassign_html {
   my ($p,$safe,$stack,$token)=@_;
   $stack->{'tags'}->[-1]->{'options'}=[];
   return '';
}

sub end_lcspreadsheetassign_html {
   my ($p,$safe,$stack,$token)=@_;
   my $output='';
# Attempt to read uploaded spreadsheet
   my ($entity,$domain)=&Apache::lc_entity_sessions::user_entity_domain();
   my $sheets=&Apache::lc_json_utils::json_to_perl(
                &Apache::lc_file_utils::readfile(
                   &Apache::lc_entity_urls::wrk_to_filepath($domain.'/'.$entity.'/uploaded_spreadsheet.json')));
   unless ($sheets) {
      return &Apache::lc_xml_utils::error_message('Could not interpret spreadsheet data. Please make sure your file has the proper extension (e.g., ".xls") or try another format.');
   }
   my $values;
   my $choices;
   foreach my $option (@{$stack->{'tags'}->[-1]->{'options'}}) {
      push(@{$values},$option->{'value'});
      push(@{$choices},&mt($option->{'label'}));
   }
# Go through all worksheets
   foreach my $worksheet (keys(%{$sheets})) {
      unless (($sheets->{$worksheet}->{'col_max'}>1) && ($sheets->{$worksheet}->{'row_max'}>1)) {
        $output.='<p>'.
            &Apache::lc_xml_utils::problem_message(
               'The spreadsheet may have been misinterpreted. Please make sure your file has the proper extension (e.g., ".xls") or try another format.').
               '</p>';
      }
# Start a new table for each worksheet
      $output.='<table><thead class="lcsorttablehead"><tr><th colspan="2">'.$worksheet.'</th></tr><tr><th>'.&mt('Sample Entries').'</th><th>'.&mt('Assignment').
               '</th></tr></thead><tbody class="lcsorttablebody">';
      foreach my $col ($sheets->{$worksheet}->{'col_min'} .. $sheets->{$worksheet}->{'col_max'}) {
         $output.="\n<tr><td><pre>";
         my $found=0;
         foreach my $row ($sheets->{$worksheet}->{'row_min'} .. $sheets->{$worksheet}->{'row_max'}) {
            if ($sheets->{$worksheet}->{'cells'}->{$row}->{$col}->{'value'}) {
               $output.=$sheets->{$worksheet}->{'cells'}->{$row}->{$col}->{'value'}."\n";
               $found++;
            }
            if ($found>5) { last; }
         }
         $output.="</pre></td><td>\n";
         my $default='nothing';
         my $id=&Apache::lc_xml_utils::form_escape($worksheet.'c'.$col);
         if ($screen_form_defaults->{$id}) {
            $default=$screen_form_defaults->{$id};
         }
         $output.=&selectfield($id,$id,$values,$choices,$default,$stack->{'tags'}->[-1]->{'args'}->{'verify'});
         $output.="</td></tr>";
      }
      $output.='</tbody></table>';
   }
   $output.=&hidden_field('flush_associations',1);
   return $output;
}



1;
__END__
