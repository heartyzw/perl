#!/usr/bin/perl -w

####################################################################
#David add this package in 2016/08/12
#Caesar update the script's format in 2016/08/16
####################################################################

package H3CSwitch;

use Expect;
use strict;


# /*!
#    @function new  
#        @param HASH Any of the following key-value pair in the HASH are OPTIONAL when you new the object, provide key-pair only when you need use them.
#        @param CLIMode=>'climode', use cli via 'console'(serial port) or 'ssh'. default set as 'ssh' mode.
#        @param	HostIP=>switch manage ip address.
#        @param	SSHPort=>'sshport', ssh connection port, default set as 22
#        @param	AdminUser=>'adminuser', xtm admin user name, default set as 'admin'
#        @param	AdminPasswd=>'adminpasswd', xtm admin user's password, default set as 'password'
#  	
#    @return   
#     1. object, if sucess
#     2. undef, if fail
#    <h2>Example:</h2>
#    <pre>
#		my $switch = new H3CSwitch('HostIP'=>'192.168.1.1');
#    </pre>
#
# */
sub new{
    my $ret;
    my $class = shift;
    my %params = @_;
		
    #set default value of attribute, these attributes are allowed to transmit from param
    my $self = {
        'CLIMode' =>'ssh',
        'SSHPort'=>22,
        'AdminUser'=>'admin',
        'AdminPasswd'=>'password',
        'id' =>undef,
        'HostIP'=>undef,
        'Name'=>undef,
        'Model' => '5120',
    };
	
    bless $self,$class;
	
    for my $attrib ( keys %params ) {	
        $self->{$attrib}= $params{$attrib} ;
    }

    #{IfNewHandle}It is use for judge if need call disconnect at the end of some method which use cli do something
    #{HandleType} is to record what kind of handle process it was created. console/ssh
    $self->{ConnectNum}=0;
	
    return $self;
}

##20120725, add API, sw_model, it's can be call form other side
=pod
    Function: Change and Fetch model of the switch instance
    Param:1.model name.
    Return: return the current model name
    Example:
    1. my $sw_model = $this->model();
=cut
sub sw_model{
    my $self = shift;
    if (@_) { $self->{Model} = shift }
    return $self->{Model};
}

=pod
    Function: change the connection mode.
    Param :1. 'ssh' ,modify the connection mode to ssh
    Param: 2. 'console', modify the connection mode to console
	
    Return:
    return the current connection mode;
    Example:
    1. my $cli_mode = $this->cli_mode("ssh");
    2. my $cli_mode = $this->cli_mode();
=cut

