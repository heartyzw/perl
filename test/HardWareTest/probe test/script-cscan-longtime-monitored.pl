#!/usr/bin/perl -w
use H3CSwitch;
use AP;
use strict;
use warnings;
use DBI;
use Date::Parse;
use Spreadsheet::WriteExcel;
use Unicode::UTF8simple;
use DateTime;

my $dbname = "position";
my $location = "192.168.23.106";
my $port = "3306";
my $database = "DBI:mysql:$dbname:$location:$port";
my $db_user = "root";
my $db_pass = "1";

our $count;
our $argument2 = 10;

my @APList;
open(FILE,"<","/home/airocov/pwd.txt") or die"cannot open the file: $!\n";
my @linelist=<FILE>;
foreach my $eachline(@linelist){
	my @argument = split(/\s+/,$eachline);
	#print "$argument[0]\n";
	#print "$argument[1]\n";
	$argument[0] = &macchange("$argument[0]");
	push(@APList,$argument[0]);
}		
close FILE;
	

for (my $i=0;$i<1;$i++){
	my $argument1 = &Getcscan(\@APList);
	&sendmessage("$argument1","$argument2");
        #open( my $i, '>', './fruit.out' ) or die $!;
}

sub Getcscan()
{
    my($APList)=@_; 
    #print("@$APList\n");
    #print("$@$APList[1]\n");
    #print("@$APList[0]\n");
    my $unix_start_time = `date +%s` - 180;
    my $unix_end_time = `date +%s`;
	
    my $file ='/home/airocov/yzw/'.$unix_start_time.'.xls';
    #my $file = 'datasheet.xls';
    my $sheetName = 'Sheet1';
    my $dbh = DBI->connect($database,$db_user,$db_pass);
    my $book = new Spreadsheet::WriteExcel($file);
    my $sheet = $book->add_worksheet($sheetName);
    my $row = 1;
    my $col = 1;
    my $sql = "SELECT distinct apmac FROM `airocov_new_probe` WHERE time between \"$unix_start_time\" and $unix_end_time";
    #SELECT distinct apmac FROM airocov_new_probe
    #print "----------------\n";
    #print "$sql \n";
    #print "----------------\n";
    my $sth = $dbh->prepare($sql);
    $sth->execute() or die "can't execute the command:$dbh->errstr";
    my @datalist;
	my @mac_number;
	
    while(@datalist = $sth->fetchrow_array())
    {
	 if($datalist[0] =~ m/f416/i){
		 push(@mac_number,$datalist[0]);
		 #print ("$datalist[0] \n");
		 #$sheet->write($row,$col,$datalist[0]);
		 #$sheet->write($row,$col+1,1);
		 #$row++;
	 }
	 else{
		 print "no this mac \n";
	 }	 
    }
    $count = @mac_number;
	#$row = @mac_number;
	for(my $i=0;$i<@$APList;$i++){
		#print("@$APList[$i]\n");
		for(my $j=0;$j<@mac_number;$j++)
		{
			if (@$APList[$i] eq $mac_number[$j] ){
			    print "@$APList[$i] eq $mac_number[$j]\n";
				$sheet->write($row,$col,@$APList[$i]);
				$sheet->write($row,$col+1,1);
				$row++;
			}
		}	
	}
	$row = $count+2;
	for(my $i=0;$i<@$APList;$i++){
	    $row++;
		$sheet->write($row,$col,@$APList[$i]);
		$sheet->write($row,$col+1,);
	}
    print ("$count \n");
	return $count;
	$sth->finish();
    $dbh->disconnect();
	$book->close();
}
sub macchange()
{
	my $char = shift;
	#my @argument = split(/-/,$char);
	my @argument = split(/:/,$char);
	my $str = join('',@argument);
	return $str;	
}
sub sendmessage()
{   
	my $number = shift;
	my $total = shift;
	my $fail = $total - $number;
	exit();
	system("curl -G 'http://www.airocov.com/Certificate/Interface/hengdaMeg?name=星网云联&tel=15680597560&contents={$number}个正常,{$fail}个失败'");
        system("curl -G 'http://www.airocov.com/Certificate/Interface/hengdaMeg?name=星网云联&tel=15108246412&contents={$number}个正常,{$fail}个失败'");	
}



