#!/usr/bin/perl

use strict;
use warnings;

use Net::Inetd;

my $Inetd = Net::Inetd->new('./inetd.conf');

$, = "\n";
print @{$Inetd->dump_enabled},"\n";
print @{$Inetd->dump_disabled},"\n";
