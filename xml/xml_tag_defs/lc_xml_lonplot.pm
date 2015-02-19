# The LearningOnline Network with CAPA
# Dynamic plot
#
# $Id: lonplot.pm,v 1.175 2014/06/19 17:23:50 raeburn Exp $
#
# Copyright Michigan State University Board of Trustees
#
# This file is part of the LearningOnline Network with CAPA (LON-CAPA).
#
# LON-CAPA is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# LON-CAPA is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with LON-CAPA; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# /home/httpd/html/adm/gpl.txt
#
# http://www.lon-capa.org/
#




package Apache::lc_xml_lonplot;

use strict;
use warnings FATAL=>'all';
no warnings 'uninitialized';

use Apache::lc_asset_xml();
use Apache::lc_asset_safeeval();

use HTML::PullParser;

our @ISA = qw(Exporter);

# Export all tags that this module defines in the list below
our @EXPORT = qw(start_gnuplot_html  end_gnuplot_html
                 start_xtics_html end_xtics_html
                 start_ytics_html end_ytics_html
                 start_tic_html end_tic_html
                 start_key_html end_key_html
                 start_title_html end_title_html
                 start_xlabel_html end_xlabel_html
                 start_ylabel_html end_ylabel_html
                 start_label_html end_label_html
                 start_curve_html end_curve_html
                 start_function_html end_function_html
                 start_data_html end_data_html
                 start_axis_html end_axis_html);


=pod

## 
## Description of data structures:
##
##  %plot       %key    %axis
## --------------------------
##  height      title   color
##  width       box     xmin
##  bgcolor     pos     xmax
##  fgcolor             ymin
##  transparent         ymax
##  grid
##  border
##  font
##  align
##
##  @labels: $labels[$i] = \%label
##           %label: text, xpos, ypos, justify, rotate, zlayer
##
##  @curves: $curves[$i] = \%curve
##           %curve: name, linestyle, ( function | data )
##
##  $curves[$i]->{'data'} = [ [x1,x2,x3,x4],
##                            [y1,y2,y3,y4] ]
##

###################################################################
##                                                               ##
##        Tests used in checking the validitity of input         ##
##                                                               ##
###################################################################

=cut

my $max_str_len = 50;    # if a label, title, xlabel, or ylabel text
                         # is longer than this, it will be truncated.

my %linetypes =                 # For png use these linetypes.
    (
     solid          => 1,
     dashed         => 0
    );
my %ps_linetypes =              # For ps the line types are different!
   (
    solid          => 1,
    dashed         => 7
   );

my %linestyles = 
    (
     lines          => 2,     # Maybe this will be used in the future
     linespoints    => 2,     # to check on whether or not they have 
     dots           => 2,     # supplied enough <data></data> fields
     points         => 2,     # to use the given line style.  But for
     steps          => 2,     # now there are more important things 
     fsteps         => 2,     # for me to deal with.
     histeps        => 2,
     errorbars      => 3,
     xerrorbars     => [3,4],
     yerrorbars     => [3,4],
     xyerrorbars    => [4,6],
     boxes          => 3,
     filledcurves   => 2,
     vector         => 4
    );              

