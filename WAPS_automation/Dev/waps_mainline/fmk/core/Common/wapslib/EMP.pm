#!/usr/bin/perl

package EMP;

sub new
{
    my $class = shift;
    my $self  = {
        mac  => shift,
        vlan => shift,
        interface => shift,
        age  => shift,
        ipaddr => shift,
        type => shift,
    };

    bless $self, $class;
    return $self;
}

sub TO_JSON { return { %{ shift()}};} 
