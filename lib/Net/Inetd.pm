package Net::Inetd;

$VERSION = '0.15';

use strict;
use Net::Inetd::Entity;

sub new {
    my($self, $conf) = @_;      
    return bless Net::Inetd::Entity::_new($conf), ref $self || $self;
}

sub is_enabled    { &Net::Inetd::Entity::_is_enabled }
sub enable        { &Net::Inetd::Entity::_set }
sub disable       { &Net::Inetd::Entity::_set }
sub dump_enabled  { &Net::Inetd::Entity::_dump }
sub dump_disabled { &Net::Inetd::Entity::_dump }

sub DESTROY       { &Net::Inetd::Entity::_destroy }

1;
__END__

=head1 NAME

Net::Inetd - An interface to inetd.conf

=head1 SYNOPSIS

 use Net::Inetd;

 $Inetd = Net::Inetd->new;                      

 if ($Inetd->is_enabled(telnet => 'tcp')) {    
     $Inetd->disable(telnet => 'tcp');
 }

 print $Inetd->{CONF}[6];                                               

 $, = "\n";
 print @{$Inetd->dump_enabled};            

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

The inetd.conf configuration is tied as instance data;
it may be accessed by @{$Inetd->{CONF}}.

=head1 SEE ALSO

L<Tie::File>, inetd(8)

=cut