my $int_test       = sub {$_[0]=~s/\s+//g;$_[0]=~/^\d+$/};
my $real_test      = 
    sub {$_[0]=~s/\s+//g;$_[0]=~/^[+-]?\d*\.?\d*([eE][+-]\d+)?$/};
my $pos_real_test  =
    sub {$_[0]=~s/\s+//g;$_[0]=~/^[+]?\d*\.?\d*([eE][+-]\d+)?$/};
my $color_test = sub {$_[0]=~s/\s+//g;$_[0]=~s/^x/#/;$_[0]=~/^\#[\da-fA-F]{6}$/};
my $onoff_test     = sub {$_[0]=~/^(on|off)$/};
my $key_pos_test   = sub {$_[0]=~/^(top|bottom|right|left|outside|below| )+$/};
my $sml_test       = sub {$_[0]=~/^(\d+|small|medium|large)$/};
my $linestyle_test = sub {exists($linestyles{$_[0]})};
my $words_test     = sub {$_[0]=~s/\s+/ /g;$_[0]=~/^([\w~!\@\#\$\%^&\*\(\)-=_\+\[\]\{\}:\;\'<>,\.\/\?\\]+ ?)+$/};

my $arrowhead_test = sub{$_[0]=~/^(nohead|head|heads| )+$/};
my $arrowstyle_test= sub{$_[0]=~/^(filled|empty|nofilled)+$/};
my $degree_test  = sub{&$pos_real_test($_[0]) && ($_[0] <= 360.0)};

###################################################################
##                                                               ##
##                      Attribute metadata                       ##
##                                                               ##
###################################################################
my @gnuplot_edit_order = 
    qw/alttag bgcolor fgcolor height width texwidth fontface font texfont
    transparent grid samples 
    border align plotcolor plottype gridtype lmargin rmargin
    tmargin bmargin major_ticscale minor_ticscale boxwidth gridlayer fillstyle
    pattern solid/;

my $margin_choices = ['default',0..20];

my %gnuplot_defaults = 
    (
     alttag       => {
         default     => 'dynamically generated plot',
         test        => $words_test,
         description => 'Brief description of the plot',
         edit_type   => 'entry',
         size        => '40'
         },
     height       => {
         default     => 300,
         test        => $int_test,
         description => 'Height of image (pixels)',
         edit_type   => 'entry',
         size        => '10'
         },
     width        => {
         default     => 400,
         test        => $int_test,
         description => 'Width of image (pixels)',
         edit_type   => 'entry',
         size        => '10'
         },
     bgcolor      => {
         default     => 'xffffff',
         test        => $color_test, 
         description => 'Background color of image (xffffff)',
         edit_type   => 'entry',
         size        => '10',
         class       => 'colorchooser'
         },
     fgcolor      => {
         default     => 'x000000',
         test        => $color_test,
         description => 'Foreground color of image (x000000)',
         edit_type   => 'entry',
         size        => '10',
         class       => 'colorchooser'
         },
     transparent  => {
         default     => 'off',
         test        => $onoff_test, 
         description => 'Transparent image',
         edit_type   => 'onoff'
         },
     grid         => {
         default     => 'on',
         test        => $onoff_test, 
         description => 'Display grid',
         edit_type   => 'onoff'
         },
     gridlayer    => {
         default     => 'off',
         test        => $onoff_test, 
         description => 'Display grid front layer over filled boxes or filled curves',
         edit_type   => 'onoff'
         },
     box_border   => {
         default     => 'noborder',
         test        => sub {$_[0]=~/^(noborder|border)$/},
         description => 'Draw border for boxes',
         edit_type   => 'choice',
         choices     => ['border','noborder']
         },
     border       => {
         default     => 'on',
         test        => $onoff_test, 
         description => 'Draw border around plot',
         edit_type   => 'onoff'
         },
     font         => {
         default     => '9',
         test        => $sml_test,
         description => 'Font size to use in web output (pts)',
         edit_type   => 'choice',
         choices     => [['5','5 (small)'],'6','7','8',['9','9 (medium)'],'10',['11','11 (large)'],'12','15']
         },
     fontface     => {
        default     => 'sans-serif',
        test        => sub {$_[0]=~/^(sans-serif|serif|classic)$/},
        description => 'Type of font to use',
        edit_type   => 'choice',
        choices     => ['sans-serif','serif', 'classic']
        },
     samples      => {
         default     => '100',
         test        => $int_test,
         description => 'Number of samples for non-data plots',
         edit_type   => 'choice',
         choices     => ['100','200','500','1000','2000','5000']
         },
     align        => {
         default     => 'middle',
         test        => sub {$_[0]=~/^(left|right|middle|center)$/},
         description => 'Alignment for image in HTML',
         edit_type   => 'choice',
         choices     => ['left','right','middle']
         },
     texwidth     => {
         default     => '93',
         test        => $int_test,
         description => 'Width of plot when printed (mm)',
         edit_type   => 'entry',
         size        => '5'
         },
     texfont      => {
         default     => '22',
         test        => $int_test,
         description => 'Font size to use in TeX output (pts):',
         edit_type   => 'choice',
         choices     => [qw/8 10 12 14 16 18 20 22 24 26 28 30 32 34 36/],
         },
     plotcolor    => {
         default     => 'monochrome',
         test        => sub {$_[0]=~/^(monochrome|color|colour)$/},
         description => 'Color setting for printing:',
         edit_type   => 'choice',
         choices     => [qw/monochrome color colour/],
         },
     pattern      => {
         default     => '',
         test        => $int_test,
         description => 'Pattern value for boxes:',
         edit_type   => 'choice',
         choices     => [0,1,2,3,4,5,6]
         },
     solid        => {
         default     => 0,
         test        => $real_test,
         description => 'The density of fill style for boxes',
         edit_type   => 'entry',
         size        => '5'
         },
     fillstyle    => {
         default     => 'empty',
         test        => sub {$_[0]=~/^(empty|solid|pattern)$/},
         description => 'Filled style for boxes:',
         edit_type   => 'choice',
         choices     => ['empty','solid','pattern']
         },
     plottype     => {
         default     => 'Cartesian',
         test        => sub {$_[0]=~/^(Polar|Cartesian)$/},
         description => 'Plot type:',
         edit_type   => 'choice',
         choices     => ['Cartesian','Polar']
         },
     gridtype     => {
         default     => 'Cartesian',
         test        => sub {$_[0]=~/^(Polar|Cartesian|Linear-Log|Log-Linear|Log-Log)$/},
         description => 'Grid type:',
         edit_type   => 'choice',
         choices     => ['Cartesian','Polar','Linear-Log','Log-Linear','Log-Log']
         },
     lmargin      => {
         default     => 'default',
         test        => sub {$_[0]=~/^(default|\d+)$/},
         description => 'Left margin width (pts):',
         edit_type   => 'choice',
         choices     => $margin_choices,
         },
     rmargin      => {
         default     => 'default',
         test        => sub {$_[0]=~/^(default|\d+)$/},
         description => 'Right margin width (pts):',
         edit_type   => 'choice',
         choices     => $margin_choices,
         },
     tmargin      => {
         default     => 'default',
         test        => sub {$_[0]=~/^(default|\d+)$/},
         description => 'Top margin width (pts):',
         edit_type   => 'choice',
         choices     => $margin_choices,
         },
     bmargin      => {
         default     => 'default',
         test        => sub {$_[0]=~/^(default|\d+)$/},
         description => 'Bottom margin width (pts):',
         edit_type   => 'choice',
         choices     => $margin_choices,
         },
     boxwidth     => {
         default     => '',
         test        => $real_test, 
         description => 'Width of boxes, default is auto',
         edit_type   => 'entry',
         size        => '5'
         },
     major_ticscale  => {
         default     => '1',
         test        => $real_test,
         description => 'Size of major tic marks (plot coordinates)',
         edit_type   => 'entry',
         size        => '5'
         },
     minor_ticscale  => {
         default     => '0.5',
         test        => $real_test,
         description => 'Size of minor tic mark (plot coordinates)',
         edit_type   => 'entry',
         size        => '5'
         },
     );

my %key_defaults = 
    (
     title => { 
         default => '',
         test => $words_test,
         description => 'Title of key',
         edit_type   => 'entry',
         size        => '40'
         },
     box   => { 
         default => 'off',
         test => $onoff_test,
         description => 'Draw a box around the key?',
         edit_type   => 'onoff'
         },
     pos   => { 
         default => 'top right', 
         test => $key_pos_test, 
         description => 'Position of the key on the plot',
         edit_type   => 'choice',
         choices     => ['top left','top right','bottom left','bottom right',
                         'outside','below']
         }
     );

my %label_defaults = 
    (
     xpos    => {
         default => 0,
         test => $real_test,
         description => 'X position of label (graph coordinates)',
         edit_type   => 'entry',
         size        => '10'
         },
     ypos    => {
         default => 0, 
         test => $real_test,
         description => 'Y position of label (graph coordinates)',
         edit_type   => 'entry',
         size        => '10'
         },
     justify => {
         default => 'left',    
         test => sub {$_[0]=~/^(left|right|center)$/},
         description => 'justification of the label text on the plot',
         edit_type   => 'choice',
         choices     => ['left','right','center']
     },
     rotate => {
         default => 0,
         test => $real_test,
         description => 'Rotation of label (degrees)',
         edit_type   => 'entry',
         size        => '10',
     },
     zlayer => {
         default => '',
         test => sub {$_[0]=~/^(front|back)$/},
         description => 'Z position of label',
         edit_type   => 'choice',
         choices     => ['front','back'], 
     },
     );

my @tic_edit_order = ('location','mirror','start','increment','end',
                      'minorfreq');
my %tic_defaults =
    (
     location => {
         default => 'border', 
         test => sub {$_[0]=~/^(border|axis)$/},
         description => 'Location of major tic marks',
         edit_type   => 'choice',
         choices     => ['border','axis']
         },
     mirror => {
         default => 'on', 
         test => $onoff_test,
         description => 'Mirror tics on opposite axis?',
         edit_type   => 'onoff'
         },
     start => {
         default => '-10.0',
         test => $real_test,
         description => 'Start major tics at',
         edit_type   => 'entry',
         size        => '10'
         },
     increment => {
         default => '1.0',
         test => $real_test,
         description => 'Place a major tic every',
         edit_type   => 'entry',
         size        => '10'
         },
     end => {
         default => ' 10.0',
         test => $real_test,
         description => 'Stop major tics at ',
         edit_type   => 'entry',
         size        => '10'
         },
     minorfreq => {
         default => '0',
         test => $int_test,
         description => 'Number of minor tics per major tic mark',
         edit_type   => 'entry',
         size        => '10'
         }, 
     rotate => {
         default => 'off',
         test    => $onoff_test,
         description => 'Rotate tic label by 90 degrees if on',
         edit_type   => 'onoff'
     }
     );

my @axis_edit_order = ('color','xmin','xmax','ymin','ymax','xformat', 'yformat', 'xzero', 'yzero');
my %axis_defaults = 
    (
     color   => {
         default => 'x000000', 
         test => $color_test,
         description => 'Color of grid lines (x000000)',
         edit_type   => 'entry',
         size        => '10',
         class       => 'colorchooser'
         },
     xmin      => {
         default => '-10.0',
         test => $real_test,
         description => 'Minimum x-value shown in plot',
         edit_type   => 'entry',
         size        => '10'
         },
     xmax      => {
         default => ' 10.0',
         test => $real_test,
         description => 'Maximum x-value shown in plot',         
         edit_type   => 'entry',
         size        => '10'
         },
     ymin      => {
         default => '-10.0',
         test => $real_test,
         description => 'Minimum y-value shown in plot',         
         edit_type   => 'entry',
         size        => '10'
         },
     ymax      => {
         default => ' 10.0',
         test => $real_test,
         description => 'Maximum y-value shown in plot',         
         edit_type   => 'entry',
         size        => '10'
        },
     xformat      => {
         default     => 'on',
         test        => sub {$_[0]=~/^(on|off|\d+(f|F|e|E))$/},
         description => 'X-axis number formatting',
         edit_type   => 'choice',
         choices     => ['on', 'off', '2e', '2f'],
         },
     yformat      => {
         default     => 'on',
         test        => sub {$_[0]=~/^(on|off|\d+(f|F|e|E))$/},
         description => 'Y-axis number formatting',
         edit_type   => 'choice',
         choices     => ['on', 'off', '2e', '2f'],
         },
     
     xzero => {
        default => 'off',
        test    => sub {$_[0]=~/^(off|line|thick-line|dotted)$/},
        description => 'Show x-zero (y=0) axis',
        edit_type  => 'choice',
        choices => ['off', 'line', 'thick-line', 'dotted'],
        },
     
     yzero => {
        default => 'off',
        test    => sub {$_[0]=~/^(off|line|thick-line|dotted)$/},
        description => 'Show y-zero (x=0) axis',
        edit_type  => 'choice',
        choices => ['off', 'line', 'thick-line', 'dotted'],
        },
     );


my @curve_edit_order = ('color','name','linestyle','linewidth','linetype',
                        'pointtype','pointsize','limit', 'arrowhead', 'arrowstyle', 
                        'arrowlength', 'arrowangle', 'arrowbackangle'
    );

my %curve_defaults = 
    (
     color     => {
         default => 'x000000',
         test => $color_test,
         description => 'Color of curve (x000000)',
         edit_type   => 'entry',
         size        => '10',
         class       => 'colorchooser'
         },
     name      => {
         default => '',
         test => $words_test,
         description => 'Name of curve to appear in key',
         edit_type   => 'entry',
         size        => '20'
         },
     linestyle => {
         default => 'lines',
         test => $linestyle_test,
         description => 'Plot with:',
         edit_type   => 'choice',
         choices     => [keys(%linestyles)]
         },
     linewidth => {
         default     => 1,
         test        => $int_test,
         description => 'Line width (may not apply to all plot styles)',
         edit_type   => 'choice',
         choices     => [1,2,3,4,5,6,7,8,9,10]
         },
     linetype => {
         default     => 'solid',
         test        => sub {$_[0]=~/^(solid|dashed)$/},
         description => 'Line type (may not apply to all plot styles)',
         edit_type   => 'choice',
         choices     => ['solid', 'dashed']
         }, 
     pointsize => {
         default     => 1,
         test        => $pos_real_test,
         description => 'Point size (may not apply to all plot styles)',
         edit_type   => 'entry',
         size        => '5'
         },
     pointtype => {
         default     => 1,
         test        => $int_test,
         description => 'Point type (may not apply to all plot styles)',
         edit_type   => 'choice',
         choices     => [0,1,2,3,4,5,6]
         },
     limit     => {
         default     => 'closed',
         test        => sub {$_[0]=~/^(above|below|closed|x1|x2|y1|y2)$/},
         description => 'Point to fill -- for filledcurves',
         edit_type   => 'choice',
         choices     => ['above', 'below', 'closed','x1','x2','y1','y2']
         },
     arrowhead => {
         default     => 'head',
         test        => $arrowhead_test,
         description => 'Vector arrow head type',
         edit_type   => 'choice',
         choices     => ['nohead', 'head', 'heads']
     },
     arrowstyle => {
         default     => 'filled',
         test        => $arrowstyle_test,
         description => 'Vector arrow head style',
         edit_type   => 'choice',
         choices     => ['filled', 'empty', 'nofilled']
     },
     arrowlength => {
         default     => 0.02,
         test        => $pos_real_test,
         description => "Length of vector arrow (only applies to vector plots)",
         edit_type   => 'entry',
         size        => '5'
     },
     arrowangle  => {
        default      => 10.0,
        test         => $degree_test,
        description  => 'Angle of arrow branches to arrow body (only applies to vector plots)',
        edit_type    => 'entry',
        size         => '5'
     },

     arrowbackangle => {
         default    => 90.0,
         test       => $degree_test,
         descripton => 'Angle of arrow back lines to branches.',
         edit_type  => 'entry',
         size       => '5'
     }

     );

###################################################################
##                                                               ##
##                    parsing and edit rendering                 ##
##                                                               ##
###################################################################

undef %Apache::lc_xml_lonplot::plot;
my (%key,%axis,$title,$xlabel,$ylabel,@labels,@curves,%xtics,%ytics);

my $current_tics;               # Reference to the current tick hash

sub start_gnuplot_html {
    undef(%Apache::lc_xml_lonplot::plot);   undef(%key);    undef(%axis);
    undef($title);  undef($xlabel); undef($ylabel);
    undef(@labels); undef(@curves);
    undef(%xtics);  undef(%ytics);
    #
    my ($p, $safe, $stack, $token) = @_;
    my $result='';
#     &Apache::lonxml::register('Apache::lc_xml_lonplot',
#              ('title','xlabel','ylabel','key','axis','label','curve',
#               'xtics','ytics'));
#     push (@Apache::lonxml::namespace,'lonplot');
    &get_attributes(\%Apache::lc_xml_lonplot::plot,\%gnuplot_defaults,$token,$token->[1]);
    return $result;
}

sub end_gnuplot_html {
    my ($p, $safe, $stack, $token) = @_;
#     pop @Apache::lonxml::namespace;
#     &Apache::lonxml::deregister('Apache::lc_xml_lonplot',
#         ('title','xlabel','ylabel','key','axis','label','curve'));
    my $result = '';

    &check_inputs(); # Make sure we have all the data we need
    ##
    ## Write the plot description to the file
    my $gnuplot_script = &write_gnuplot_file();
    # add required scripts (this would be better elsewhere, to avoid doubles, but...)
    $result .= '<script src="/scripts/gnuplot/canvas_term/canvastext.js"></script>'."\n";
    $result .= '<script src="/scripts/gnuplot/canvas_term/canvasmath.js"></script>'."\n";
    $result .= '<script src="/scripts/gnuplot/canvas_term/gnuplot_common.js"></script>'."\n";
    $result .= '<script src="/scripts/gnuplot/canvas_term/gnuplot_dashedlines.js"></script>'."\n";
    $result .= '<script src="/scripts/gnuplot/canvas_term/gnuplot_mouse.js"></script>'."\n";
    $result .= '<script src="/scripts/gnuplot/gnuplotjs/gnuplot_api.js"></script>'."\n";
    $result .= '<script>gnuplotjs_url = "/scripts/gnuplot/gnuplotjs/gnuplot.js";</script>'."\n";
    $result .= '<script src="/scripts/gnuplot/gnuplotjscanvas.js"></script>'."\n";
    ## return canvas element and script for the plot
    my $id = &Apache::lc_asset_xml::open_tag_attribute('id', $stack);
    if (!defined $id) {
        $id = 'my_gnuplot_canvas_'.int(rand(1000)); # this should not happen anyway, the parser generates an id
    }
    my $width = $Apache::lc_xml_lonplot::plot{'width'};
    my $height = $Apache::lc_xml_lonplot::plot{'height'};
    my $align = $Apache::lc_xml_lonplot::plot{'align'};
    my $alt = $Apache::lc_xml_lonplot::plot{'alttag'};
    $result .= '<canvas id="'.$id.'" width="'.$width.'" height="'.$height.
        '" alt="'.$alt.'" oncontextmenu="return false;" tabindex="0"';
    if ($align eq 'right') {
        $result .= ' style="float: right"';
    }
    $result .= '></canvas>'."\n";
    $result .= '<div id="'.$id.'_script'.'" style="display:none">'.$gnuplot_script.'</div>'."\n";
    $result .= '<script>run_gnuplot_script(document.getElementById("'.$id.'_script'.'").textContent, "'.$id.'");</script>';
    
    return $result;
}


##--------------------------------------------------------------- xtics
sub start_xtics_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result='';
    &get_attributes(\%xtics,\%tic_defaults,$token,$token->[1]);
    $current_tics = \%xtics;
#         &Apache::lonxml::register('Apache::lc_xml_lonplot', 'tic');
    return $result;
}

sub end_xtics_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result = '';
#         &Apache::lonxml::deregister('Apache::lc_xml_lonplot', 'tic');
    return $result;
}

##--------------------------------------------------------------- ytics
sub start_ytics_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result='';
    &get_attributes(\%ytics,\%tic_defaults,$token,$token->[1]);
    $current_tics = \%ytics;
#         &Apache::lonxml::register('Apache::lc_xml_lonplot', 'tic');
    return $result;
}

sub end_ytics_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result = '';
#         &Apache::lonxml::deregister('Apache::lc_xml_lonplot', 'tic');
    return $result;
}


##----------------------------------------------------------------
#
#  Tic handling:
#   The <tic> tag allows users to specify exact Tic positions and labels
#   for each axis.  In this version we only support level 0 tics (major tic).
#   Each tic has associated with it a position and a label
#   $current_tics is a reference to the current tick description hash.
#   We add elements to an array  in that has: ticspecs whose elements
#   are 'pos' - the tick position and 'label' - the tic label.
#


sub start_tic_html {
    my ($p, $safe, $stack, $token) = @_;

    my $result = '';
    my $tic_location = $token->[2]->{'location'};
    my $tic_label    = $p->get_text('/tic');

    # Tic location must e a real:

    if (!&$real_test($tic_location)) {
        warning("Tic location: $tic_location must be a real number");
    } else {

        if (!defined  $current_tics->{'ticspecs'}) {
            $current_tics->{'ticspecs'} = [];
        }
        my $ticspecs = $current_tics->{'ticspecs'};
        push (@$ticspecs, {'pos' => $tic_location, 'label' => $tic_label});
    }

    return $result;
}

sub end_tic_html {
    return '';
}

##-----------------------------------------------------------------font
my %font_properties =
    (
     'classic'    => {
         face       => 'classic',
         file       => 'DejaVuSansMono-Bold',
         printname  => 'Helvetica',
         tex_no_file => 1,
     },
     'sans-serif' => {
         face       => 'sans-serif',
         file       => 'DejaVuSans',
         printname  => 'DejaVuSans',
     },
     'serif'      => {
         face       => 'serif',
         file       => 'DejaVuSerif',
         printname  => 'DejaVuSerif',
     },
     );

sub get_font {
    my ($size, $selected_font);

    if ( $Apache::lc_xml_lonplot::plot{'font'} =~ /^(small|medium|large)/) {
        $selected_font = $font_properties{'classic'};
        if ( $Apache::lc_xml_lonplot::plot{'font'} eq 'small') {
            $size = '5';
        } elsif ( $Apache::lc_xml_lonplot::plot{'font'} eq 'medium') {
            $size = '9';
        } elsif ( $Apache::lc_xml_lonplot::plot{'font'} eq 'large') {
            $size = '11';
        } else {
            $size = '9';
        }
    } else {
        $size = $Apache::lc_xml_lonplot::plot{'font'};
        $selected_font = $font_properties{$Apache::lc_xml_lonplot::plot{'fontface'}};
    }
    return ($size, $selected_font);
}

##----------------------------------------------------------------- key
sub start_key_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result='';
    &get_attributes(\%key,\%key_defaults,$token,$token->[1]);
    return $result;
}

sub end_key_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result = '';
    return $result;
}

sub parse_label {
    my ($text) = @_;
    my %ARGS =
    (
        start       => "'S',tagname,attr,attrseq,text,line",
        end         => "'E',tagname,text,line",
        text        => "'T',text,is_cdata,line",
        process     => "'PI',token0,text,line",
        comment     => "'C',text,line",
        declaration => "'D',text,line",
    );
    my $parser=HTML::PullParser->new(doc => \$text, %ARGS);
    my $result;
    while (my $token=$parser->get_token) {
        if ($token->[0] eq 'S') {
            if ($token->[1] eq 'sub') {
                $result .= '_{';
            } elsif ($token->[1] eq 'sup') {
                $result .= '^{';
            } else {
                $result .= $token->[4];
            }
        } elsif ($token->[0] eq 'E') {
            if ($token->[1] eq 'sub'
                || $token->[1] eq 'sup') {
                $result .= '}';
            } else {
                $result .= $token->[2];
            }
        } elsif ($token->[0] eq 'T') {
            $result .= &replace_entities($token->[1]);
        }
    }
    return $result;
}

my %lookup = 
   (  # Greek alphabet:
      
      '(Alpha|#913)'   => "\x{391}",
      '(Beta|#914)'    => "\x{392}",
      '(Chi|#935)'     => "\x{3A7}",
      '(Delta|#916)'   => "\x{394}",
      '(Epsilon|#917)' => "\x{395}",
      '(Phi|#934)'     => "\x{3A6}",
      '(Gamma|#915)'   => "\x{393}",
      '(Eta|#919)'     => "\x{397}",
      '(Iota|#921)'    => "\x{399}",
      '(Kappa|#922)'   => "\x{39A}",
      '(Lambda|#923)'  => "\x{39B}",
      '(Mu|#924)'      => "\x{39C}",
      '(Nu|#925)'      => "\x{39D}",
      '(Omicron|#927)' => "\x{39F}",
      '(Pi|#928)'      => "\x{3A0}",
      '(Theta|#920)'   => "\x{398}",
      '(Rho|#929)'     => "\x{3A1}",
      '(Sigma|#931)'   => "\x{3A3}",
      '(Tau|#932)'     => "\x{3A4}",
      '(Upsilon|#933)' => "\x{3A5}",
      '(Omega|#937)'   => "\x{3A9}",
      '(Xi|#926)'      => "\x{39E}",
      '(Psi|#936)'     => "\x{3A8}",
      '(Zeta|#918)'    => "\x{396}",
      '(alpha|#945)'   => "\x{3B1}",
      '(beta|#946)'    => "\x{3B2}",
      '(chi|#967)'     => "\x{3C7}",
      '(delta|#948)'   => "\x{3B4}",
      '(epsilon|#949)' => "\x{3B5}",
      '(phi|#966)'     => "\x{3C6}",
      '(gamma|#947)'   => "\x{3B3}",
      '(eta|#951)'     => "\x{3B7}",
      '(iota|#953)'    => "\x{3B9}",
      '(kappa|#954)'   => "\x{3BA}",
      '(lambda|#955)'  => "\x{3BB}",
      '(mu|#956)'      => "\x{3BC}",
      '(nu|#957)'      => "\x{3BD}",
      '(omicron|#959)' => "\x{3BF}",
      '(pi|#960)'      => "\x{3C0}",
      '(theta|#952)'   => "\x{3B8}",
      '(rho|#961)'     => "\x{3C1}",
      '(sigma|#963)'   => "\x{3C3}",
      '(tau|#964)'     => "\x{3C4}",
      '(upsilon|#965)' => "\x{3C5}",
      '(omega|#969)'   => "\x{3C9}",
      '(xi|#958)'      => "\x{3BE}",
      '(psi|#968)'     => "\x{3C8}",
      '(zeta|#950)'    => "\x{3B6}",
      '(thetasym|#977)' => "\x{3d1}",
      '(upsih|#978)'   => "\x{3d2}",
      '(piv|#982)'     => "\x{3d6}",


      # Punctuation:
      
      '(quot|#034)'   => '\42',
      '(amp|#038)'    => '\46',
      '(lt|#060)'     => '\74',
      '(gt|#062)'     => '\76',
      '#131'          => "\x{192}",
      '#132'          => "\x{201e}",
      '#133'          => "\x{2026}",
      '#134'          => "\x{2020}",
      '#135'          => "\x{2021}",
      '#136'          => '\\\\^',
      '#137'          => "\x{2030}", # Per Mille <FIX>
      '#138'          => "\x{160}", # S-Caron <FIX>
      '#139'          => '<',
      '#140'          => "\x{152}", # AE ligature <FIX>
      '#145'          => "\x{2018}",
      '#146'          => "\x{2019}",
      '#147'          => "\x{201c}", # Left " <FIX>
      '#148'          => '\\"',      # Right " <FIX>
      '#149'          => "\x{2022}",
      '#150'          => "\x{2013}",  # en dash
      '#151'          => "\x{2014}",  # em dash
      '#152'          => '\\\\~',
      '#153'          => "\x{2122}", # trademark

      # Accented letters, and other furreign language glyphs.

      '#154'          => "\x{161}", # small s-caron no ps.
      '#155'          => '\76',     # >
      '#156'          => "\x{153}", # oe ligature.<FIX>
      '#159',         => "\x{178}", # Y-umlaut - can't print <FIX>
      '(nbsp|#160)'   => ' ',       # non breaking space.
      '(iexcl|#161)'  => "\x{a1}",  # inverted !
      '(cent|#162)'   => "\x{a2}",  # Cent currency.
      '(pound|#163)'  => "\x{a3}",  # GB Pound currency.
      '(curren|#164)' => "\x{a4}",  # Generic currency symb. <FIX>
      '(yen|#165)'    => "\x{a5}",  # Yen currency.
      '(brvbar|#166)' => "\x{a6}",  # Broken vert bar no print.
      '(sect|#167)'   => "\x{a7}",  # Section symbol.
      '(uml|#168)'    => "\x{a8}",  # 'naked' umlaut.
      '(copy|#169)'   => "\x{a9}",  # Copyright symbol.
      '(ordf|#170)'   => "\x{aa}",  # Feminine ordinal.
      '(laquo|#171)'  => "\x{ab}",  # << quotes.
      '(not|#172)'    => "\x{ac}",  # Logical not.
      '(shy|#173)'    => "\x{ad}",  # soft hyphen.
      '(reg|#174)'    => "\x{ae}",  # Registered tm.
      '(macr|#175)'   => "\x{af}",  # 'naked' macron (overbar).
      '(deg|#176)'    => "\x{b0}",  # Degree symbo..`
      '(plusmn|#177)' => "\x{b1}",  # +/- symbol.
      '(sup2|#178)'   => "\x{b2}",  # Superscript 2.
      '(sup3|#179)'   => "\x{b3}",  # Superscript 3.
      '(acute|#180)'  => "\x{b4}",  # 'naked' acute accent.
      '(micro|#181)'  => "\x{b5}",  # Micro (small mu).
      '(para|#182)'   => "\x{b6}",  # Paragraph symbol.
      '(middot|#183)' => "\x{b7}",  # middle dot
      '(cedil|#184)'  => "\x{b8}",  # 'naked' cedilla.
      '(sup1|#185)'   => "\x{b9}",  # superscript 1.
      '(ordm|#186)'   => "\x{ba}",  # masculine ordinal.
      '(raquo|#187)', => "\x{bb}",  # Right angle quotes.
      '(frac14|#188)' => "\x{bc}",  # 1/4.
      '(frac12|#189)' => "\x{bd}",  # 1/2.
      '(frac34|#190)' => "\x{be}",  # 3/4
      '(iquest|#191)' => "\x{bf}",  # Inverted ?
      '(Agrave|#192)' => "\x{c0}",  # A Grave.
      '(Aacute|#193)' => "\x{c1}",  # A Acute.
      '(Acirc|#194)'  => "\x{c2}",  # A Circumflex.
      '(Atilde|#195)' => "\x{c3}",  # A tilde.
      '(Auml|#196)'   => "\x{c4}",  # A umlaut.
      '(Aring|#197)'  => "\x{c5}",  # A ring.
      '(AElig|#198)'  => "\x{c6}",  # AE ligature.
      '(Ccedil|#199)' => "\x{c7}",  # C cedilla
      '(Egrave|#200)' => "\x{c8}",  # E Accent grave.
      '(Eacute|#201)' => "\x{c9}",  # E acute accent.
      '(Ecirc|#202)'  => "\x{ca}",  # E Circumflex.
      '(Euml|#203)'   => "\x{cb}",  # E umlaut.
      '(Igrave|#204)' => "\x{cc}",  # I grave accent.
      '(Iacute|#205)' => "\x{cd}",  # I acute accent.
      '(Icirc|#206)'  => "\x{ce}",  # I circumflex.
      '(Iuml|#207)'   => "\x{cf}",  # I umlaut.
      '(ETH|#208)'    => "\x{d0}",  # Icelandic Cap eth.
      '(Ntilde|#209)' => "\x{d1}",  # Ntilde (enyan).
      '(Ograve|#210)' => "\x{d2}",  # O accent grave.
      '(Oacute|#211)' => "\x{d3}",  # O accent acute.
      '(Ocirc|#212)'  => "\x{d4}",  # O circumflex.
      '(Otilde|#213)' => "\x{d5}",  # O tilde.
      '(Ouml|#214)'   => "\x{d6}",  # O umlaut.
      '(times|#215)'  => "\x{d7}",  # Times symbol.
      '(Oslash|#216)' => "\x{d8}",  # O slash.
      '(Ugrave|#217)' => "\x{d9}",  # U accent grave.
      '(Uacute|#218)' => "\x{da}",  # U accent acute.
      '(Ucirc|#219)'  => "\x{db}",  # U circumflex.
      '(Uuml|#220)'   => "\x{dc}",  # U umlaut.
      '(Yacute|#221)' => "\x{dd}",  # Y accent acute.
      '(THORN|#222)'  => "\x{de}",  # Icelandic thorn.
      '(szlig|#223)'  => "\x{df}",  # German sharfes s.
      '(agrave|#224)' => "\x{e0}",  # a accent grave.
      '(aacute|#225)' => "\x{e1}",  # a grave.
      '(acirc|#226)'  => "\x{e2}",  # a circumflex.
      '(atilde|#227)' => "\x{e3}",  # a tilde.
      '(auml|#228)'   => "\x{e4}",  # a umlaut
      '(aring|#229)'  => "\x{e5}",  # a ring on top.
      '(aelig|#230)'  => "\x{e6}",  # ae ligature.
      '(ccedil|#231)' => "\x{e7}",  # C cedilla
      '(egrave|#232)' => "\x{e8}",  # e accent grave.
      '(eacute|#233)' => "\x{e9}",  # e accent acute.
      '(ecirc|#234)'  => "\x{ea}",  # e circumflex.
      '(euml|#235)'   => "\x{eb}",  # e umlaut.
      '(igrave|#236)' => "\x{ec}",  # i grave.
      '(iacute|#237)' => "\x{ed}",  # i acute.
      '(icirc|#238)'  => "\x{ee}",  # i circumflex.
      '(iuml|#239)'   => "\x{ef}",  # i umlaut.
      '(eth|#240)'    => "\x{f0}",  # Icelandic eth.
      '(ntilde|#241)' => "\x{f1}",  # n tilde.
      '(ograve|#242)' => "\x{f2}",  # o grave.
      '(oacute|#243)' => "\x{f3}",  # o acute.
      '(ocirc|#244)'  => "\x{f4}",  # o circumflex.
      '(otilde|#245)' => "\x{f5}",  # o tilde.
      '(ouml|#246)'   => "\x{f6}",  # o umlaut.
      '(divide|#247)' => "\x{f7}",  # division symbol
      '(oslash|#248)' => "\x{f8}",  # o slashed.
      '(ugrave|#249)' => "\x{f9}",  # u accent grave.
      '(uacute|#250)' => "\x{fa}",  # u acute.
      '(ucirc|#251)'  => "\x{fb}",  # u circumflex.
      '(uuml|#252)'   => "\x{fc}",  # u umlaut.
      '(yacute|#253)' => "\x{fd}",  # y acute accent.
      '(thorn|#254)'  => "\x{fe}",  # small thorn (icelandic).
      '(yuml|#255)'   => "\x{ff}",  # y umlaut.
      
      # Latin extended A entities:

      '(OElig|#338)'  => "\x{152}",  # OE ligature.
      '(oelig|#339)'  => "\x{153}",  # oe ligature.
      '(Scaron|#352)' => "\x{160}",  # S caron no printable.
      '(scaron|#353)' => "\x{161}",  # s caron no printable.
      '(Yuml|#376)'   => "\x{178}",  # Y umlaut - no printable.

      # Latin extended B.

      '(fnof|#402)'  => "\x{192}",  # f with little hook.

      # Standalone accents:

      '(circ|#710)'  => '^',        # circumflex.
      '(tilde|#732)' => '~',        # tilde.

      # General punctuation.  We're not able to make a distinction between
      # the various length spacings in the print version. (e.g. en/em/thin).
      # the various joiners will be empty strings in the print version too.


      '(ensp|#8194)'   => "\x{2002}", # en space.
      '(emsp|#8195)'   => "\x{2003}", # em space.
      '(thinsp|#8201)' => "\x{2009}", # thin space.
      '(zwnj|#8204)'   => "\x{200c}", # Zero width non joiner.
      '(zwj|#8205)'    => "\x{200d}", # Zero width joiner.
      '(lrm|#8206)'    => "\x{200e}", # Left to right mark
      '(rlm|#8207)'    => "\x{200f}", # right to left mark.
      '(ndash|#8211)'  => "\x{2013}", # en dash.
      '(mdash|#8212)'  => "\x{2014}", # em dash.
      '(lsquo|#8216)'  => "\x{2018}", # Left single quote.
      '(rsquo|#8217)'  => "\x{2019}", # Right single quote.
      '(sbquo|#8218)'  => "\x{201a}", # Single low-9 quote.
      '(ldquo|#8220)'  => "\x{201c}", # Left double quote.
      '(rdquo|#8221)'  => "\x{201d}", # Right double quote.
      '(bdquo|#8222)'  => "\x{201e}", # Double low-9 quote.
      '(dagger|#8224)' => "\x{2020}", # Is this a dagger I see before me now?
      '(Dagger|#8225)' => "\x{2021}", # it's handle pointing towards my heart?
      '(bull|#8226)'   => "\x{2022}", # Bullet.
      '(hellep|#8230)' => "\x{2026}", # Ellipses.
      '(permil|#8240)' => "\x{2031}", # Per mille.
      '(prime|#8242)'  => "\x{2032}", # Prime.
      '(Prime|#8243)'  => "\x{2033}", # double prime.
      '(lsaquo|#8249)' => "\x{2039}", # < quote.
      '(rsaquo|#8250)' => "\x{203a}", # > quote.
      '(oline|#8254)'  => "\x{203e}", # Overline.
      '(frasl|#8260)'  => "\x{2044}", # Fraction slash.
      '(euro|#8364)'   => "\x{20ac}", # Euro currency.
      
      # Letter like symbols.

      '(weierp|#8472)'  => "\x{2118}", # Power set symbol
      '(image|#8465)'   => "\x{2111}", # Imaginary part
      '(real|#8476)'    => "\x{211c}", # Real part.
      '(trade|#8482)'   => "\x{2122}", # trademark symbol.
      '(alefsym|#8501)' => "\x{2135}", # Hebrew alef.

      # Arrows  of various types and directions.
      '(larr|#8592)'    => "\x{2190}", # <--
      '(uarr|#8593)'    => "\x{2191}", # up arrow.
      '(rarr|#8594)'    => "\x{2192}", # -->
      '(darr|#8595)'    => "\x{2193}", # down arrow.
      '(harr|#8596)'    => "\x{2194}", # <-->
      '(crarr|#8629)'   => "\x{21b5}", # corner arrow down and right.
      '(lArr|#8656)'    => "\x{21d0}", # <==
      '(uArr|#8657)'    => "\x{21d1}", # Up double arrow.
      '(rArr|#8658)'    => "\x{21d2}", # ==>
      '(dArr|#8659)'    => "\x{21d3}", # Down double arrow.
      '(hArr|#8660)'    => "\x{21d4}", # <==>

      # Mathematical operators. For some of these we do the best we can in printing.

      '(forall|#8704)'  => "\x{2200}", # For all.
      '(part|#8706)'    => "\x{2202}", # partial derivative
      '(exist|#8707)'   => "\x{2203}", # There exists.
      '(empty|#8709)'   => "\x{2205}", # Null set.
      '(nabla|#8711)'   => "\x{2207}", # Gradient e.g.
      '(isin|#8712)'    => "\x{2208}", # Element of the set.
      '(notin|#8713)'   => "\x{2209}", # Not an element of
      '(ni|#8715)'      => "\x{220b}", # Contains as a member
      '(prod|#8719)'    => "\x{220f}", # Product 
      '(sum|#8721)'     => "\x{2211}", # Sum of.
      '(minus|#8722)'   => "\x{2212}", # - sign.
      '(lowast|#8727)'  => "\x{2217}", # * 
      '(radic|#8730)'   => "\x{221a}", # Square root. 
      '(prop|#8733)'    => "\x{221d}", # Proportional to.
      '(infin|#8734)'   => "\x{221e}", # Infinity.
      '(ang|#8736)'     => "\x{2220}", # Angle .
      '(and|#8743)'     => "\x{2227}", # Logical and.
      '(or|#8744)'      => "\x{2228}", # Logical or.
      '(cap|#8745)'     => "\x{2229}", # Set intersection.
      '(cup|#8746)'     => "\x{222a}", # Set union.
      '(int|8747)'      => "\x{222b}", # Integral.

      # Some gnuplot guru will have to explain to me why the next three
      # require the extra slashes... else they print very funkily.

      '(there4|#8756)'  => "\x{2234}", # Therefore triple dots.
      '(sim|#8764)'     => "\x{223c}", # Simlar to.
      '(cong|#8773)'    => "\x{2245}", # Congruent to/with.

      '(asymp|#8776)'   => "\x{2248}", # Asymptotic to.
      '(ne|#8800)'      => "\x{2260}", # not equal to.
      '(equiv|#8801)'   => "\x{2261}", # Equivalent to.
      '(le|8804)'       => "\x{2264}", # Less than or equal to.
      '(ge|8805)'       => "\x{2265}", # Greater than or equal to
      '(sub|8834)'      => "\x{2282}", # Subset of.
      '(sup|8835)'      => "\x{2283}", # Super set of.
      '(nsub|8836)'     => "\x{2284}", # not subset of.
      '(sube|8838)'     => "\x{2286}", # Subset or equal.
      '(supe|8839)'     => "\x{2287}", # Superset or equal
      '(oplus|8853)'    => "\x{2295}", # O with plus inside
      '(otimes|8855)'   => "\x{2297}", # O with times.
      '(perp|8869)'     => "\x{22a5}", # Perpendicular.
      '(sdot|8901)'     => "\x{22c5}", # Dot operator.

      # Misc. technical symbols:

      '(lceil|8698)'    => "\x{2308}", # Left ceiling.
      '(rceil|8969)'    => "\x{2309}", # Right ceiling.
      '(lfloor|8970)'   => "\x{230a}", # Left floor.
      '(rfloor|8971)'   => "\x{230b}", # Right floor.

      # The gnuplot png font evidently does not have the big angle brackets at
      # positions 0x2329, 0x232a so use ordinary brackets.

      '(lang|9001)'     => '<', # Left angle bracket.
      '(rang|9002)'     => '>', # Right angle bracket.

      # Gemoetric shapes.

      '(loz|9674)'      => "\x{25ca}", # Lozenge.

      # Misc. symbols

      '(spades|9824)'   => "\x{2660}", 
      '(clubs|9827)'    => "\x{2663}", 
      '(hearts|9829)'   => "\x{2665}", 
      '(diams|9830)'    => "\x{2666}"

    );


sub replace_entities {
    my ($text) = @_;
    $text =~ s{([_^~\{\}]|\\\\)}{\\\\$1}g;
    while (my ($re, $replace) = each(%lookup)) {
        $text =~ s/&$re;/$replace/g;
    }
    $text =~ s{(&)}{\\\\$1}g;
    return $text;
}

##------------------------------------------------------------------- title
sub start_title_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result='';
    $title = $p->get_text('/title');
    if (!defined $title) {
      $title = '';
    }
    $title = &Apache::lc_asset_safeeval::texteval($safe, $title);
    $title =~ s/\n/ /g;
    if (length($title) > $max_str_len) {
        $title = substr($title,0,$max_str_len);
    }
    $title = &parse_label($title);
    return $result;
}

