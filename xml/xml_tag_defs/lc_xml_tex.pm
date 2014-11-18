# The LearningOnline Network with CAPA - LON-CAPA
# Implements the LaTeX-related-blocks
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
package Apache::lc_xml_tex;

use strict;
use Apache::lc_asset_safeeval;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_tm_html start_tm_meta, start_dtm_html start_dtm_meta);

sub start_tm_html {
   my ($p,$safe,$stack,$token)=@_;
   return '\\('.&tex_eval($p,$safe,$stack,$token,'tm').'\\)';
}

sub start_dtm_html {
   my ($p,$safe,$stack,$token)=@_;
   return '\\['.&tex_eval($p,$safe,$stack,$token,'dtm').'\\]';
}

sub start_tm_meta {
   &start_im_html(@_);
   return '';
}

sub start_dtm_meta {
   &start_dm_html(@_);
   return '';
}

sub tex_eval {
   my ($p,$safe,$stack,$token,$end)=@_;
   my $text=$p->get_text('/'.$end);
   $p->get_token;
   pop(@{$stack->{'tags'}});
   $text=~s/\\/\\\\/gs;
   return &Apache::lc_asset_safeeval::texteval($safe,$text);
}

1;
__END__
