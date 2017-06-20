#!/usr/bin/perl
use Cwd;	                      	            #获取当前目录路径
use Sys::Hostname;                            	#获取主机名
use Socket;                                   	#用于获取IP地址
use Net::SMTP;                                	#用于发送邮件
use Authen::SASL;                             	#用于验证邮件的用户名和密码
use File::Basename;					            #用于取得脚本的名字
use Filesys::Df;								#用于获取磁盘分区信息
#require 'sys/ioctl.ph';                       	#用于获取IP地址
#require 'DBI.pm';								#用于连接mysql数据库，不需要请注释掉(前面添加#)
#require 'DBD/mysql.pm';							#用于连接mysql数据库，不需要请注释掉
use AP;
use DBI;
use Date::Parse;
use Spreadsheet::WriteExcel;
use Unicode::UTF8simple;
use DateTime;


#发送邮件设置,需要修改
my $site = '163.com';							#用于标识发送邮件时的邮件域
my $smtp_host = 'smtp.163.com' ;          	    #发送的邮件服务器
my $from = 'yzw19941217@163.com';        		#发送邮件的帐号
my $password = '19941217';                		#帐号密码
my $to = '823040905@qq.com';            	    #收件人
my $subject = 'cscan信息';					#设置邮件主题
my $from_info = '服务器监控邮件';				#设置发件人信息
# my $to2 = '123456@163.com'; 					#设置第二个个收件人
# my $to3 = '321654@qq.com';  					#设置第三个个收件人
my $basename = basename $0; 
my $temp_log = "/tmp/$basename.log";			#临时文件,用于写入系统信息,用完后会删除

# mysql connetion
my %mysql = (
	'dbname' => "position",
	'host' => "192.168.23.106",
	'port' => 3306,
	'user' => 'root',
	'pass' => '1',
);


#调用主函数执行程序
&main;