sub end_title_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result = '';
    return $result;
}
##------------------------------------------------------------------- xlabel
sub start_xlabel_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result='';
    $xlabel = $p->get_text('/xlabel');
    if (!defined $xlabel) {
      $xlabel = '';
    }
    $xlabel = &Apache::lc_asset_safeeval::texteval($safe, $xlabel);
    $xlabel =~ s/\n/ /g;
    if (length($xlabel) > $max_str_len) {
        $xlabel = substr($xlabel,0,$max_str_len);
    }
    $xlabel = &parse_label($xlabel);
    return $result;
}

sub end_xlabel_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result = '';
    return $result;
}

##------------------------------------------------------------------- ylabel
sub start_ylabel_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result='';
    $ylabel = $p->get_text('/ylabel');
    if (!defined $ylabel) {
      $ylabel = '';
    }
    $ylabel = &Apache::lc_asset_safeeval::texteval($safe, $ylabel);
    $ylabel =~ s/\n/ /g;
    if (length($ylabel) > $max_str_len) {
        $ylabel = substr($ylabel,0,$max_str_len);
    }
    $ylabel = &parse_label($ylabel);
    return $result;
}

sub end_ylabel_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result = '';
    return $result;
}

##------------------------------------------------------------------- label
sub start_label_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result='';
    my %label;
    &get_attributes(\%label,\%label_defaults,$token,$token->[1]);
    my $text = $p->get_text('/label');
    if (!defined $text) {
      $text = '';
    }
    $text = &Apache::lc_asset_safeeval::texteval($safe, $text);
    $text =~ s/\n/ /g;
    $text = substr($text,0,$max_str_len) if (length($text) > $max_str_len);
    $label{'text'} = &parse_label($text);
    push(@labels,\%label);
    return $result;
}

