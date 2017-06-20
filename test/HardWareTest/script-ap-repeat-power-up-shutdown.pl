#!/usr/bin/perl -w

#Auther: David
#Script Name: repeat power up shutdown.
#Function: Restart the device to determine whether it can be started, while the data written to the database
#Date: 2016/10/16
#Version: 1.0
#Abstract: when power up the ap, wait 60 sec, test pc send a ping packet to the ap. 
#Changelist: none
#Notice: Server MUST install EXPECT on CPAN!
#Copy Right: AIROCOV

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
open(FILE,"<","./pwd.txt") or die"cannot open the file: $!\n";
my @linelist=<FILE>;
foreach my $eachline(@linelist){
	    my @argument = split(/\s+/,$eachline);
		print "$argument[0]\n";
		print "$argument[1]\n";
		$argument[1] = &macchange("$argument[1]");
		push(@APList,$argument[0]);
		push(@APList,$argument[1]);
		print "@APList \n";
}
close FILE;
my $switch = new H3CSwitch('HostIP'=>"10.20.0.251");
my $interface = "int gi 1/0";
my $switch1 = new H3CSwitch('HostIP'=>"10.20.0.250");
#my $interface = "int gi 1/0";
my @cmd_enable;
my @cmd_disable;
for(my $i=1;$i<=20;$i++){
    push(@cmd_enable,join("/",$interface,$i));
    push(@cmd_enable,"poe enable");
    push(@cmd_disable,join("/",$interface,$i));
    push(@cmd_disable,"undo poe enable");
}
my @result1;
my @result2;

for(my $i=1;$i<=100;$i++){
    $switch->connect_cli();
    @result1=$switch->cmd("sys",@cmd_enable);
    $switch->disconnect();
	sleep 60;
	#foreach my $eachline(@APList){
	 #   print "$eachline \n";
         # &InsertDatafromDB("$eachline");
    #}
	#while(@APList){
	   # my $arg1 = pop@APList;
		#my $arg2 = pop@APList;
		#&InsertDatafromDB("$arg2","$arg1");
	#}
	for (my $i=0;$i<@APList;)
	{
	   my $arg1 = @APList[$i];
	   my $arg2 = @APList[$i+1];
	   $i=$i+2;
	   &InsertDatafromDB("$arg1","$arg2");
	}
    $switch->connect_cli();
    @result2=$switch->cmd("sys",@cmd_disable);
    $switch->disconnect();
    sleep 10;
}

sub InsertDatafromDB(){
    my $apaddr = shift;
    my $apmac = shift;
    my $sql;
    my $linux  = new AP('HostIP'=>"127.0.0.1");
    my @ret1   =$linux->cmd("ping -c 1 $apaddr");
    if($ret1[1] =~ /.*1\sreceived/){
	    $sql = "INSERT INTO `airocov_apshutdown`(`apaddr`, `apmac`, `status`) VALUES ('$apaddr','$apmac','1')";
	}else{
	    $sql = "INSERT INTO `airocov_apshutdown`(`apaddr`, `apmac`, `status`) VALUES ('$apaddr','$apmac','0')";
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
