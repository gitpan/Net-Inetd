package Net::Inetd::Entity;

use strict;
use vars qw($INETD_CONF);
use Fcntl 'O_RDWR';
use Tie::File;

$INETD_CONF = '/etc/inetd.conf';

sub croak {
    my($called, $line_nr) = (caller(2))[1,2];
    die "@_ at $called line $line_nr.\n";
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

sub _is_enabled {
    my($o, $serv, $prot) = @_;
    croak 'usage: $Inetd->is_enabled($service => $protocol)'
      unless $serv && $prot;
    
    return defined $o->{ENABLED}{$serv}{$prot}
      ? $o->{ENABLED}{$serv}{$prot}
      : undef;
}

sub _set {
    my($o, $serv, $prot) = @_;
    my $called = _getcaller();
    croak "usage: \$Inetd->$called(\$service => \$protocol)"
      unless $serv && $prot;
    
    my $enable = 1 if $called eq 'enable';
    my $prechar = $enable ? '#' : '';
    for (@{$o->{CONF}}) {
        if (/^$prechar$serv.*$prot\b/) {
	    $o->{ENABLED}{$serv}{$prot} = $enable ? 1 : 0;
	    $_ = $enable ? substr($_, 1, length) : '#'.$_;
	    return 1;
	}
    }
    return 0;
}

sub _dump {
    my $o = shift;
    my $called = _getcaller('.*_(.*)');
    croak "usage: \$Inetd->dump_$called"
      unless ref $o;
       
    my @conf = @{$o->{CONF}};
    _filter_conf(\@conf, $called eq 'enabled' 
      ? '^[^#]' : '^#');
    return \@conf;     
}

sub _filter_conf {
    my $conf = shift; 
    my @patterns = ('(?:stream|dgram|raw|rdm|seqpacket)', @_);     
    for (my $match, my $i = 0; $i < @$conf; $i++ if $match) {
        for (@patterns) { 
            $match = $$conf[$i] =~ /$_/;
	    splice(@$conf, $i, 1) && last unless $match;
	}
    }
}

sub _split_serv_prot {
    my($line) = shift; 
    my($serv, $prot) = (split, $line)[0,2];
    ($serv) = $serv =~ /.*:(.*)/ 
      if $serv =~ /:/;
    $serv = substr($serv, 1, length $serv) 
      if $serv =~ /^\#/; 
    return($serv, $prot);
}

sub _getcaller {
    my $pattern = shift || '(.*)';
    my ($called) = (caller(2))[3] =~ /.*:$pattern/;
    return $called;
}

1;