#主函数调用其他函数
sub main {
	my $refs = &Openfile();
	&Apstatus();
    &Getcscanstatus(\@$refs,"airocov_xwyl_cache");
	#打开临时文件，读取文件的内容并发送邮件
	open READLOG,"<","$temp_log" or die "Can't read $temp_log : $!";
	@temp_information = <READLOG>;
	close READLOG;
	&SendMail(@temp_information);
	#system("rm /tmp/$basename.log");

}
#发送邮件函数
sub SendMail {
	eval {
	      my $smtp = Net::SMTP->new($smtp_host,Timeout=>30,Hello=>$site);
	      $smtp-> auth($from, $password) or die "Email user or password Auth Error!\n";
	      $smtp-> mail($from);
	      $smtp-> to($to);
	      #$smtp-> to($to,$to2,$to3);		#同时发送给多个人
	      $smtp-> data();
		  $smtp-> datasend("Subject: $subject\n");
		  $smtp-> datasend("From: $from_info\n");
		  $smtp-> datasend("To: $to");
		  $smtp-> datasend("\n" );
		  $smtp-> datasend("Mime-Version:1.0\n");		
		  $smtp-> datasend("Content-Type: text/html;charset=utf-8\n");	
		  $smtp-> datasend("Content-Transfer-Encoding: quoted-printable\n\n");
		  $smtp-> datasend("@_\n" );
	      $smtp-> dataend();
	      $smtp-> quit;
	};
	if ($@) {
		print RUNLOG "Occurred Error ($@)\n";
	}
}
#获取ap和cscan的PING状态
sub Apstatus()
{
	#my $mac = shift;
	#my $ip = shift;
	open WRITELOG,">","$temp_log" or die "Can't write $temp_log : $!";
	open(FILE,"<","./pwdmacip.txt") or die"cannot open the file: $!\n";
	my @linelist=<FILE>;
	foreach my $eachline(@linelist){
        my @argument = split(/#/,$eachline);
        $argument[0] = &macchange("$argument[0]");
		push(@List,$argument[0]);
		push(@List,$argument[1]);
		print $argument[1]."\n";
		my $linux  = new AP('HostIP'=>"127.0.0.1");
		my @ret1   =$linux->cmd("ping -c 3 $argument[1]");
		if($ret1[1] =~ /.*3\sreceived/){
			print WRITELOG "$argument[0] $argument[1] ping success\n";
		    print "$argument[0] $argument[1] ping success\r\n";
		}else{
			print WRITELOG "$argument[0] $argument[1] ping failure\n";
			print "$argument[0] $argument[1] ping failure\r\n";
		}
	close (FILE);
	close (WRITELOG);
	}
}
#get cscan的数据status
sub Getcscanstatus()
{
	my  ($ap) = shift;
	my  $table_name = shift;
	#my	$unix_start_time= `date +%s` -180;
	#my  $unix_end_time=` date +%s`;
    my $unix_start_time = `date +%s` -120 ;
    my $unix_end_time = `date +%s`-60;
	my  $database = "DBI:mysql:$mysql{'dbname'}:$mysql{'host'}:$mysql{'port'}";
    my  $dbh = DBI->connect($database,$mysql{'user'},$mysql{'pass'}) or die ("can not connect to database:$DBI::errstr");
	$dbh->do("SET character_set_client='utf8'");
	$dbh->do("SET character_set_connection='utf8'");
	$dbh->do("SET character_set_results='utf8'");
    #$sth = $dbh->prepare("SELECT  *  FROM `airocov_new_probe` WHERE time between $unix_start_time and $unix_end_time and apmac='$apmac'");
	#my $sql ="SELECT distinct apmac FROM  `$table_name` WHERE time between $unix_start_time and $unix_end_time";
	#print $sql."\n";
	$sth = $dbh->prepare("SELECT distinct apmac FROM  `$table_name` WHERE time between $unix_start_time and $unix_end_time");
	#time between \"$unix_start_time\" and $unix_end_time
	#$sth = $dbh->prepare("SELECT distinct apmac FROM  `$table_name` WHERE 1");
    $sth->execute() or die "无法执行SQL语句:$dbh->errstr";
	print "----------------";
	open WRITELOG,">","$temp_log" or die "Can't write $temp_log : $!";
    my @macnumber;
	while(my @data = $sth->fetchrow_array()){
		if ($data[0]=~m/f[0-9]16/i){
			print $data[0]."\n";
			push(@macnumber,$data[0]);
			print WRITELOG "$data[0] cscan is running\n";
			print "----------------\n";
		}else{
			print "no this mac \n";
		}
	}
	my $refs_three = &diff(\@macnumber,\@$AP);
	for(my $i=0; $i <@$refs_three;$i++)
	{
	   print WRITELOG "@$refs_three[$i] is Abnormal\n";	
	}
    close (WRITELOG);
}

sub macchange()
{
	my $char = shift;
	#my $flag = shift;
	my @argument = split(/:/,$char);
	my $str = join('',@argument);
	return $str;
}
sub diff()
{
    my($arry_one)=shift;
	my($arry_two)=shift;
	my @union=();#并集  
	my @diff=(); #差集   
	my @isect=();#交集  
	my $e;
	my $union;
	my $isect;
	my %union;
	my %isect;
	foreach $e(@$arry_one,@$arry_two){  
		$union{$e}++&&$isect{$e}++;  
	}  
	@union=keys %union;  
	@isect=keys %isect;  
	@diff=grep {$union{$_}==1;} @union;  
	
	#print join(',', @$a),"\n";
	#print join(',', @$b),"\n";
	#print join(',', @diff),"\n";
	return \@diff;
}

sub Openfile()
{
	my $filepath = shift;
	my @APList;
	#open(FILE,"<","$filepath") or die"cannot open the file: $!\n";
	open(FILE,"<","./pwd.txt") or die"cannot open the file: $!\n";
	my @linelist=<FILE>;
	foreach my $eachline(@linelist){
        my @argument = split(/\s+/,$eachline);
        $argument[0] = &macchange("$argument[0]");
		push(@APList,$argument[0]);
	}
	close FILE;
	return \@APList;
}