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
our @EXPORT = qw(start_html_html end_html_html
                 start_body_html end_body_html
                 start_head_html end_head_html
                 start_script_html start_script_meta start_title_meta start_meta_meta
                 start_loncapa_html end_loncapa_html);

# Ways to start HTML
#
sub start_html_html {
   return &begin_html(@_);
}

sub start_loncapa_html {
   return &begin_html(@_);
}

sub begin_html {
   my ($p,$safe,$stack,$token)=@_;
   if ($stack->{'context'}->{'start_html_emitted'}) { return ''; }
   $stack->{'context'}->{'start_html_emitted'}=1;
   return '<!DOCTYPE html>'."\n".
          '<html lang="'.&mt('language_code').'" dir="'.&mt('language_direction').'">';
}

# Ways to end HTML
#

sub end_html_html {
   return &end_html(@_);
}

sub end_loncapa_html {
   return &end_html(@_);
}

sub end_html {
   my ($p,$safe,$stack,$token)=@_;
   if ($stack->{'context'}->{'end_html_emitted'}) { return ''; }
   $stack->{'context'}->{'end_html_emitted'}=1;
   return '</html>';
}

# Start body
#
sub start_body_html {
   return &begin_body(@_);
}

sub begin_body {
   my ($p,$safe,$stack,$token)=@_;
   if ($stack->{'context'}->{'start_body_emitted'}) { return ''; }
   $stack->{'context'}->{'start_body_emitted'}=1;
   return &begin_html(@_).&begin_head(@_).&end_head(@_).'<body>';
}

# End body
#
sub end_body_html {
   return &end_body(@_);
}

sub end_body {
   my ($p,$safe,$stack,$token)=@_;
   if ($stack->{'context'}->{'end_body_emitted'}) { return ''; }
   $stack->{'context'}->{'end_body_emitted'}=1;
   return '</body>';
}

# Finish HTML document
#
sub finish_document {
   return &end_body(@_).&end_html(@_);
}

# Start head
#

sub start_head_html {
   return &begin_head(@_);
}

sub begin_head {
   my ($p,$safe,$stack,$token)=@_;
   if ($stack->{'context'}->{'start_header_emitted'}) { return ''; }
   $stack->{'context'}->{'start_header_emitted'}=1;
   return (<<ENDHEADER);
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width; initial-scale=1.0;">
<script src="/scripts/jquery-2.0.3.min.js"></script>
<script src="/scripts/mathjax/MathJax.js?config=TeX-AMS-MML_HTMLorMML"></script>
<script src="/scripts/jquery.blockUI.js"></script>
<script src="/scripts/jstree/jstree.min.js"></script>
<script src="/scripts/ckeditor/ckeditor.js"></script>
<script src="/scripts/ckeditor/adapters/jquery.js"></script>
<script src="/scripts/datepick/jquery.plugin.js"></script> 
<script src="/scripts/datepick/jquery.datepick.js"></script>
<script src="/scripts/datepick/jquery.datepick.lang.js"></script>
<script src="/scripts/jquery.dataTables.min.js"></script>
<script src="/scripts/LC_math_editor.min.js"></script>
<script src="/scripts/lc_file_upload.js"></script>
<script src="/scripts/lc_standard.js"></script>
<link rel="stylesheet" type="text/css" href="/css/lc_style.css" />
<link rel="stylesheet" type="text/css" href="/css/jquery.dataTables.css" />
<link rel="stylesheet" type="text/css" href="/scripts/datepick/flora.datepick.css">
<link rel="stylesheet" type="text/css" href="/scripts/jstree/themes/default/style.min.css" />
ENDHEADER
}

# End the header
#
sub end_head_html {
   return &end_head(@_);
}

sub end_head {
   my ($p,$safe,$stack,$token)=@_;
   if ($stack->{'context'}->{'end_header_emitted'}) { return ''; }
   $stack->{'context'}->{'end_header_emitted'}=1;
   return '</head>';
}

# Script tag
#
sub start_script_html {
   my ($p,$safe,$stack,$token)=@_;
   unless (($token->[2]->{'src'}=~/\/jquery.*\.js$/) || 
           ($token->[2]->{'src'}=~/\/jstree.*\.js$/) ||
           ($token->[2]->{'src'}=~/\/MathJax\.js$/) ||
           ($token->[2]->{'src'}=~/\/ckeditor\.js$/)) {
      return $token->[-1];
   } else {
      return '<script>';
   }
}

sub start_script_meta {
   my ($p,$safe,$stack,$token)=@_;
   $p->get_text('/script');
   $p->get_token;
   pop(@{$stack->{'tags'}});
   return '';
}

sub start_title_meta {
   my ($p,$safe,$stack,$token)=@_;
# Title should have no embedded tags, just plain text - but make sure
   my $title=&Apache::lc_xml_utils::textonly($p->get_text('/title'));
# Remember
   $stack->{'metadata'}->{'title'}=$title;
   $p->get_token;
   pop(@{$stack->{'tags'}});
   return $title;
}


sub start_meta_meta {
   my ($p,$safe,$stack,$token)=@_;
   if (($token->[2]->{'name'}) && ($token->[2]->{'content'}=~/\S/)) {
      $stack->{'metadata'}->{'hardcoded'}->{$token->[2]->{'name'}}=$token->[2]->{'content'};
   }
   return '';
}

1;
__END__