sub end_label_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result = '';
    return $result;
}

##------------------------------------------------------------------- curve
sub start_curve_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result='';
#     &Apache::lonxml::register('Apache::lc_xml_lonplot',('function','data'));
#     push (@Apache::lonxml::namespace,'curve');
    my %curve;
    &get_attributes(\%curve,\%curve_defaults,$token,$token->[1]);
    push (@curves,\%curve);
    return $result;
}

sub end_curve_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result = '';
#     pop @Apache::lonxml::namespace;
#     &Apache::lonxml::deregister('Apache::lc_xml_lonplot',('function','data'));
    return $result;
}

##------------------------------------------------------------ curve function
sub start_function_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result='';
    if (exists($curves[-1]->{'data'})) {
        warning
            ('Use of the <b>curve function</b> tag precludes use of '.
              ' the <b>curve data</b> tag.  '.
              'The curve data tag will be omitted in favor of the '.
              'curve function declaration.');
        delete $curves[-1]->{'data'} ;
    }
    my $function = $p->get_text('/function');
    if (!defined $function) {
      $function = '';
    }
    $function = &Apache::lc_asset_safeeval::texteval($safe, $function);
    $function=~s/\^/\*\*/gs;
    $function=~ s/^\s+//;   # Trim leading
    $function=~ s/\s+$//;   # And trailing whitespace.
    $curves[-1]->{'function'} = $function; 
    return $result;
}

