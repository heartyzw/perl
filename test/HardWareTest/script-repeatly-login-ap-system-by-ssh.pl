#!/usr/bin/perl -w
#/usr/bin/perl
#Auther: David
#Script Name: repeatly login ap system by ssh.
#Function: repeatly login ap system by ssh.
#Date: 2016/10/19
#Version: 1.0
#Abstract: use this script repeatly login the ap system by ssh, and test the flash and ddr. write the data to database
#Changelist: none
#Notice: Server MUST install EXPECT on CPAN!
#Copy Right: AIROCOV

use Expect;
use Getopt::Std;
our $result = "ssh";

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
open(FILE,"<","./pwd.txt") or die"cannot open the file: $!\n";
my @linelist=<FILE>;
foreach my $eachline(@linelist){
	my @argument = split(/\s+/,$eachline);
	print "$argument[0]\n";
	print "$argument[1]\n";
	$argument[1] = &macchange("$argument[1]");
	push(@APList,$argument[1]);
	#print "@APList \n";
	for(my $i=0;$i<100;$i++) {
        &InsertDatafromDB($argument[0],$argument[1]);
	}
}	
close FILE;


sub InsertDatafromDB(){
    my $apaddr = shift;
    my $apmac = shift;
    my $sql;
    my $exp     = new Expect;
    my $command = "ssh -p4119 root\@$apaddr";
    $exp->spawn($command) or die "Cannot spawn $command: $!\n";
    my $pass = $exp->expect( 6, 'connecting' );
    $exp->send("yes\r\n") if ($pass);
    $pass = $exp->expect( 6, 'password' );
    $exp->send("1\r\n");

    $pass = $exp->expect( 6, '#' );
    if($pass eq '1'){
        #`echo $host $mac >> "/tmp/result/success_$result.txt"`;
        #$exp->send("ifconfig\r\n");
		$sql = "INSERT INTO `airocov_apssh`(`apaddr`, `apmac`, `status`) VALUES ('$apaddr','$apmac','1')";
    }else{
        #`echo $host $mac >> /tmp/result/failure_$result.txt`;
		$sql = "INSERT INTO `airocov_apssh`(`apaddr`, `apmac`, `status`) VALUES ('$apaddr','$apmac','0')";
    }
    $pass = $exp->expect( 6, '#' );
    $exp->send("exit\r\n");
	
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
