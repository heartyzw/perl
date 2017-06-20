#!/usr/bin/perl -w

use strict;
use warnings;
use DBI;
use Date::Parse;
use Unicode::UTF8simple;
use DateTime;
use Expect;


my @IPlist;
open(FILE,"<","./macip.txt") or die "can not open file: $!\n";
my @linelist=<FILE>;
foreach my $eachline(@linelist){
    my @argument = split(/\s+/,$eachline);
    $argument[0] = &macchange("$argument[0]");
    push(@IPlist,$argument[0]);
    push(@IPlist,$argument[1]);
    &copyfile("$argument[0]");
    sleep 1;
    &sshAP("$argument[0]");
}
close FILE;

sub macchange()
{
    my $char = shift;
    my @argument = split(/:/,$char);
    my $str = join('',@argument);
    return $str;
}


sub copyfile()
{
    my $host = shift;
    my $sourdir = "./wireless";
    my $destdir = "/etc/config/wireless";
    chomp($sourdir);
    chomp($destdir);
    chomp($host);
    my $exp  = new Expect;
    #my $command = "scp -P 4119 $sourdir"."\/$file root\@$host:"."$destdir"."\/$file";
    my $command = "scp -P 4119 $sourdir root\@$host:"."$destdir";
    print "$command\n";
    $exp->spawn($command) or die "Cannot spawn $command: $!\n";
    my $pass = $exp->expect( 6, '(yes/no)?' );
    #$exp->send("yes\r\n");
    $exp->send("yes\r\n") if ($pass);
    $pass = $exp->expect( 6, 'password:' );
    $exp->send("1\r\n");
    $pass = $exp->expect( 10, '100%' );
    if($pass) {
        print("success!\n");
    }else{
        print("fail!\n")
    }
}

sub sshAP()
{
    my $host = shift;
    chomp($host);
    my $exp     = new Expect;
    my $command = "ssh -p4119 root\@$host";
    $exp->spawn($command) or die "Cannot spawn $command: $!\n";
    my $pass = $exp->expect( 6, 'connecting' );
    $exp->send("yes\r\n") if ($pass);
    $pass = $exp->expect( 6, 'password' );
    $exp->send("1\r\n");
    my $ac_restart="wifi";
    chomp($ac_restart);
    $pass = $exp->expect( 6, '#' );
    $exp->send("$ac_restart\r\n");
    $pass = $exp->expect( 6, '#' );
    $exp->send("exit\r\n");
}
