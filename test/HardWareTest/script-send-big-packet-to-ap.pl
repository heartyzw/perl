#!/usr/bin/perl -w
#Auther: David
#Script Name: big ping packet to probe or AP. write data to database
#Function: big ping packet to probe or AP.
#Date: 2016/10/16
#Version: 1.0
#Abstract: 
#Changelist: none
#Notice: Server MUST install EXPECT on CPAN!
#Copy Right: AIROCOV

use Expect;
use Getopt::Std;


use H3CSwitch;
use AP;
use strict;
use warnings;

use DBI;
use Date::Parse;
use Spreadsheet::WriteExcel;
use Unicode::UTF8simple;
use DateTime;

our $dbname = "position";
our $location = "192.168.23.106";
our $port = "3306";
our $database = "DBI:mysql:$dbname:$location:$port";
our $db_user = "root";
our $db_pass = "1";
my @APList;

open(FILE,"<","/home/airocov/testforap/pwd.txt") or die"cannot open the file: $!\n";
my @linelist=<FILE>;
foreach my $eachline(@linelist){
	my @argument = split(/\s+/,$eachline);
	print "$argument[0]\n";
	print "$argument[1]\n";
	$argument[1] = &macchange("$argument[1]");
	push(@APList,$argument[1]);
	#print "@APList \n";
	for(my $i=0;$i<@APList;$i++) {
		for(my $i = 0;$i < 900;$i++){
			&InsertDatafromDB($argument[0],$argument[1]);
		}
	}
}	
}	
close FILE;

sub InsertDatafromDB {
    my $apaddr = shift;
    my $apmac = shift;
    my $sql;
	my $unix_time = `date +%s`;
    my $linux  = new AP('HostIP'=>"127.0.0.1");
    my @ret1   =$linux->cmd("ping -c 1 $apaddr -s 9000");
    if($ret1[1] =~ /.*1\sreceived/){
        $sql = "INSERT INTO `airocov_appingbig`(`time`,`apaddr`, `apmac`, `status`) VALUES ('$unix_time','$apaddr','$apmac','1')";
	}else{
	    $sql = "INSERT INTO `airocov_appingbig`(`time`,`apaddr`, `apmac`, `status`) VALUES ('$unix_time','$apaddr','$apmac','0')";
	}
    print "$sql \n";
    my $dbh = DBI->connect($database,$db_user,$db_pass);
    my $sth = $dbh->prepare($sql);
    $sth->execute() or die "can't execute the command:$dbh->errstr";
    $sth->finish();
    $dbh->disconnect();
}

sub macchange()
{
	my $char = shift;
	my @argument = split(/-/,$char);
	my $str = join('',@argument);
	return $str;	
}

