# The LearningOnline Network with CAPA - LON-CAPA
# Deal with PostgreSQL
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
package Apache::lc_postgresql;

use strict;
use DBI;
use Apache::lc_logs;

require Exporter;
our @ISA = qw (Exporter);
our @EXPORT = qw(insert_url);


use vars qw($dbh);

sub insert_url {
   my ($url,$entity)=@_;
# Remove initial slash, if present
   $url=~s/^\/+//;
# Remove "asset" and version tags
   $url=~s/^asset\/\w+\/\w+\///;
   return $dbh->do("insert into urls (url,entity) values ('$url','$entity')");
}

#
# Initialize the postgreSQL handle, local host
#
sub init_postgres {
   if ($dbh=DBI->connect('DBI:Pg:dbname=loncapa;host=127.0.0.1;port=5432','loncapa','loncapa',{ RaiseError => 0 })) {
      &lognotice("Connected to PostgreSQL");
   } else {
      &logerror("Could not connect to PostgreSQL, ".$DBI::errstr);
   } 
}

BEGIN {
   &init_postgres();
}

1;
__END__
