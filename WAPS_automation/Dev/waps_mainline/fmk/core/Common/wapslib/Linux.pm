#! /usr/bin/perl

####################################################################
#David add this package in 2016/08/18
####################################################################

package Linux;

#use strict;
use Net::SSH2;
use Net::SSH2::Expect;

sub new{
    my $class = shift;
    my %params = @_;
		
	#set default value of attribute, these attributes are allowed to transmit from param
    my $self = {
   		    'HostIP' =>undef,
    		'UserName'=>'root',
    		'Password'=>'1',
			'Port'=>'4119',
    		'Role' =>$class,
    	};
    	
    bless $self,$class;
    
    for my $attrib ( keys %params ) {
    		print "[Invalid parameter '$attrib' passed to '$class' constructor.]\n"
        		unless exists $self->{$attrib};
     	$self->{$attrib}= $params{$attrib} ;
    }

	return $self;
};

sub cmd{
    my $self=shift;
	my @ret;
	my @result;
    my $handle=$self->handle;
	my $host = $self->host_ip();
	my $port = '22';
	my $user = 'airocov';
	my $passwd = 'password';
	my $ssh2 = Net::SSH2->new();
	$ssh2->connect($host,$port);
	if ($ssh2->auth_password($user, $passwd)) {
	    foreach my $cmd (@_) {
		    @ret = Net_SSH2_CMD($ssh2, $cmd, sub {});
		}
	}
	
	if($ret[2] eq '0' and !$ret[1]) {
	    $result[0]='ok';
		$result[1]=$ret[0];
	}else{
        $result[0]='nok';
		$result[1]='execute this command fail';
	}
		
	# print "STDOUT: $ret[0]\n";
	# print "STDERR: $ret[1]\n";
	# print "EXITCODE: $ret[2]\n";
	return @result;	

}
	
sub Net_SSH2_CMD {
    my ($ssh, $cmd, $callback) = @_;
    my $timeout = 30;
    my $bufsize = 4096;
    #needed for ssh->channel
    $ssh->blocking(1);
    my $chan=$ssh->channel();
    $chan->exec($cmd);
    # defin polling context: will poll stdout (in) and stderr (ext)
    my $poll = [{ handle => $chan, events => ['in','ext'] }];
    # hash of strings. store stdout/stderr results
    my %std=();
    $ssh->blocking( 0 ); # needed for channel->poll
    while(!$chan->eof) {
        $ssh->poll($timeout, $poll);
        # number of bytes read (n) into buffer (buf)
        my( $n, $buf );
        foreach my $ev (qw(in ext)) {
            next unless $poll->[0]{revents}{$ev};
            #there are something to read here, into $std{$ev} hash
            #got n byte into buf for stdout ($ev='in') or stderr ($ev='ext')
            if( $n = $chan->read($buf, $bufsize, $ev eq 'ext') ) {
                $std{$ev} .= $buf;
            }
            if (ref($callback) eq 'CODE' && $std{$ev}) {
                $callback->($std{$ev}, $chan, $ev eq 'ext' ?
                                                  'stderr' : 'stdout');
            }
        }
    }
    $chan->wait_closed(); #not really needed but cleaner
    my $exit = $chan->exit_status();
    $chan->close(); #not really needed but cleaner
    $ssh->blocking(1); # set it back for sanity (future calls)
    my @result=($std{in}, $std{ext}, $exit);
	return @result
}


=pod
    Function: Set and get the expect handle of the AP;
    Param: 1. expect handle
    Return: the current expect handle;
	
    Example:
          my $handle = $this->handle();
          my $handle = $this->handle($new_handle);
=cut

sub handle{
    my $self = shift;
    if(@_){
          $self->{Handle}=shift;
    }
    return $self->{Handle};
}

=pod
    Function: Change and get the password for administrator
    
    Param:1. password for administrator
    
    Example:
         1. my $admin_password = $this->admin_passwd();
=cut

sub admin_passwd{
    my $self = shift;
    if (@_) { $self->{AdminPasswd} = shift }
    return $self->{AdminPasswd};
}

=pod
    Function: Change and get the administrator name of the switch instance
    Param: 1. administrator user name
	
    Return: return the current administrator name
	
    Example:
          1. my $admin = $this->admin_user();
          2. my $admin = $this->admin_user("admin");
=cut

sub admin_user{
    my $self = shift;
    if (@_) { $self->{AdminUser} = shift }
    return $self->{AdminUser};
}

=pod
    Function: Change and Fetch hostip of the switch instance
    Param:1.host ip address.
    
    Return: return the current HostIP address

    Example:
    1. my $host_ip = $this->host_ip();
    2. my $host_ip = $this->host_ip("192.168.1.2");
=cut

sub host_ip{
    my $self = shift;
    if (@_) { $self->{HostIP} = shift }
    return $self->{HostIP};
}


return 1;
