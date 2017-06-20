#!/usr/bin/perl -w
#/usr/bin/perl
use strict;
use warnings;
use DBI;
use Date::Parse;
use Spreadsheet::WriteExcel;
use Unicode::UTF8simple;
use DateTime;

our $dbname = "position";
our $location = "192.168.23.57";
our $port = "3306";
our $database = "DBI:mysql:$dbname:$location:$port";
our $db_user = "root";
our $db_pass = "1";
our $execlname ="ap-cscan";
our $file = $execlname.'.xls';
our $sheetName = 'Sheet1';
our $book = new Spreadsheet::WriteExcel($file);
our $sheet = $book->add_worksheet( $sheetName );

my @APList;
open(FILE,"<","./pwd.txt") or die"cannot open the file: $!\n";
my @linelist=<FILE>;
foreach my $eachline(@linelist){
        my @argument = split(/#/,$eachline);
        print "$argument[0]\n";
        #print "$argument[1]\n";
        $argument[0] = &macchange("$argument[0]");
        push(@APList,$argument[0]);
        #print "@APList \n";
}
print "@APList \n";
close FILE;

for (my $i=0;$i<@APList;)
{
        my $arg1 = $APList[$i];
        my $arg2 = $i*4;
        &GetDatafromDB("$arg1","$arg2");
        sleep 1;
        $i++;
}
$book->close();
sub macchange()
{
        my $char = shift;
        my @argument = split(/:/,$char);
        my $str = join('',@argument);
        return $str;
}

sub GetDatafromDB(){
    my $apmac = shift;
    my $col = shift;
    my $dbh = DBI->connect($database,$db_user,$db_pass);
    my $row = 1;
    chomp($apmac);
    my $sql = "SELECT * FROM `airocov_xwyl5_cache_b` WHERE apmac = '$apmac'";
    my $sth = $dbh->prepare($sql);
    $sth->execute() or die "can't execute the command:$dbh->errstr";
    print "$sql\n";
    my @datalist;
    while(@datalist = $sth->fetchrow_array()){
             $sheet->write($row,$col,$datalist[1]);
             $sheet->write($row,$col+2,$datalist[2]);
             $sheet->write($row,$col+3,$datalist[3]);
             $sheet->write($row,$col+4,$datalist[8]);
             $row++;
    }
    $sth->finish();
    $dbh->disconnect();
}


