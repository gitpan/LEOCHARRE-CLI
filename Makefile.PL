use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'LEOCHARRE::CLI',
	VERSION_FROM => 'lib/LEOCHARRE/CLI.pm',
	PREREQ_PM => {
		'Getopt::Std' => 0,
		'Carp' => 0,
		'YAML' => 0,
	},
	EXE_FILES => ['bin/mkperlbin', 'bin/renamerfpi'],
);
