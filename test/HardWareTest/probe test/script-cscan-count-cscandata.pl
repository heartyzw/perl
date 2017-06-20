#!/usr/bin/perl -w
#Auther: David
#Script Name: check the probe data.
#Date: 2016/10/18
#Version: 1.0
#Abstract:
#Changelist: none
#Function: 读取探帧上传数据的时间戳判断是否连续确定探帧是否正常工作

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


open(FILE,"<","/home/airocov/pwd.txt") or die"cannot open the file: $!\n";
my @linelist=<FILE>;
foreach my $eachline(@linelist){
        my @argument = split(/\s+/,$eachline);
        print "$argument[0]\n";
        $argument[0] = &macchange("$argument[0]");
        &GetDatafromDB("$argument[0]");
}
close FILE;


##########################################################
sub GetDatafromDB(){
    #my $serial = shift;
    my $apmac  = shift;
    #my $mobile = shift;
    #my $file = $apmac.'.xls';
    #my $sheetName = 'Sheet1';

    #my $book = new Spreadsheet::WriteExcel($file);
    #my $sheet = $book->add_worksheet($sheetName);

    my $dbh = DBI->connect($database,$db_user,$db_pass);
    my $unix_start_time = `date +%s` - 600;
    my $unix_end_time = `date +%s`;
    my $sql = "SELECT  *  FROM `airocov_new_probe` WHERE time between $unix_start_time and $unix_end_time and apmac='$apmac'";
    #my $sql = "SELECT * FROM `airocov_new_probe` WHERE time between \"$unix_start_time\" and \"$unix_end_time\"";
    print $sql."\n";
    my $sth = $dbh->prepare($sql);
	
    $sth->execute() or die "can't execute the command:$dbh->errstr";
    my @datalist;
    my @timelist;
    while(@datalist = $sth->fetchrow_array()){
	    if ($datalist[4] =~ m/f016/i){
			#print $datalist[4]."\n";
		}
		else{
	    	push(@timelist,$datalist[4]);	
	}		
    }
    my %count;
	my @uniq_times = grep { ++$count{ $_ } < 2; } @timelist;
	#print "@uniq_times\n";
    my $countarry = @uniq_times;
	&wirte_maccount_to_data("$countarry","$apmac");
    $sth->finish();
    $dbh->disconnect();
    #$book->close();
    sleep 1;
	return $countarry;
}
=pod 
判断时间是否是连续的
=cut
sub serial(){  
        my($time)=@_;
	my $discretecount = 0;
	#print @time."\n";
        for(my $i=0;$i<@$time-1;$i++)
        {	
	    #print "@$time \n";
            my $argument1=@$time[$i];
            my $argument2=@$time[$i+1];
            #print "$argument1 \n";
            #print "$argument2 \n";
            if($argument1-$argument2 < 5){
				#print "--///////\n";
			}
            else{
                  $discretecount++;
            }
        }
	#print "---------\n";
        return  $discretecount;
        print $discretecount."\n";
}
#改变字符串格式将F016C4D5-08D5 转变成F016C4D508D5 或者 F0:16:C4:D5:08:D5 F016C4D508D5
sub macchange()
{
        my $char = shift;
        #my @argument = split(/-/,$char);
        my @argument = split(/:/,$char);
        my $str = join('',@argument);
        return $str;
}
#发送短信
sub sendmessage()
{   
        my $number = shift;
        #my $total = shift;
        #my $fail = $total - $number;
		print $number."\n";
		print "-------\n";
        #exit();
        #system("curl -G 'http://www.airocov.com/Certificate/Interface/hengdaMeg?name=星网云联&tel=15680597560&contents={$number}个正常,{$fail}个失败'");
        
}
=pod 
#传递数组
#my $argument1 = &Getcscan(\@APList);
#my($APList)=@_;        
#for(my $i=0;$i<@$APList;$i++)
=cut

sub wirte_maccount_to_data()
{
    my $count = shift;
	my $apmac = shift;
	my $sql = "INSERT INTO `airocov_maccount`(`maccount`,`apmac`) VALUES ('$count','$apmac')";
	my $dbh = DBI->connect($database,$db_user,$db_pass);
   # print $sql."\n";
    my $sth = $dbh->prepare($sql);
    $sth->execute() or die "can't execute the command:$dbh->errstr";
	$sth->finish();
    $dbh->disconnect();
}


 

