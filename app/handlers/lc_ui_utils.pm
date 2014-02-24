# The LearningOnline Network with CAPA - LON-CAPA
# UI Utilities
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
package Apache::lc_ui_utils;

use strict;
use JSON::DWIW;
use LWP::UserAgent;
use LWP::ConnCache;
use File::Util;
use Time::y2038;
use Apache2::Const qw(:common :http);
use Cache::Memcached;

require Exporter;

our @ISA = qw (Exporter);
our @EXPORT = qw(core get_content clean_username clean_domain);

use constant FILEROOT => '/home/cw/ui/';

# Handle to talk to core
my $client;
# Handle to talk to memcached in own namespace
my $memd;

# ==== Send local requests to the local core
#
sub core {
   my ($method,$uri,$data)=@_;
   if ($ENV{'lc_session'}->{'id'}) {
      if ($uri=~/\?/) {
         $uri.='&s='.$ENV{'lc_session'}->{'id'};
      } else {
         $uri.='?s='.$ENV{'lc_session'}->{'id'};
      }
   }
   my $response;
   if ($method eq 'PUT') {
      $response=$client->put('http://localhost/localcore/'.$uri,Content=>$data);
   }
   if ($method eq 'POST') {
      $response=$client->post('http://localhost/localcore/'.$uri,Content=>$data);
   }
   if ($method eq 'GET') {
      $response=$client->get('http://localhost/localcore/'.$uri);
   }
   if ($method eq 'DELETE') {
      $response=$client->delete('http://localhost/localcore/'.$uri);
   }
   return ($response->code,$response->content);
}

# ==== Get POSTed content
#
sub get_content {
   my ($r)=@_;
   my $content='';
   if ($r->headers_in->{"Content-length"}>0) {
      $r->read($content,$r->headers_in->{"Content-length"});
   }
   return split(/[\&\=]/,$content);
}

# ==== Clean up usernames and domains
#
sub clean_username {
   my ($username)=@_;
   $username=~s/\s//gs;
   $username=~s/\///gs;
   return $username;
}

sub clean_domain {
   my ($domain)=@_;
   $domain=~s/\s//gs;
   $domain=~s/\///gs;
   return $domain;
}

BEGIN {
   $memd=new Cache::Memcached({'servers' => ['127.0.0.1:11211'],'namespace' => 'lc_app'});
}

1;
__END__
