use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Net::Inetd',
    VERSION_FROM => 'lib/Net/Inetd.pm',
    PREREQ_PM    => { Tie::File => 0 },
    ($] >= 5.005 
      ? (ABSTRACT_FROM => 'lib/Net/Inetd.pm') : ()
    ),
);
