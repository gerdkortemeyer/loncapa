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

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_lcform_html end_lcform_html start_lcformtable_html end_lcformtable_html start_lcformtableinput_html
                 start_lcforminput_html
                 start_lcformtrigger_html start_lcformcancel_html);

sub start_lcform_html {
   my ($p,$safe,$stack,$token)=@_;
   return '<form class="lcform" id="'.$token->[2]->{'id'}.'">';
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


1;
__END__
