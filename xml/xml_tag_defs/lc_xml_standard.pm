# The LearningOnline Network with CAPA - LON-CAPA
# Standard XML tags
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
package Apache::lc_xml_standard;

use strict;
use Apache::lc_ui_localize;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_html_html start_head_html start_script_html);

sub start_html_html {
   my ($p,$safe,$stack,$token)=@_;
   return '<html lang="'.&mt('language_code').'" dir="'.&mt('language_direction').'">';
}

sub start_head_html {
   my ($p,$safe,$stack,$token)=@_;
   return (<<ENDHEADER);
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width; initial-scale=1.0;">
<script src="/scripts/jquery-2.0.3.min.js"></script>
<script src="/scripts/mathjax/MathJax.js?config=default"></script>
<script src="/scripts/jquery.blockUI.js"></script>
<script src="/scripts/jstree/jstree.min.js"></script>
<script src="/scripts/ckeditor/ckeditor.js"></script>
<script src="/scripts/ckeditor/adapters/jquery.js"></script>
<script src="/scripts/datepick/jquery.plugin.js"></script> 
<script src="/scripts/datepick/jquery.datepick.js"></script>
<script src="/scripts/datepick/jquery.datepick.lang.js"></script>
<script src="/scripts/lc_standard.js"></script>
<link rel="stylesheet" type="text/css" href="/css/lc_style.css" />
<link rel="stylesheet" type="text/css" href="/scripts/datepick/flora.datepick.css">
<link rel="stylesheet" type="test/css" href="/scripts/jstree/themes/default/style.min.css" />
ENDHEADER
}

sub start_script_html {
   my ($p,$safe,$stack,$token)=@_;
   unless (($token->[2]->{'src'}=~/\/jquery.*\.js$/) || 
           ($token->[2]->{'src'}=~/\/jstree.*\.js$/) ||
           ($token->[2]->{'src'}=~/\/MathJax\.js$/) ||
           ($token->[2]->{'src'}=~/\/ckeditor\.js$/)) {
      return $token->[-1];
   }
}

1;
__END__
