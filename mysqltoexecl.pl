#!/usr/bin/perl -w
#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use Date::Parse;
use Spreadsheet::WriteExcel;
use Unicode::UTF8simple;
use DateTime;
use Excel::Writer::XLSX;

our $dbname = "position";
our $location = "192.168.23.106";
our $port = "3306";
our $database = "DBI:mysql:$dbname:$location:$port";
our $db_user = "root";
our $db_pass = "1";



die "$0 requires an argument.\n" if $#ARGV < 0;
if($ARGV[0] =~ m/.xlsx/i){
	our $workbook=Excel::Writer::XLSX->new("$ARGV[0]");
	our $worksheet=$workbook->add_worksheet();
	our $format=$workbook->add_format();
	$format->set_bold();
	$format->set_color('red');
	$format->set_align('center');
	my $fruit_ref = &Openfiletoarray("$ARGV[0]");
	for (my $i=0;$i<@$fruit_ref;)
	{
      	      my $arg1 = @$fruit_ref[$i];
              my $arg2 = $i*4;
              &Getdatatoxlsx("$arg1","$arg2");
              sleep 1;
              $i++;
	}
	$workbook->close();
}else($ARGV[0] =~ m/.xls/i){
	our $execlname= $ARGV[0]; 
	our $file = $execlname.'.xls';
	our $sheetName = 'Sheet1';
        our $book = new Spreadsheet::WriteExcel($file);
        our $sheet = $book->add_worksheet( $sheetName );
	my $fruit_ref = &Openfiletoarray("$ARGV[0]");
	for (my $i=0;$i<@$fruit_ref;)
	{
            my $arg1 = @$fruit_ref[$i];
            my $arg2 = $i*4;
            &Getdatatoxls("$arg1","$arg2");
            sleep 1;
            $i++;
	}
	$book->close();
}


sub Openfiletoarray()
{
    my $filename = shift;
	my @APList;
	open(FILE,"<","$filename") or die"cannot open the file: $!\n";
	my @linelist=<FILE>;
	foreach my $eachline(@linelist){
        my @argument = split(/#/,$eachline);
        #print "$argument[0]\n";
        #print "$argument[1]\n";
        $argument[0] = &macchange("$argument[0]");
        #push(@APList,$argument[0]);
	}
	print "@APList \n";
	close FILE;
	return \@APList;
}

sub macchange()
{
        my $char = shift;
        my @argument = split(/:/,$char);
        my $str = join('',@argument);
        return $str;
}

sub Getdatatoxlsx(){
    my $apmac = shift;
    my $col = shift;
    my $dbh = DBI->connect($database,$db_user,$db_pass);
    $chomp($apmac);
    my $row = 1;
    my $sql = "SELECT * FROM `airocov_new_probe` WHERE apmac = '$apmac'";
    my $sth = $dbh->prepare($sql);
    $sth->execute() or die "can't execute the command:$dbh->errstr";
    my @datalist;
    while(@datalist = $sth->fetchrow_array()){
            $worksheet->write($row,$col,$datalist[1]);
			$worksheet->write($row,$col+2,$datalist[2]);
            $worksheet->write($row,$col+3,$datalist[3]);
            $worksheet->write($row,$col+4,$datalist[4]);
            $row++;
    }
    $sth->finish();
    $dbh->disconnect();
}

sub Getdatatoxls(){
    my $apmac = shift;
    my $col = shift;
    my $dbh = DBI->connect($database,$db_user,$db_pass);
	$chomp($apmac);
    my $row = 1;
    my $sql = "SELECT * FROM `airocov_new_probe` WHERE apmac = '$apmac'";
    my $sth = $dbh->prepare($sql);
    $sth->execute() or die "can't execute the command:$dbh->errstr";
    my @datalist;
    while(@datalist = $sth->fetchrow_array()){ 
            $sheet->write($row,$col,$datalist[1]);
			$sheet->write($row,$col+2,$datalist[2]);
            $sheet->write($row,$col+3,$datalist[3]);
            $sheet->write($row,$col+4,$datalist[4]);
            $row++;
    }
    $sth->finish();
    $dbh->disconnect();
}
