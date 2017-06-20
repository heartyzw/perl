#!/bin/bash
root_id=`id -u`
if [ $root_id -ne 0 ] ; then
{
   clear
   echo -e "\033[40;37mWarning: you are not root user ! \n\n[Please use Command line ]$ sudo su \n\n \033[0m"
   exit 10
}
fi
for prot in {10000..10005}
do
	iperf3 -s -p $prot
done
