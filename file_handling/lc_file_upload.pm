# The LearningOnline Network with CAPA - LON-CAPA
# Uploading files from client - server-side 
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

package Apache::lc_file_upload;

use strict;

use Apache2::Const qw(:common :http);
use Apache::lc_logs;
use Apache::lc_parameters;
use Apache::lc_file_utils();
use File::Copy;
use Apache::lc_entity_sessions();

# The filename on the client side
# 
sub uploaded_remote_filename {
   my %content=&Apache::lc_entity_sessions::posted_content();
   return $content{'remote_filename'};
}

# The URL that an uploaded file should have
#
sub uploaded_dest_url {
   my %content=&Apache::lc_entity_sessions::posted_content();
   my ($entity,$domain)=&Apache::lc_entity_sessions::user_entity_domain();
   return '/asset/wrk/-/'.$domain.'/'.$entity.'/'.$content{'wrk_filename'};
}


# Moving the uploaded file into place
#
sub move_uploaded_into_place {
   my ($dest_filename)=@_;
   unless (&Apache::lc_file_utils::ensuresubdir($dest_filename)) { 
      &logerror("Unable to generate filepath for ($dest_filename) to move uploaded file");
      return undef; 
   }
   my %content=&Apache::lc_entity_sessions::posted_content();
   return &copy($content{'local_filename'},$dest_filename);
}

# Move the uploaded file into the default place in the user's wrk-directory
#
sub move_uploaded_into_default_place {
   my ($entity,$domain)=&Apache::lc_entity_sessions::user_entity_domain();
   my %content=&Apache::lc_entity_sessions::posted_content();
   my $dest_filename=&Apache::lc_entity_urls::wrk_to_filepath($domain.'/'.$entity.'/'.$content{'wrk_filename'});
   if (&move_uploaded_into_place($dest_filename)) {
      return $dest_filename;
   } else {
      &logerror("Unable to move uploaded ($content{'remote_filename'}) to ($dest_filename)");
      return undef;
   }
}



sub handler {
# Fetch the uploaded file
   my $file=&move_uploaded_into_default_place();
   unless ($file) {
      &logerror("Failed to upload file");
      return HTTP_SERVICE_UNAVAILABLE;
   }
# Where should this go?
   my $dest_url=&uploaded_dest_url();
# Does that already exist?
   my $url_entity=&Apache::lc_entity_urls::url_to_entity($dest_url);


#
#
#   my ($entity,$domain)=&Apache::lc_entity_sessions::user_entity_domain();
#   my %content=&Apache::lc_entity_sessions::posted_content();
# Construct the URL
# 
#   &Apache::lc_entity_urls::transfer_uploaded($url);
#   &Apache::lc_entity_urls::save($url);
   &logdebug("File [$file] URL [$dest_url] Entity [$url_entity]");
   return OK;
}

1;
__END__
