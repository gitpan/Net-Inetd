use ExtUtils::MakeMaker;

WriteMakefile(
    DISTNAME     => 'Net-Inetd',
    NAME         => 'Net::Inetd',
    VERSION_FROM => 'lib/Net/Inetd.pm',
    PREREQ_PM    => { Tie::File => 0 },
    'dist'       => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    ($] >= 5.005 ? 
       (ABSTRACT_FROM => 'lib/Net/Inetd.pm',
        AUTHOR        => 'Steven Schubiger') : ()),
);
