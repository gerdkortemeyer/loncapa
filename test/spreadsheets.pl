use strict;
use Spreadsheet::ParseExcel;
use Spreadsheet::XLSX;

sub parse_xls {
    my ($file)=@_;
    my $parser   = Spreadsheet::ParseExcel->new();
    my $workbook = $parser->parse($file);

    if ( !defined $workbook ) {
        die $parser->error(), ".\n";
    }

    for my $worksheet ( $workbook->worksheets() ) {

        my ( $row_min, $row_max ) = $worksheet->row_range();
        my ( $col_min, $col_max ) = $worksheet->col_range();

        for my $row ( $row_min .. $row_max ) {
            for my $col ( $col_min .. $col_max ) {

                my $cell = $worksheet->get_cell( $row, $col );
                next unless $cell;

                print "Row, Col    = ($row, $col)\n";
                print "Value       = ", $cell->value(),       "\n";
                print "Unformatted = ", $cell->unformatted(), "\n";
                print "\n";
            }
        }
    }
}

sub parse_xlsx {
   my ($file)=@_; 
   my $excel = Spreadsheet::XLSX -> new ($file);
 
 foreach my $sheet (@{$excel -> {Worksheet}}) {
 
        printf("Sheet: %s\n", $sheet->{Name});
        
        $sheet -> {MaxRow} ||= $sheet -> {MinRow};
        
         foreach my $row ($sheet -> {MinRow} .. $sheet -> {MaxRow}) {
         
                $sheet -> {MaxCol} ||= $sheet -> {MinCol};
                
                foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
                
                        my $cell = $sheet -> {Cells} [$row] [$col];
 
                        if ($cell) {
                            printf("( %s , %s ) => %s\n", $row, $col, $cell -> {Val});
                        }
 
                }
 
        }
 
 }
}

&parse_xls('/home/www/Desktop/classlist.xls');
print "\n=========\n";
&parse_xlsx('/home/www/Desktop/classlist.xlsx');

