# The LearningOnline Network with CAPA - LON-CAPA
# Utilities for writing log files 
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

package Apache::lc_logs;

use strict;

use Apache::lc_parameters;
use Apache::lc_date_utils();
use Devel::StackTrace();

require Exporter;
our @ISA = qw (Exporter);
our @EXPORT = qw(logerror logwarning lognotice logdebug);

sub appendlog {
   my ($which,$text)=@_;
   open(LOG,'>>'.&lc_log_dir().$which.'.log');
   print LOG &Apache::lc_date_utils::now2str().":$$: ".$text."\n";
   close(LOG);
}

sub logerror {
   my $trace = Devel::StackTrace->new();
   &appendlog('errors',@_[0]."\n".$trace->as_string());
}

sub logwarning {
   &appendlog('warnings',@_[0]);
}
sub lognotice {
   &appendlog('notices',@_[0]);
}

sub logdebug {
   &appendlog('debug',@_[0]);
}

1;
__END__
