# The LearningOnline Network with CAPA - LON-CAPA
# Utilities for handling files 
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

package Apache::lc_file_utils;

use strict;
use File::Util;
use Fcntl qw(:flock);
use File::Touch;
use File::Copy;
use Apache::lc_logs;
use Apache::lc_parameters;
use Apache::lc_entity_urls();
use Apache::lc_json_utils();

my $extension;

sub file_icon {
   my ($type,$name)=@_;
   if ($type eq 'special') {
      if ($name eq 'dir_up') { return 'dir_up'; }
      if ($name eq 'led_green') { return 'led_green'; }
      if ($name eq 'led_orange') { return 'led_orange'; }
      if ($name eq 'led_red') { return 'led_red'; }
      if ($name eq 'led_black') { return 'led_black'; }
   }
   if ($type eq 'directory') { return 'folder_closed'; }
   unless ($extension) { &load_extension(); }
   my ($ext)=($name=~/\.(\w+)$/);
   if ($extension->{$ext}->{'icon'}) { return $extension->{$ext}->{'icon'}; }
   return 'unknown';
}

sub load_extension {
   $extension=&Apache::lc_json_utils::json_to_perl(&readfile(&lc_conf_dir().'extensions.json'));
}

# ==== Lock a file the hard way
#
sub get_exclusive_lock {
   my ($filename)=@_;
   &touch($filename.'.lock');
   my $fh;
   open($fh,$filename.'.lock');
   flock($fh,LOCK_EX);
   return $fh;
}

sub get_shared_lock {
   my ($filename)=@_;
   &touch($filename.'.lock');
   my $fh;
   open($fh,$filename.'.lock') || &logwarning("Could not open lockfile for $filename");
   flock($fh,LOCK_SH) || &logwarning("Could not obtain lock for $filename");
   return $fh;
}

# ==== Unlock a file
#
sub unlock {
   my ($fh)=@_;
   flock($fh,LOCK_UN) || &logwarning("Could not remove a lock");
   close($fh);
}

# ==== Ensuring a data directory exists
# Input: filepath
#
sub ensuresubdir {
   my ($filepath)=@_;
   $filepath=~s/\/[^\/]+$//;
   unless (-e $filepath) {
      eval {
         my $f=File::Util->new();
         $f->make_dir($filepath,0700,'--if-not-exists');
      };
      if ($@) { 
         &logwarning("Could not make subdirectory $filepath: $@");
         return 0; 
      }
   }
   return 1;
}

# ==== Read a file
#
sub readfile {
   my ($filename)=@_;
   my $data='';
   if (-e $filename) {
      my $fh=&get_shared_lock($filename);
      open(IN,$filename) || &logwarning("Error open readfile $filename: $!");
      $data=join('',<IN>);
      close(IN);
      &unlock($fh);
   } else {
      &logwarning("Non existing readfile $filename");
   }
   return $data;
}

# ==== Read a URL, replicate if needed
#
sub readurl {
   my ($url)=@_;
   my $filepath=&Apache::lc_entity_urls::url_to_filepath($url);
   unless ($filepath) {
      &logwarning("Trying to read ($url) at ($filepath), but does not exist");
      return undef;
   }
   unless (-e $filepath) {
      unless (&Apache::lc_entity_urls::replicate($url)) {
         &logwarning("Failed to replicate ".$url);
         return undef;
      }
   }
   return &readfile($filepath);
}

# ==== Write a file
#
sub writefile {
   my ($filename,$data)=@_;
   &ensuresubdir($filename);
   my $fh=&get_exclusive_lock($filename);
   unless (open(OUT,'>'.$filename)) {
      &unlock($fh);
      &logerror("Could not open writefile $filename: $!");
      return undef;
   }
   print OUT $data;
   close(OUT);
   &unlock($fh);
   return 1;
}

# ==== Write a URL
#
sub writeurl {
   my ($full_url,$data)=@_;
   my ($version_type,$version_arg,$domain,$author,$url)=&Apache::lc_entity_urls::split_url($full_url);
   unless ($version_type eq 'wrk') {
      &logerror("Cannot directly write to any published version of ($full_url)");
      return undef;
   }
   my $filename=&Apache::lc_entity_urls::url_to_filepath($full_url);
   unless ($filename) {
      &logerror("Cannot write to ($full_url), no file path");
      return undef;
   }
   return &writefile($filename,$data);
}

1;
__END__
