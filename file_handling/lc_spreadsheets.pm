# The LearningOnline Network with CAPA - LON-CAPA
# Deal with spreadsheet uploads 
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

package Apache::lc_spreadsheets;

use strict;

use Apache2::Const qw(:common :http);
use Apache::lc_logs;
use Apache::lc_parameters;
use Apache::lc_file_utils();
use Apache::lc_file_upload();
use Spreadsheet::ParseExcel;
use Spreadsheet::XLSX;
use Text::CSV_PP;

sub parse_xls {
   my ($file)=@_;
   my $sheets;
   my $parser   = Spreadsheet::ParseExcel->new();
   my $workbook = $parser->parse($file);
   unless (defined($workbook)) { return undef; }
   foreach my $worksheet ( $workbook->worksheets() ) {
      my $name=$worksheet->{'Name'};
      my ( $row_min, $row_max ) = $worksheet->row_range();
      $sheets->{$name}->{'row_min'}=$row_min;
      $sheets->{$name}->{'row_max'}=$row_max;
      my ( $col_min, $col_max ) = $worksheet->col_range();
      $sheets->{$name}->{'col_min'}=$col_min;
      $sheets->{$name}->{'col_max'}=$col_max;
      foreach my $row ($row_min .. $row_max) {
         foreach my $col ($col_min .. $col_max) {
            my $cell = $worksheet->get_cell($row,$col );
            next unless $cell;
            $sheets->{$name}->{'cells'}->{$row}->{$col}->{'value'}=$cell->value();
            $sheets->{$name}->{'cells'}->{$row}->{$col}->{'unformatted'}=$cell->unformatted();
            $sheets->{$name}->{'cells'}->{$row}->{$col}->{'type'}=$cell->type();
         }
      }
   }
   return $sheets;
}

sub parse_xlsx {
   my ($file)=@_;
   my $sheets;
   my $excel = Spreadsheet::XLSX -> new ($file);
   foreach my $worksheet (@{$excel->{'Worksheet'}}) {
      my $name=$worksheet->{'Name'};
      my ($row_min,$row_max)=($worksheet->{'MinRow'},$worksheet->{'MaxRow'});
      $sheets->{$name}->{'row_min'}=$row_min;
      $sheets->{$name}->{'row_max'}=$row_max;
      my ($col_min,$col_max)=($worksheet->{'MinCol'},$worksheet->{'MaxCol'});
      $sheets->{$name}->{'col_min'}=$col_min;
      $sheets->{$name}->{'col_max'}=$col_max;
      foreach my $row ($row_min .. $row_max) {
         foreach my $col ($col_min .. $col_max) {
            my $cell = $worksheet -> {'Cells'} [$row] [$col];
            next unless $cell;
            $sheets->{$name}->{'cells'}->{$row}->{$col}->{'value'}=$cell->value();
            $sheets->{$name}->{'cells'}->{$row}->{$col}->{'unformatted'}=$cell->unformatted();
            $sheets->{$name}->{'cells'}->{$row}->{$col}->{'type'}=$cell->type();
         }
      }
   }
   return $sheets;
}

sub parse_csv {
   my ($file,$sep)=@_;
   unless ($sep) { $sep=','; }
   my $sheets;
   my $csv = Text::CSV_PP->new({ sep_char => $sep, allow_whitespace => 1 });
   my $content=&Apache::lc_file_utils::readfile($file);
   my $name='default';
   $sheets->{$name}->{'row_min'}=0;
   $sheets->{$name}->{'col_min'}=0;
   $sheets->{$name}->{'col_max'}=0;
   my $row=0;
   foreach my $rowdata (split(/[\n\r]+/,$content)) {
      $csv->parse($rowdata);
      my @cells=$csv->fields();
      my $rowcols=$#cells;
      if ($rowcols<0) { next; }
      if ($rowcols>$sheets->{$name}->{'col_max'}) { $sheets->{$name}->{'col_max'}=$rowcols; }
      foreach my $col (0 .. $rowcols) {
         next unless $cells[$col];
         $sheets->{$name}->{'cells'}->{$row}->{$col}->{'value'}=$cells[$col];
            $sheets->{$name}->{'cells'}->{$row}->{$col}->{'unformatted'}=$cells[$col];
            $sheets->{$name}->{'cells'}->{$row}->{$col}->{'type'}='Text';
      }
      $row++;
   }
   $sheets->{$name}->{'row_max'}=$row-1;
   return $sheets;
}

sub parse_spreadsheet {
   my ($file)=@_;
   my $sheets;
   if ($file=~/\.xls\s*$/i) {
      $sheets=&parse_xls($file);
   } elsif ($file=~/\.xlsx\s*$/i) {
      $sheets=&parse_xlsx($file);
   } elsif ($file=~/\.csv\s*$/i) {
      my $sheetscomma=&parse_csv($file,',');
      my $sheetssemi=&parse_csv($file,';');
      if ($sheetscomma->{'default'}->{'col_max'}>$sheetssemi->{'default'}->{'col_max'}) {
         $sheets=$sheetscomma;
      } else {
         $sheets=$sheetssemi;
      }
   }
   return $sheets;
}

sub parse_spreadsheet_to_jsonfile {
   my ($file,$destfile)=@_;
   return &Apache::lc_file_utils::writefile($destfile,&Apache::lc_json_utils::perl_to_json(&parse_spreadsheet($file)));
}

sub handler {
   my ($entity,$domain)=&Apache::lc_entity_sessions::user_entity_domain();
   my $file=&Apache::lc_file_upload::move_uploaded_into_default_place();
   unless ($file) {
      &logerror("Failed to upload spreadsheet file");
      return HTTP_SERVICE_UNAVAILABLE;
   }
   unless (&parse_spreadsheet_to_jsonfile($file,&Apache::lc_entity_urls::wrk_to_filepath($domain.'/'.$entity.'/uploaded_spreadsheet.json'))) {
      &logwarning("Could not parse uploaded spreadsheet");
      return HTTP_SERVICE_UNAVAILABLE;
   }
   return OK;
}

1;
__END__