sub end_function_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result = '';
    return $result;
}

##------------------------------------------------------------ curve  data
sub start_data_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result='';
    if (exists($curves[-1]->{'function'})) {
        warning
            ('Use of the <b>curve function</b> tag precludes use of '.
              ' the <b>curve data</b> tag.  '.
              'The curve function tag will be omitted in favor of the '.
              'curve data declaration.');
        delete($curves[-1]->{'function'});
    }
    my $datatext = $p->get_text('/data');
    if (!defined $datatext) {
      $datatext = '';
    }
    $datatext = &Apache::lc_asset_safeeval::argeval($safe, $datatext);
    # Deal with cases where we're given an array...
    my @data;
    if (ref($datatext) eq 'ARRAY') {
        @data = @$datatext;
    } else {
        $datatext =~ s/\s+/ /g;
        # Need to do some error checking on the @data array - 
        # make sure it's all numbers and make sure each array 
        # is of the same length.
        if ($datatext =~ /,/) { # comma deliminated
            @data = split /,/,$datatext;
        } else { # Assume it's space separated.
            @data = split / /,$datatext;
        }
    }
    for (my $i=0;$i<=$#data;$i++) {
        # Check that it's non-empty
        if (! defined($data[$i])) {
            warning(
                'undefined curve data value.  Replacing with '.
                ' pi/e = 1.15572734979092');
            $data[$i] = 1.15572734979092;
        }
        # Check that it's a number
        if (! &$real_test($data[$i]) & ! &$int_test($data[$i])) {
            warning(
                'Bad curve data value of '.$data[$i].'  Replacing with '.
                ' pi/e = 1.15572734979092');
            $data[$i] = 1.15572734979092;
        }
    }
    # complain if the number of data points is not the same as
    # in previous sets of data.
    if (($curves[-1]->{'data'}) && ($#data != $#{$curves[-1]->{'data'}->[0]})){
        warning
            ('Number of data points is not consistent with previous '.
              'number of data points');
    }
    push  @{$curves[-1]->{'data'}},\@data;
    return $result;
}

