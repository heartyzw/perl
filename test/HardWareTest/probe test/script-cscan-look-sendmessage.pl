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

for (my $i=0;$i<1;$i++){
        my $argument1 = &Getcscan();
        &sendmessage("$argument1","$argument2");
}

sub Getcscan()
{
    my $unix_start_time = `date +%s` - 180;
    my $unix_end_time = `date +%s`;
        my $dbh = DBI->connect($database,$db_user,$db_pass);
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
                 print ("$datalist[0] \n");
         }
         else{
                 print "no this mac \n";
         }       
    }
    $count = @mac_number;
    print ("$count \n");
        return $count;
        $sth->finish();
    $dbh->disconnect();
}

sub sendmessage()
{   
        my $number = shift;
        my $total = shift;
        my $fail = $total - $number;
        print $fail."\n";
	#exit();
        system("curl -G 'http://www.airocov.com/Certificate/Interface/hengdaMeg?name=星网云联&tel=15208358256&contents={$number}个正常,{$fail}个失败'");
        system("curl -G 'http://www.airocov.com/Certificate/Interface/hengdaMeg?name=星网云联&tel=15680597560&contents={$number}个正常,{$fail}个失败'");
        system("curl -G 'http://www.airocov.com/Certificate/Interface/hengdaMeg?name=星网云联&tel=15108246412&contents={$number}个正常,{$fail}个失败'");
        system("curl -G 'http://www.airocov.com/Certificate/Interface/hengdaMeg?name=星网云联&tel=17780502868&contents={$number}个正常,{$fail}个失败'");
}

