package Net::Inetd;

use 5.006;
use base qw(Exporter);
use strict;
use warnings;

our $VERSION = '0.08';

use Carp 'croak';
use Fcntl 'O_RDWR';
use Tie::File;

our $INETD_CONF = '/etc/inetd.conf';

sub new {
    my($pkg, $conf) = @_;    
    my $class = ref $pkg || $pkg;
    return bless _data($conf), $class; 
}

sub is_enabled {
    my($o, $serv, $prot) = @_;
    croak 'usage: $Inetd->is_enabled($service => $protocol)'
      unless $serv && $prot;
    
    return defined $o->{ENABLED}{$serv}{$prot}
      ? $o->{ENABLED}{$serv}{$prot}
      : undef;
}

sub enable  {  
    my($o, $serv, $prot) = @_;
    croak 'usage: $Inetd->enable($service => $protocol)'
      unless $serv && $prot;
      
    for (@{$o->{CONF}}) {
        if (/$serv.*$prot\b/ && /^\#/) {
	    $_ = substr $_, 1, length;
	    $o->{ENABLED}{$serv}{$prot} = 1;
	    return 1;
        }
    }
    return 0;    
}

sub disable {
    my($o, $serv, $prot) = @_;
    croak 'usage: $Inetd->disable($service => $protocol)'
      unless $serv && $prot;
      
    for (@{$o->{CONF}}) {
        if (/$serv.*$prot\b/ && !/^\#/) {
	    $_ = '#'.$_;
	    $o->{ENABLED}{$serv}{$prot} = 0;
            return 1;
	}  
    }
    return 0;  
}

sub dump_enabled  {
    my $o = shift;
    croak 'usage: $Inetd->dump_enabled'
      unless ref $o;
       
    my @conf = @{$o->{CONF}}; _filter_conf(\@conf);
    for (my $i = 0; $i < @conf;) { 
        $conf[$i] =~ /^\#/
	  ? splice @conf, $i, 1 
	  : $i++;
    }  
    return \@conf;   
}

sub dump_disabled {
    my $o = shift;
    croak 'usage: $Inetd->dump_disabled'
      unless ref $o;
       
    my @conf = @{$o->{CONF}}; _filter_conf(\@conf);
    for (my $i = 0; $i < @conf;) { 
        $conf[$i] !~ /^\#/
	  ? splice @conf, $i, 1 
	  : $i++;
    }  
    return \@conf;     
}

sub _data {
    my $conf_file = shift || $INETD_CONF;      
    my %data;    
    _tie_conf(\@{$data{CONF}}, $conf_file);    
    %{$data{ENABLED}} = %{_parse_enabled(@{$data{CONF}})};    
    return \%data;
} 

sub _tie_conf {
    my($conf, $file) = @_;
    my $tied = tie @$conf, 'Tie::File', $file, mode => O_RDWR
      or croak "Couldn't tie $file: $!";
    $tied->flock;
}   

sub _parse_enabled {
    my %is_enabled;         
    _filter_conf(\@_);
    for (@_) {
	my($serv, $prot) = _split_serv_prot($_);
	$is_enabled{$serv}{$prot} = !/^\#/ ? 1 : 0;
    }    
    return \%is_enabled;
} 

sub _filter_conf {
    my $conf = shift;    
    for (my $i = 0; $i < @$conf;) { 
        $$conf[$i] !~ /(?:stream|dgram|raw|rdm|seqpacket)/
	  ? splice @$conf, $i, 1 
	  : $i++;
    }
}

sub _split_serv_prot {
    my($line) = shift; 
    my($serv, $prot) = (split, $line)[0,2];
    ($serv) = $serv =~ /.*:(.*)/ 
      if $serv =~ /:/;
    $serv = substr $serv, 1, length $serv 
      if $serv =~ /^\#/; 
    return($serv, $prot);
}

1;
__END__

=head1 NAME

Net::Inetd - an interface to inetd.conf.

=head1 SYNOPSIS

 use Net::Inetd;

 $Inetd = Net::Inetd->new;                      # constructor

 if ($Inetd->is_enabled(telnet => 'tcp')) {     # disable telnet
     $Inetd->disable(telnet => 'tcp');
 }

 if (!$Inetd->is_enabled(ftp => 'tcp')) {       # enable ftp
     $Inetd->enable(ftp => 'tcp');
 }

 print $Inetd->{CONF}[6];                       # output a line

 push @{$Inetd->{CONF}}, $service;              # add a new line

 pop @{$Inetd->{CONF}};                         # NOT recommended

 $, = "\n";
 print @{$Inetd->dump_enabled},"\n";            # output enabled services

=head1 DESCRIPTION

Net::Inetd is an interface to inetd's configuration file F<inetd.conf>;
it simplifies checking and setting the enabled / disabled state of services 
and dumping them by their state.

=head1 METHODS

=head2 new

Object constructor.

 $Inetd = Net::Inetd->new('./inetd.conf');

Omitting the path to inetd.conf, will cause the default
F</etc/inetd.conf> to be used.

=head2 is_enabled

Checks whether a service is enlisted as enabled.

 $Inetd->is_enabled($service => $protocol);

Returns 1 if the service is enlisted as enabled, 0 if 
enlisted as disabled, undef if the service does not exist. 

=head2 enable

Enables a service.

 $Inetd->enable($service => $protocol);

Returns 1 if the service has been enabled, 
0 if no action has been taken.

=head2 disable

Disables a service.

 $Inetd->disable($service => $protocol);

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

=head1 INSTANCE DATA

The inetd.conf configuration is tied as instance data
by using Tie::File.

It may be accessed by @{$Inetd->{CONF}}.

=head1 SEE ALSO

L<Tie::File>, L<perlfunc/tie>.

=cut