sub end_data_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result = '';
    return $result;
}

##------------------------------------------------------------------- axis
sub start_axis_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result='';
    &get_attributes(\%axis,\%axis_defaults,$token,$token->[1]);
    return $result;
}

sub end_axis_html {
    my ($p, $safe, $stack, $token) = @_;
    my $result = '';
    return $result;
}

###################################################################
##                                                               ##
##        Utility Functions                                      ##
##                                                               ##
###################################################################

##----------------------------------------------------------- set_defaults
sub set_defaults {
    my ($var,$defaults) = @_;
    my $key;
    foreach $key (keys(%$defaults)) {
        $var->{$key} = $defaults->{$key}->{'default'};
    }
}

##------------------------------------------------------------------- misc
sub get_attributes{
    my ($values,$defaults,$token,$tag) = @_;
    foreach my $attr (keys(%{$defaults})) {
#         if ($attr eq 'texwidth' || $attr eq 'texfont') {
#             $values->{$attr} = 
#                 &Apache::lonxml::get_param($attr,$parstack,$safeeval,undef,1);
#         } else {
#             $values->{$attr} = 
#                 &Apache::lonxml::get_param($attr,$parstack,$safeeval);
#         }
        $values->{$attr} = $token->[2]->{$attr};
        
        if ($values->{$attr} eq '' | !defined($values->{$attr})) {
            $values->{$attr} = $defaults->{$attr}->{'default'};
            next;
        }
        my $test = $defaults->{$attr}->{'test'};
        if (! &$test($values->{$attr})) {
            warning
                ($tag.':'.$attr.': Bad value.'.'Replacing your value with : '
                 .$defaults->{$attr}->{'default'} );
            $values->{$attr} = $defaults->{$attr}->{'default'};
        }
    }
    return ;
}
##
# Generate tic mark specifications.
# 
# @param type - type of tics (xtics or ytics).
# @param spec - Reference to a hash that contains the tic specification.
# @param target - 'tex' if hard copy target.
#
# @return string - the tic specification command.
#
sub generate_tics {
    my ($type, $spec) = @_;
    my $result   = '';


    if ((ref($spec) eq 'HASH') && (keys(%{$spec}) > 0)) {

        

        # Major tics: - If there are 'ticspecs' these override any other
        #               specifications:

        
        
        $result .= "set $type $spec->{'location'}  ";
        $result .= ($spec->{'mirror'} eq 'on') ? 'mirror ' : 'nomirror ';
        if ($spec->{'rotate'} eq 'on') {
            $result .= ' rotate ';
        }
        if (defined $spec->{'ticspecs'}) {
            $result .= '( ';
            my @ticspecs;
            my $ticinfo = $spec->{'ticspecs'};
            foreach my $tic (@$ticinfo) {
                push(@ticspecs,  '"' . $tic->{'label'} . '" ' . $tic->{'pos'} );
            }
            $result .= join(', ', (@ticspecs));
            $result .= ' )';
        } else {
            $result .= "$spec->{'start'}, ";
            $result .= "$spec->{'increment'}, ";
            $result .= "$spec->{'end'} ";
        }
        $result .= "\n";
        
        # minor frequency:
        
        if ($spec->{'minorfreq'} != 0) {
            $result .= "set m$type $spec->{'minorfreq'}\n";
        }
    }
    
    
    return $result;
}

