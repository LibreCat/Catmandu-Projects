#!/usr/bin/perl -w

use Data::Dumper;
use Text::CSV;

#
# Script to anonymize SAP-Export files
#
# Usage: > perl anonymize.pl file.csv
# 
# Where 'file' is a csv formatted file with the following specifications:
# 
#  utf-8 formatted
#  text of each column enclosed in ""
#  columns separated by comma
#
#  

my $file = shift;

unless ($file) {
    print STDERR "Please enter a file name of a csv formatted file."."\n";    
    exit(1);
}

my $newfilename;
if ($file =~ /(.*)\.csv/){
   $newfilename = $1;
   $newfilename .= 'Anon.csv';
}

my $csv = Text::CSV->new({binary => 1}) or die "Cannot use CSV: ".Text::CSV->error_diag();
open my $fh, "<:encoding(utf8)", $file or die "$file: $!";

my $colNo1;
my $colNo2;
my $colNo3;

my $anonFile;

my $numOfColumns = 9; # TODO extract number of columns from the actual csv-file

while (my $row = $csv->getline($fh)){
    
    if (!$colNo1 and !$colNo2 and !$colNo3){
        for (my $i=0; $i<$numOfColumns; $i++){
        	# TODO make column names into external input parameters instead of hard coded names here
            if ($row->[$i] eq 'Bezeichnung'){
                $colNo1 = $i;
            }
            elsif ($row->[$i] eq 'Antragssumme in EUR'){
                $colNo2 = $i;
            }
            elsif ($row->[$i] eq 'Erste Bewilligung'){
                $colNo3 = $i;
            }
            $row->[$i] = "";
        }
    }
    

    $row->[$colNo1] = "";
    $row->[$colNo2] = "";
    $row->[$colNo3] = "";

    my $newRow = "";
    for (my $i=0; $i<$numOfColumns; $i++){
        $newRow .= '"'.$row->[$i].'",' if ($i!=$colNo1 and $i!=$colNo2 and $i!=$colNo3);
    }
    if($newRow =~ /(\"\",){5}\"\"/){
        $newRow = "";
    }
    
    $newRow = substr($newRow,0,-1) if $newRow ne "";
    $anonFile .= $newRow."\n" if $newRow ne "";
    
}
close $fh;


open (MYFILE, ">:utf8","$newfilename");
print MYFILE $anonFile;
close (MYFILE);
