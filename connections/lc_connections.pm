# The LearningOnline Network with CAPA - LON-CAPA
# The Cluster Connections Module
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

package Apache::lc_connections;

use strict;
use LWP::UserAgent;
use LWP::ConnCache;
use LWP::Protocol::https;
use Apache2::Const qw(:common :http);

use Apache::lc_parameters;

use vars qw($status $client);

# ================================================================
# Dispatch
# ================================================================
# ==== Dispatch an SSL request
#
sub dispatch {
   my ($method,$host,$uri,$data)=@_;
   my $response;
   my $response;
   if ($method eq 'PUT') {
      $response=$client->put('https://'.$host.'/'.$uri,Content=>$data);
   }
   if ($method eq 'POST') {
      $response=$client->post('https://'.$host.'/'.$uri,Content=>$data);
   }
   if ($method eq 'GET') {
      $response=$client->get('https://'.$host.'/'.$uri);
   }
   if ($method eq 'DELETE') {
      $response=$client->delete('https://'.$host.'/'.$uri);
   }
   return ($response->code,$response->content);
}

# ==== Copy a file
#
sub copyurl {
   my ($host,$uri,$file)=@_;
#   &Apache::cw_core_utils::ensuresubdir($file);
   my $response=$client->get('https://'.$host.'/'.$uri,':content_file' => $file);
   return ($response->code);
}

# ==== Initialize client
#
sub init_client {
   $client=LWP::UserAgent->new();
   $client->conn_cache(LWP::ConnCache->new());
   $client->conn_cache->total_capacity(100);
   $client->ssl_opts(verify_hostname => 1,
                     SSL_cert_file => &lc_certs_dir.'client.crt',
                     SSL_key_file => &lc_certs_dir.'client.key',
                     SSL_ca_file => &lc_certs_dir.'LONCAPA.crt');
}

BEGIN {
   &init_client();
}
1;
__END__