##------------------------------------------------------- write_gnuplot_file
sub write_gnuplot_file {
    my ($fontsize, $font_properties) =  &get_font();
    my $gnuplot_input = '';
    my $curve;
    #
    # Check to be sure we do not have any empty curves
    my @curvescopy;
    foreach my $curve (@curves) {
        if (exists($curve->{'function'})) {
            if ($curve->{'function'} !~ /^\s*$/) {
                push(@curvescopy,$curve);
            }
        } elsif (exists($curve->{'data'})) {
            foreach my $data (@{$curve->{'data'}}) {
                if (scalar(@$data) > 0) {
                    push(@curvescopy,$curve);
                    last;
                }
            }
        }
    }
    @curves = @curvescopy;
    # Collect all the colors
    my @Colors;
    push @Colors, $Apache::lc_xml_lonplot::plot{'bgcolor'};
    push @Colors, $Apache::lc_xml_lonplot::plot{'fgcolor'}; 
    push @Colors, (defined($axis{'color'})?$axis{'color'}:$Apache::lc_xml_lonplot::plot{'fgcolor'});
    foreach $curve (@curves) {
        push @Colors, ($curve->{'color'} ne '' ? 
                       $curve->{'color'}       : 
                       $Apache::lc_xml_lonplot::plot{'fgcolor'}        );
    }
    
    # set term
    #$gnuplot_input .= 'set terminal png enhanced nocrop ';
    #$gnuplot_input .= 'transparent ' if ($Apache::lc_xml_lonplot::plot{'transparent'} eq 'on');
    #$gnuplot_input .= 'font "'.$Apache::lonnet::perlvar{'lonFontsDir'}.
    #    '/'.$font_properties->{'file'}.'.ttf" ';
    #$gnuplot_input .= $fontsize;
    #$gnuplot_input .= ' size '.$Apache::lc_xml_lonplot::plot{'width'}.','.$Apache::lc_xml_lonplot::plot{'height'}.' ';
    #$gnuplot_input .= "@Colors\n"; # FIXME: do we need this ?
    # set output
    #$gnuplot_input .= "set output\n";
    $gnuplot_input .= "set encoding utf8\n";
    # cartesian or polar plot?
    if (lc($Apache::lc_xml_lonplot::plot{'plottype'}) eq 'polar') {
        $gnuplot_input .= 'set polar'.$/;
    } else {
        # Assume Cartesian
    }
    # cartesian or polar grid?
    if (lc($Apache::lc_xml_lonplot::plot{'gridtype'}) eq 'polar') {
        $gnuplot_input .= 'set grid polar'.$/;
    } elsif (lc($Apache::lc_xml_lonplot::plot{'gridtype'}) eq 'linear-log') {
        $gnuplot_input .= 'set logscale x'.$/;
    } elsif (lc($Apache::lc_xml_lonplot::plot{'gridtype'}) eq 'log-linear') {
        $gnuplot_input .= 'set logscale y'.$/;
    } elsif (lc($Apache::lc_xml_lonplot::plot{'gridtype'}) eq 'log-log') {
        $gnuplot_input .= 'set logscale x'.$/;
        $gnuplot_input .= 'set logscale y'.$/;
    } else {
        # Assume Cartesian
    }
    # solid or pattern for boxes?
    if (lc($Apache::lc_xml_lonplot::plot{'fillstyle'}) eq 'solid') {
        $gnuplot_input .= 'set style fill solid '.
            $Apache::lc_xml_lonplot::plot{'solid'}.$Apache::lc_xml_lonplot::plot{'box_border'}.$/;
    } elsif (lc($Apache::lc_xml_lonplot::plot{'fillstyle'}) eq 'pattern') {
        $gnuplot_input .= 'set style fill pattern '.$Apache::lc_xml_lonplot::plot{'pattern'}.$Apache::lc_xml_lonplot::plot{'box_border'}.$/;
    } elsif (lc($Apache::lc_xml_lonplot::plot{'fillstyle'}) eq 'empty') {
    }
    # margin
    if (lc($Apache::lc_xml_lonplot::plot{'lmargin'}) ne 'default') {
        $gnuplot_input .= 'set lmargin '.$Apache::lc_xml_lonplot::plot{'lmargin'}.$/;
    }
    if (lc($Apache::lc_xml_lonplot::plot{'rmargin'}) ne 'default') {
        $gnuplot_input .= 'set rmargin '.$Apache::lc_xml_lonplot::plot{'rmargin'}.$/;
    }
    if (lc($Apache::lc_xml_lonplot::plot{'tmargin'}) ne 'default') {
        $gnuplot_input .= 'set tmargin '.$Apache::lc_xml_lonplot::plot{'tmargin'}.$/;
    }
    if (lc($Apache::lc_xml_lonplot::plot{'bmargin'}) ne 'default') {
        $gnuplot_input .= 'set bmargin '.$Apache::lc_xml_lonplot::plot{'bmargin'}.$/;
    }

    # tic scales
    $gnuplot_input .= 'set tics scale '.
        $Apache::lc_xml_lonplot::plot{'major_ticscale'}.', '.$Apache::lc_xml_lonplot::plot{'minor_ticscale'}.$/;
    #boxwidth
    if (lc($Apache::lc_xml_lonplot::plot{'boxwidth'}) ne '') {
        $gnuplot_input .= 'set boxwidth '.$Apache::lc_xml_lonplot::plot{'boxwidth'}.$/;
    }
    # gridlayer
    $gnuplot_input .= 'set grid noxtics noytics front '.$/ 
        if ($Apache::lc_xml_lonplot::plot{'gridlayer'} eq 'on');

    # grid
    $gnuplot_input .= 'set grid'.$/ if ($Apache::lc_xml_lonplot::plot{'grid'} eq 'on');
    # border
    $gnuplot_input .= ($Apache::lc_xml_lonplot::plot{'border'} eq 'on'?
                       'set border'.$/           :
                       'set noborder'.$/         );
    # sampling rate for non-data curves
    $gnuplot_input .= "set samples $Apache::lc_xml_lonplot::plot{'samples'}\n";
    # title, xlabel, ylabel
    # titles
    my $extra_space_x = ($xtics{'location'} eq 'axis') ? ' offset 0, -0.5 ' : '';
    my $extra_space_y = ($ytics{'location'} eq 'axis') ? ' offset -0.5, 0 ' : '';

    $gnuplot_input .= "set title  \"$title\"          \n" if (defined($title)) ;
    $gnuplot_input .= "set xlabel \"$xlabel\" $extra_space_x \n" if (defined($xlabel));
    $gnuplot_input .= "set ylabel \"$ylabel\" $extra_space_y \n" if (defined($ylabel));
    
    # tics
    $gnuplot_input .= &generate_tics('xtics', \%xtics);

    $gnuplot_input .= &generate_tics('ytics', \%ytics);

    # axis
    if (%axis) {
        if ($axis{'xformat'} ne 'on') {
            $gnuplot_input .= "set format x ";
            if ($axis{'xformat'} eq 'off') {
                $gnuplot_input .= "\"\"\n";
            } else {
                $gnuplot_input .= "\"\%.".$axis{'xformat'}."\"\n";
            }
        }
        if ($axis{'yformat'} ne 'on') {
            $gnuplot_input .= "set format y ";
            if ($axis{'yformat'} eq 'off') {
                $gnuplot_input .= "\"\"\n";
            } else {
                $gnuplot_input .= "\"\%.".$axis{'yformat'}."\"\n";
            }
        }
        $gnuplot_input .= "set xrange \[$axis{'xmin'}:$axis{'xmax'}\]\n";
        $gnuplot_input .= "set yrange \[$axis{'ymin'}:$axis{'ymax'}\]\n";
                if ($axis{'xzero'} ne 'off') {
                        $gnuplot_input .= "set xzeroaxis ";
                        if ($axis{'xzero'} eq 'line' || $axis{'xzero'} eq 'thick-line') {
                                $gnuplot_input .= "lt -1 ";
                                if ($axis{'xzero'} eq 'thick-line') {
                                        $gnuplot_input .= "lw 3 ";
                                }
                        }
                        $gnuplot_input .= "\n";
                }
                if ($axis{'yzero'} ne 'off') {
                        $gnuplot_input .= "set yzeroaxis ";
                        if ($axis{'yzero'} eq 'line' || $axis{'yzero'} eq 'thick-line') {
                                $gnuplot_input .= "lt -1 ";
                                if ($axis{'yzero'} eq 'thick-line') {
                                        $gnuplot_input .= "lw 3 ";
                                }
                        }
                        $gnuplot_input .= "\n";
                }
    }
    # Key
    if (%key) {
        $gnuplot_input .= 'set key '.$key{'pos'}.' ';
        if ($key{'title'} ne '') {
            $gnuplot_input .= 'title "'.$key{'title'}.'" ';
        } 
        $gnuplot_input .= ($key{'box'} eq 'on' ? 'box ' : 'nobox ').$/;
    } else {
        $gnuplot_input .= 'set nokey'.$/;
    }
    # labels
    my $label;
    foreach $label (@labels) {
        $gnuplot_input .= 'set label "'.$label->{'text'}.'" at '.
                          $label->{'xpos'}.','.$label->{'ypos'};
        if ($label->{'rotate'} ne '') {
            $gnuplot_input .= ' rotate by '.$label->{'rotate'};
        }
        $gnuplot_input .= ' '.$label->{'justify'};

        if (($label->{'zlayer'} eq 'front') || ($label->{'zlayer'} eq 'back')) {
            $gnuplot_input .= ' '.$label->{'zlayer'};
        }
        $gnuplot_input .= $/;
    }
    # curves
    #
    # Each curve will have its very own linestyle.
    # (This should work just fine in web rendition I think).
    #  The line_xxx variables will hold the elements of the line style.
    #  type (solid/dashed), color, width
    #
    my $linestyle_index = 50;
    my $line_width   = '';
    my $plots = '';

    # If arrows are needed there will be an arrow style for each as well:
    #

    my $arrow_style_index = 50;
    
    my $all_plot_data = '';

    for (my $i = 0;$i<=$#curves;$i++) {
        $curve = $curves[$i];
        my $plot_command = '';
        my $plot_type = '';
        if ($i > 0) {
            $plot_type = ', ';
        }
        $line_width = $curve->{'linewidth'};
        if (exists($curve->{'function'})) {
            $plot_type  .= 
                $curve->{'function'}.' title "'.
                $curve->{'name'}.'" with '.
                $curve->{'linestyle'};
        } elsif (exists($curve->{'data'})) {
            # Store data values in $datatext
            my $datatext = '';
            # Compile data
            my @Data = @{$curve->{'data'}};
            my @Data0 = @{$Data[0]};
            for (my $i =0; $i<=$#Data0; $i++) {
                my $dataset;
                foreach $dataset (@Data) {
                    $datatext .= $dataset->[$i] . ' ';
                }
                $datatext .= $/;
            }
            # save it for adding after command
            $all_plot_data .= $datatext."\ne\n";
            #   generate gnuplot text
            $plot_type .= '"-" title "'.
                $curve->{'name'}.'" with '.
                $curve->{'linestyle'};
        }
        my $pointtype = '';
        my $pointsize = '';

        # Figure out the linestyle:

        my $lt = $curve->{'linetype'} ne '' ? $curve->{'linetype'} 
                        : 'solid';      # Line type defaults to solid.
        # The mapping of lt -> the actual gnuplot line type depends on the target:

        $lt = $linetypes{$lt};

        my $color = $curve->{'color'};
        $color =~ s/^x/#/;              # Convert xhex color -> #hex color.   


        if (($curve->{'linestyle'} eq 'points')      ||
            ($curve->{'linestyle'} eq 'linespoints') ||
            ($curve->{'linestyle'} eq 'errorbars')   ||
            ($curve->{'linestyle'} eq 'xerrorbars')  ||
            ($curve->{'linestyle'} eq 'yerrorbars')  ||
            ($curve->{'linestyle'} eq 'xyerrorbars')) {
            
            $pointtype =' pointtype '.$curve->{'pointtype'};
            $pointsize =' pointsize '.$curve->{'pointsize'};
        } elsif ($curve->{'linestyle'} eq 'filledcurves') { 
            $plot_command.= ' '.$curve->{'limit'};
        } elsif ($curve->{'linestyle'} eq 'vector') {

            # Create the arrow head style add it to 
            # $gnuplot_input..and ensure it gets
            # Selected in the plot command.

            $gnuplot_input .= "set style arrow $arrow_style_index ";
            $gnuplot_input .= ' ' . $curve->{'arrowhead'};
            $gnuplot_input .= ' size ' . $curve->{'arrowlength'};
            $gnuplot_input .= ','.$curve->{'arrowangle'};
            $gnuplot_input .= ',' . $curve->{'arrowbackangle'}; 
            $gnuplot_input .=  ' ' . $curve->{'arrowstyle'} . " ls $linestyle_index\n";


            $plot_command  .= "  arrowstyle $arrow_style_index ";
            $arrow_style_index++;
        }

        my $style_command = "set style line $linestyle_index $pointtype $pointsize linetype $lt linewidth $line_width lc rgb '$color'\n";
        $gnuplot_input .= $style_command;

        # The condition below is because gnuplot lumps the linestyle in with the 
        # arrowstyle _sigh_.

        if ($curve->{'linestyle'} ne 'vector') {
            $plot_command.= " ls $linestyle_index";
        }

        $plots .= $plot_type . ' ' . $plot_command;
        $linestyle_index++;     # Each curve get a unique linestyle.
    }
    $gnuplot_input .= 'plot '.$plots;
    $gnuplot_input .= "\n".$all_plot_data."\n";
    # Write the output to a file.

    # &Apache::lonnet::logthis($gnuplot_input); # uncomment to log the gnuplot input.
    
    # That's all folks.
    return $gnuplot_input;
}

