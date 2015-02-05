# The LearningOnline Network with CAPA - LON-CAPA
# Implements LON-CAPA math <lm> and <dlm>
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
package Apache::lc_xml_lm;

use strict;
use Apache::lc_asset_safeeval;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_lm_html start_lm_meta, start_dlm_html start_dlm_meta);

sub start_lm_html {
  my ($p, $safe, $stack, $token) = @_;
  my $mode = $token->[2]->{'mode'};
  my $text = get_text($p, $safe, $stack, 'lm');
  if ($text eq '') {
    return '';
  }
  return output_lm($text, 0, $mode eq 'units');
}

sub start_dlm_html {
  my ($p, $safe, $stack, $token) = @_;
  my $mode = $token->[2]->{'mode'};
  my $text = get_text($p, $safe, $stack, 'dlm');
  if ($text eq '') {
    return '';
  }
  return output_lm($text, 1, $mode eq 'units');
}

sub start_lm_meta {
  my ($p, $safe, $stack, $token) = @_;
  $p->get_text('/lm');
  return '';
}

sub start_dlm_meta {
  my ($p, $safe, $stack, $token) = @_;
  $p->get_text('/dlm');
  return '';
}

##
# Called from a start tag handler, this parses the text inside the element,
# and evaluates it.
# @param {HTML::TokeParser} p - the parser
# @param {Safe} safe - safespace
# @param {Hash<string,?>} stack - where we store stuff
# @param {string} tag
# @returns {string} the evaluated text
##
sub get_text {
  my ($p, $safe, $stack, $tag) = @_;
  # NOTE: why is this so complicated ???
  my $text = $p->get_text('/'.$tag);
  $p->get_token;
  pop(@{$stack->{'tags'}});
  if (!defined $text) {
    return '';
  }
  $text = &Apache::lc_asset_safeeval::texteval($safe, $text);
  return $text;
}

##
# Returns the HTML for lm
# @param {string} text - the evaluated text
# @param {boolean} bdisplay - 1 for display mode
# @param {boolean} bunits - 1 for units mode
# @returns {string} the HTML
##
sub output_lm {
  my ($text, $bdisplay, $bunits) = @_;
  my $s = '';
  if ($bdisplay) {
    $s .= "\n<div";
  } else {
    $s .= '<span';
  }
  $s .= ' class="math" data-implicit_operators="true"';
  if ($bunits) {
    $s .= ' data-unit_mode="true"';
  } else {
    $s .= ' data-unit_mode="false"';
  }
  my $text_on_one_line = $text;
  $text_on_one_line =~ s/[\n\r]/ /g;
  $s .= ' role="math" aria-label="'.$text_on_one_line.'"';
  $s .= '>'.$text.'</';
  if ($bdisplay) {
    $s .= "div>\n";
  } else {
    $s .= 'span>';
  }
  return $s;
}

1;
__END__
