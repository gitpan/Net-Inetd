# $Id: Inetd.pm,v 0.01 2004/01/19 22:39:44 sts Exp $

package Net::Inetd;

use 5.006;
use base qw(Exporter);
use strict;
use warnings;

our $VERSION = '0.01';

use Tie::File;

our $enable;

our ($CONF, 
     $ENABLED, 
     $INETD_CONF
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
      or croak qq~Could not tie $$file: $!~;
}   

sub _parse_enabled {
    my %is_enabled;
    foreach (@_) {
        next if !/(?:stream|dgram|raw|rdm|seqpacket)/;
        my @serv = split /\s.*?/; 
	splice @serv,1,1 if $serv[1] !~ /\w/; 
	
	my ($serv, $prot) = (shift @serv, splice @serv,1,1);
        ($serv) = $serv =~ /.*:(.*)/ if $serv =~ /.*:(.*)/;
	
	if (!/^\#/) { $is_enabled{$serv}{$prot} = 1 }
	else { ($serv) = $serv =~ /.(.*)/; $is_enabled{$serv}{$prot} = 0 }
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
		    $ret_state = 1;
		}
            } 
	    elsif ($o->{$CONF}[$i] !~ /^\#/) {
	        $o->{$CONF}[$i] = '#'.$o->{$CONF}[$i];
		$ret_state = 1;
	    }      
	}    
    } 
     
    return $ret_state;
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
     
 print $Inetd->{CONF}[6];                       # print a line
 
 push @{$Inetd->{CONF}}, $entry;                # add a new entry

 shift @{$Inetd->{CONF}};                       # DANGEROUS.
 
=head1 DESCRIPTION

C<Net::Inetd> is an interface to inetd's configuration file inetd.conf;
it allows checking and setting the enabled/disabled state of a service.
The configuration is tied as class data using C<Tie::File>.

=head1 CONSTRUCTOR

=head2 new

 $Inetd = Net::Inetd->new ('/etc/inetd.conf');
 
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

=head1 CLASS DATA

The inetd.conf will be tied to the object as array and may be
accessed by @{$Inetd->{CONF}}; $Inetd->{CONF}[6] for the 7th line.

=head1 SEE ALSO

L<Tie::File>.

=cut