sub cli_mode {
    my $self = shift;
    if (@_) { 
        if(($_[0] eq 'ssh')||($_[0] eq 'console')){
            $self->{CLIMode} = shift ;
        }else{
            print "invalid input value $_[0] for XtmCli->climode. Should input ssh or console \n";
        }
    }
    return $self->{CLIMode};
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
    Function: Set and get the last prompt from expect
    Param: 1. last prompt
		
    Return: the last prompt of expect
		
    Example:
          1. my $last_prompt = $this->latest_prompt();
	  2. my $last_prmpt = $this->latest_prompt("this is the latest prompt");
=cut

sub latest_prompt{
    my $self = shift;
    if (@_) { $self->{LatestPrompt} = shift }
    return $self->{LatestPrompt};
}	

=pod
    Function: Set and get the expect handle of the switch;
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
    Function: Connect to switch
    Param: null
    Return: 
    1. 'ok', mean connection successfully
    2. 'nok', mean connection failed
	
    Example:
    my $ret = $this->connect_cli();
    if($ret eq 'ok'){
        print "connect successfully\n";
    }else{
        print "Connect failed\n";
    }
=cut

sub connect_cli{
    my $self = shift;
    my $exp = new Expect; 
    my $timeout=40;
    my $adminuser;
    my $adminpasswd;
    my $hostip;
    my $sshport;
    my $result='ok';
    my $connectnum;
	
    $adminuser=$self->admin_user;	
    $adminpasswd=$self->admin_passwd;
    $hostip = $self->host_ip;
 
    if(!defined($hostip)){
        print("error", "no hostip", __FILE__, __LINE__);
	return 'nok';
    }

    if(defined($self->handle)){
        return 'ok';
    }else{
        $exp = Expect->spawn("telnet $hostip") or return "nok";
        $self->handle($exp);
    }

    $exp->expect($timeout,

        [
        qr/[[Uu]sername:/,
        sub {
            my $fh = shift;
            $fh->send("$adminuser\r");
 	        exp_continue;
        }
        ],
		
        [
        qr/[Pp]assword:/,
        sub {
            my $fh = shift;
            $fh->send("$adminpasswd\r");
 	        exp_continue;
        }
        ],
	
        [
        eof =>
        sub {
            print "meet EOF\n";
            $result='nok';
        }
        ],

        [
        timeout =>
        sub {
            $result='nok';
            print "connect_cli:WAPS go into timeout..\n";
            print "WAPS-CLI-TIMEOUT\n";
         
        }
        ],
	   
        '-re', qr/<H3C>/,
    );
      
    if($result eq 'nok'){
        $exp->hard_close;
	    $self->{Handle}=undef;
	    return 'nok';
    }
	
    return 'ok';
}

=pod
    Function: disconnect to switch and set handle to undef
    Param: null
    Return: 'ok';
	
    Example:
        $this->disconnect();
=cut

sub disconnect{
    my $self = shift;
    my $result = 'ok';
    my $handle = $self->handle;
	

    #print "before disconnect, handle=$handle \n";
    if(!defined($handle)){
        print "Current handle is undef, disconnect need do nothing. Return ok\n";
	return 'ok';
    }
		
    my $timeout=30;
    $handle->send("\r");
    $handle->expect($timeout,
    [
        qr /H3c.*]/,
	sub {
            my $fh = shift;
		$fh->send("quit\n");
		exp_continue;
	}
    ],

    [
	qr /H3C.*]/,
	sub {
            my $fh = shift;
	    $fh->send("quit\n");
	    exp_continue;
	}
    ],

    [
        qr /<H3C>/,
        sub {
	    my $fh = shift;
	    $fh->send("quit\n");
            exp_continue;
	}
    ],

    [
        timeout =>
	sub {
	    print "[CLI disconnect wait TimeOut]\n";
	    $result="nok";
	}
    ],

    [
	eof =>
	sub {
	    print "meet EOF,for disconnect this should be good\n";
            $result='ok';
	}
    ],
    );

    if($result eq 'nok'){
        $handle->hard_close();
    }
    $self->{Handle} = undef;
  
    return 'ok';
}

=pod
    Function: Execute command through the connection to switch.
    Param: commands
    Return: @result: $result[0] is 'ok' or 'nok', indicate if the command execute successfully. $result[1] contain the output of the commands
	
    Example: 
	my @result = $this->cmd("config", "interface g0/4");
	if($result[0] eq 'nok'){
	    print "command failed\n";
	}
=cut

sub cmd{
    my $self=shift;
    my $handle=$self->handle;
    my $timeout=150;
    my $cmd_output=$self->handle->match; #just a trick, let output 1st line show shell prompt
    my @result=('ok',$cmd_output);

    if(!defined($handle)){
	    #resource_log("error", "no connection", __FILE__, __LINE__);
	    $result[0] = 'nok';
	    $result[1] = "no connection";
	    return @result;;
    }

    my $sw_modelname = $self->sw_model(); 

    foreach my $cmd (@_){

        if($cmd eq '?'){
	        print "does not support \? command yet";
	        $result[0] = 'ok';
	        last;
	    }else{
	    #if(($self->latest_prompt eq '[H3C]') and ($cmd eq 'quit')){
            #$result[0] = 'ok';
            #last;
       #}
            $handle->send($cmd."\r");
        }
		
        my ($matched_pattern_position,
        $error,
        $successfully_matching_string,
        $before_match,
        $after_match)
        =$handle->expect($timeout,

            [
            '-re', qr/\<H3C\>/,
         	sub{
         	    $self->latest_prompt($handle->match);
         	    $result[0] = 'ok';
                     #$output = $handle->exp_before();
         	}
            ],
         			
            [
         	'-re', qr/\[H3C.*\]/,
         	sub{
         	    $self->latest_prompt($handle->match);
         	    $result[0] = 'ok';
            #$output = $handle->exp_before();
         	}
            ],

            [
         	timeout =>
         	sub {
         	    $result[0]='nok';
         	    print "switch timeout\n";
         	    }
            ],
        );
    #push the output into result
    if(defined($successfully_matching_string)){
        $cmd_output="$cmd_output"."$before_match"."$successfully_matching_string"."$after_match";
    }
		
    $result[1]=$cmd_output;			
    if($result[0] eq 'nok') {
	    print "switches execute cmd error\n";
	    last;
        }
    }
    return @result;	
}

=pod
    Function: Reboot switch
    Param: null
    Return: 'ok'/'nok';
	
    Example:
	$ret = $this->reboot();
=cut

sub reboot{
    my $this = shift();
    return 'ok';
}

1;
__END__
