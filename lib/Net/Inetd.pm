# $Id: Inetd.pm,v 0.02 2004/01/20 12:14:09 sts Exp $

package Net::Inetd;

use 5.006;
use base qw(Exporter);
use strict;
use warnings;

our $VERSION = '0.02';

use Tie::File;

our $enable;

our ($CONF, 
     $ENABLED, 
     $INETD_CONF,
);

$CONF = 'CONF';
$ENABLED = 'ENABLED';
$INETD_CONF = '/etc/inetd.conf';

sub croak { 
    require Carp;
    &Carp::croak;
}

sub new {
    my ($pkg, $conf) = @_;
    
    my $class = ref $pkg || $pkg;
    return bless _class_data($conf), $class; 
}

sub is_enabled {
    my ($o, $serv, $prot) = @_;
    croak q~usage: $Inetd->is_enabled ($service => $protocol)~
      unless $serv && $prot;
    
    return defined $o->{$ENABLED}{$serv}{$prot}
      ? $o->{$ENABLED}{$serv}{$prot}
      : undef;
}

sub enable { local $enable = 1; &_set }
sub disable { &_set }

sub dump_enabled { local $enable = 1; &_dump }
sub dump_disabled { &_dump }

sub _class_data {
    my $conf_file = $_[0];
    
    $conf_file ||= $INETD_CONF;
    
    my %data;    
    _tie_conf(\@{$data{$CONF}}, \$conf_file);    
    %{$data{$ENABLED}} = %{_parse_enabled(@{$data{$CONF}})};
    
    return \%data;
} 

sub _tie_conf {
    my ($conf, $file) = @_;
    
    tie @$conf, 'Tie::File', $$file
      or croak qq~couldn't tie $$file: $!~;
}   

sub _parse_enabled {
    my (%is_enabled, @serv);     
    _filter_conf(\@_);
    foreach (@_) {
	_split_serv(\@serv, \$_);	
	my ($serv, $prot) = (shift @serv, splice @serv,1,1);
	
	if (!/^\#/) { $is_enabled{$serv}{$prot} = 1 }
	else { $is_enabled{$serv}{$prot} = 0 }
    }
    
    return \%is_enabled;
} 

sub _set {
    my ($o, $serv, $prot) = @_;
    my $sub = $enable ? 'enable' : 'disable';
    croak qq~usage: \$Inetd->$sub (\$service => \$protocol)~
      unless $serv && $prot;
    
    my $ret_state = 0;
    for (my $i = 0; $i < @{$o->{$CONF}}; $i++) {
        if ($o->{$CONF}[$i] =~ /$serv.*$prot\b/) {
	    if ($enable) {
	        if ($o->{$CONF}[$i] =~ /^\#/) {
	            $o->{$CONF}[$i] = substr $o->{$CONF}[$i], 
		      1, length $o->{$CONF}[$i];
		    $o->{$ENABLED}{$serv}{$prot} = 1;
		    $ret_state = 1;
		}
            } 
	    elsif ($o->{$CONF}[$i] !~ /^\#/) {
	        $o->{$CONF}[$i] = '#'.$o->{$CONF}[$i];
		$o->{$ENABLED}{$serv}{$prot} = 0;
		$ret_state = 1;
	    }      
	}    
    } 
     
    return $ret_state;
} 

sub _dump {
    my $o = $_[0];
    
    my @dump;
    my @conf = @{$o->{$CONF}}; _filter_conf(\@conf);  
    foreach (@conf) {
        next if (($enable && $_ =~ /^\#/) 
	  || (!$enable && $_ !~ /^\#/));
	push @dump, $_;    
    }
    
    return \@dump;   
}

sub _filter_conf {
    my $conf = $_[0];
    
    my @tmp;
    foreach (@$conf) {
        push @tmp, $_
	  if /(?:stream|dgram|raw|rdm|seqpacket)/;
    }
    @$conf = @tmp; 
}

sub _split_serv {
    my ($serv, $line) = @_;
    
    @$serv = split /\s.*?/, $$line;
    splice @$serv,1,1 if $$serv[1] !~ /\w/;
    
    ($$serv[0]) = $$serv[0] =~ /.*:(.*)/ 
      if $$serv[0] =~ /:/;
    $$serv[0] = substr $$serv[0], 1, length $$serv[0] 
      if $$serv[0]=~ /^\#/; 
}

1;
__END__

=head1 NAME

Net::Inetd - an interface to inetd.conf.

=head1 SYNOPSIS

 use Net::Inetd;

 $Inetd = Net::Inetd->new;                      # constructor

 if ($Inetd->is_enabled (telnet => 'tcp')) {    # disable telnet
     $Inetd->disable (telnet => 'tcp');
 }

 if (!$Inetd->is_enabled (ftp => 'tcp')) {      # enable ftp
     $Inetd->enable (ftp => 'tcp');
 }

 print $Inetd->{CONF}[6];                       # output a line

 push @{$Inetd->{CONF}}, $service;              # add a new line

 pop @{$Inetd->{CONF}};                         # NOT recommended.

 foreach (@{$Inetd->dump_enabled}) {            # output enabled services
     print "$_\n";
 }

=head1 DESCRIPTION

C<Net::Inetd> is an interface to inetd's configuration file inetd.conf;
it allows checking and setting the enabled/disabled state of a service.
The configuration is tied as class data using C<Tie::File>.

=head1 CONSTRUCTOR

=head2 new

 $Inetd = Net::Inetd->new ('./inetd.conf');

Omitting the path to inetd.conf, will cause the default
F</etc/inetd.conf> to be used.

=head1 METHODS

=head2 is_enabled

Checks whether a service is enlisted as enabled.

 $Inetd->is_enabled ($service => $protocol);

Returns 1 if the service is enlisted as enabled, 0 if 
enlisted as disabled, undef if the service does not exist. 

=head2 enable

Enables a service.

 $Inetd->enable ($service => $protocol);

Returns 1 if the service has been enabled, 
0 if no action has been taken.

=head2 disable

Disables a service.

 $Inetd->disable ($service => $protocol);

Returns 1 if the service has been disabled, 
0 if no action has been taken.

=head2 dump_enabled

Dumps the enabled services.

 $dumpref = $Inetd->dump_enabled;

Returns an arrayref that consists of inetd.conf
lines which contain enabled services.

=head2 dump_disabled

Dumps the disabled services.

 $dumpref = $Inetd->dump_disabled;

Returns an arrayref that consists of inetd.conf
lines which contain disabled services.

=head1 CLASS DATA

The inetd.conf will be tied to the object as array and may be
accessed by @{$Inetd->{CONF}}; $Inetd->{CONF}[6] for the 7th line.

=head1 SEE ALSO

L<Tie::File>.

=cut
