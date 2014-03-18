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

use Apache::lc_logs;
use Apache::lc_parameters;

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

# ==== Write a file
#
sub writefile {
   my ($filename,$data)=@_;
   &ensuresubdir($filename);
   my $fh=&get_exclusive_lock($filename);
   open(OUT,'>'.$filename) || &logwarning("Could not open writefile $filename: $!");
   print OUT $data;
   close(OUT);
   &unlock($fh);
}

# ==== Asset files

# Takes URL entity and returns the filename in resource space
#
sub asset_resource_filename {
   my ($entity,$domain,$version_type,$version_arg)=@_;
   $entity=~/(\w)(\w)(\w)(\w)/;
   my $filename=&lc_res_dir().$domain.'/'.$1.'/'.$2.'/'.$3.'/'.$4.'/'.$entity;
# Absolute version number
   if ($version_type eq 'n') {
      $filename.='.'.$version_arg;
   }
   return $filename;
}

1;
__END__
