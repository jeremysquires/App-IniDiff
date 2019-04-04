# App-IniDiff

App-IniDiff is a package of Perl utilities that compares,
patches and filters INI files.

It works much as the GNU diffutils package works, but taking 
the INI structure of section, key and values into account.

Originally Developed by Michael Rendell, Memorial University of Newfoundland
as part of the regutils package, for maintaining Win95 diskless workstations,
which is still available here: https://sourceforge.net/projects/regutils/

App-IniDiff can be used to help in managing INI configuration files.
The utilities can be used to apply changes to INIs as needed.
They can also be used to identify and correct similarities and 
differences between configurations. These may be helpful in debug 
situations or when consistency or differences need to be maintained.

The package contains the following programs:

    inicat    - cat ini files to standard output.
    inidiff   - generate the differences between two ini files.
    iniedit   - edit (or patch) a ini file.
    inifilter - filter an ini file by making substitutions and deletions to keys and entries.

## INSTALLATION

To install this module, run the following commands:
(on Windows, use Strawberry gmake instead of cygwin make)

	perl Makefile.PL
	make
	make test
	make install

Alternatively use the CPAN.pm module:

    # perl -MCPAN -e 'install App::IniDiff'

Or the newer CPANPLUS.pm module

    # perl -MCPANPLUS -e 'install App::IniDiff'

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc App::IniDiff::IniFile
    perldoc inicat
    perldoc inidiff
    perldoc iniedit
    perldoc inifilter

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-IniDiff

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/App-IniDiff

    CPAN Ratings
        https://cpanratings.perl.org/d/App-IniDiff

    Search CPAN
        https://metacpan.org/release/App-IniDiff


## LICENSE AND COPYRIGHT

This software is Copyright (C) 1998 Memorial University of Newfoundland

This is free software, licensed under:

  The GNU General Public License, Version 3, 29 June 2007

