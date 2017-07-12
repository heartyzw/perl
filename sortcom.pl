#!/usr/bin/perl -w
use strict;
use warnings;
use Unicode::UTF8simple;
my @Gilist;
# author uyzw
'rm ./pwd1.txt';
`cat pwd.txt | grep "^f[0-4]" |cut -d " " -f 16 | sort -V -u  >> ./tmp.txt`;
open(FILE,"<","./tmp.txt" ) or die "can not open the file";
my @linelist=<FILE>;
foreach my $eachline(@linelist){
    $eachline = &macchange("$eachline");
    push(@Gilist,$eachline);
}
#print @Gilist;
#`rm ./tmp.txt`;
close FILE;
for (my $i=0;$i<@Gilist;$i++ )
{
       open(FILE,"<","./pwd.txt" ) or die "can not open the file";
       my @linelistt=<FILE>;
       foreach my $eachline(@linelistt){
            my @argument = split(/\s+/,$eachline);
            $argument[3] = &macchange("$argument[3]");
            #print "$argument[3]\n";
            #print "$Gilist[$i]\n";
            chomp($argument[3]);
            chomp($Gilist[$i]);
             if( $argument[3] eq $Gilist[$i] )
            #if(  $Gilist[$i] =~ /$argument[3]/ )
             # if(( $argument[3] cmp $Gilist[$i] ) ==0 )
            {  
                if(  $Gilist[$i] =~ /GigabitEthernet1024/ )
                {
                }else{
                    print "xxx\n";
                    open(FI,">>","./pwd1.txt" ) or die "can not open the file";
                    print FI "$eachline";
                    close (FI);
                    print $eachline."\n";
                }
            }
    }   
    close FILE;
}
sub macchange()
{
        my $char = shift;
        my @argument = split(/\//,$char);
        my $str = join('',@argument);
        return $str;
}
