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

# ==== Lock a file the hard way
#
sub getlock {
   my ($filename)=@_;
   &touch($filename);
   my $fh;
   open($fh,$filename);
   flock($fh,LOCK_EX);
   return $fh;
}

# ==== Unlock a file
#
sub unlock {
   my ($fh)=@_;
   flock($fh,LOCK_UN);
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
      open(IN,$filename) || &logwarning("Error open readfile $filename: $!");
      $data=join('',<IN>);
      close(IN);
   } else {
      &logwarning("Non existing readfile $filename");
   }
   return $data;
}

1;
__END__