#---------------------------------------------- check_inputs
sub check_inputs {
    ## Note: no inputs, no outputs - this acts only on global variables.
    ## Make sure we have all the input we need:
    if (! %Apache::lc_xml_lonplot::plot) { &set_defaults(\%Apache::lc_xml_lonplot::plot,\%gnuplot_defaults); }
    if (! %key ) {} # No key for this plot, thats okay
#    if (! %axis) { &set_defaults(\%axis,\%axis_defaults); }
    if (! defined($title )) {} # No title for this plot, thats okay
    if (! defined($xlabel)) {} # No xlabel for this plot, thats okay
    if (! defined($ylabel)) {} # No ylabel for this plot, thats okay
    if ($#labels < 0) { }      # No labels for this plot, thats okay
    if ($#curves < 0) { 
        warning("No curves specified for plot!!!!");
        return '';
    }
    my $curve;
    foreach $curve (@curves) {
        if (!defined($curve->{'function'})&&!defined($curve->{'data'})){
            warning("One of the curves specified did not contain any curve data or curve function declarations\n");
            return '';
        }
    }
}


# This should output a warning in some cases, but we would need something for that in lc_asset_xml
# to replace Apache::lonxml::warning
sub warning {
    my ($message) = @_;
    print STDERR $message."\n";
}

##----------------------------------------------------------------------
1;
__END__


=head1 NAME

Apache::lc_xml_lonplot.pm

=head1 SYNOPSIS

XML-based plotter of graphs

This is part of the LearningOnline Network with CAPA project
described at http://www.lon-capa.org.


=head1 SUBROUTINES (parsing and edit rendering)

=over

=item start_gnuplot()

=item end_gnuplot()

=item start_xtics()

=item end_xtics()

=item start_ytics()

=item end_ytics()

=item get_font()

=item start_key()

=item end_key()

=item parse_label()

=item replace_entities()

=item start_title()

=item end_title()

=item start_xlabel()

=item end_xlabel()

=item start_ylabel()

=item end_label()

=item start_curve()

=item end_curve()

=item start_function()

=item end_function()

=item start_data()

=item end_data()

=item start_axis()

=item end_axis

=back

=head1 SUBROUTINES (Utility)

=over

=item set_defaults()

=item get_attributes()

=item write_gnuplot_file()

=item check_inputs()

=back

=cut
