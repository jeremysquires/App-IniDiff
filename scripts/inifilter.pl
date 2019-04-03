#!perl
#
#    inifilter - make changes to a dos .ini file patch (regutils package)
#    Copyright (C) 1998 Memorial University of Newfoundland
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

#
# Script to make modifications to a dos/window ini file - the modified
# file is sent to standard output.  Modifications are read from one or more
# `filter' files.
#
# (pod at end)
#

use strict;
use Getopt::Std;

# BEGIN { push(@INC, 'lib'); }
use App::IniDiff::IniFile;

my $prog = $0;
$prog =~ s:.*\/::;

my $Usage = "Usage: $prog [-f file] [-V] [-e] [-p] filter-file [filter-file ...]
	-f file	Read from file (defaults to stdin)
	-V	Print version number and exit.
	-e  Exports the filter results to a text format (debug purposes)
	-p  Preserves the order of Ordered Field names (such as mod_1, mod_2, etc.)
    Reads patterns from filter-file(s), then filters keys matching those
    patterns from the specified ini file or inidiff output.
";

# add support for --help and --version
$Getopt::Std::STANDARD_HELP_VERSION = "true";
my $VERSION = '0.15';
sub VERSION_MESSAGE {
    print "$prog: version 0.15\n";
}
sub HELP_MESSAGE {
    print STDERR $Usage;
}

my %opt;
if (!&getopts('f:Vep', \%opt)) {
    print STDERR $Usage;
    exit 1;
}
if (defined $opt{'V'}) {
    print "$prog: version 0.15\n";
    exit 0;
}
my $inFile = defined $opt{'f'} ? $opt{'f'} : undef;

if (@ARGV == 0) {
    print STDERR "$prog: no filter-pattern files specified on command line\n";
    die $Usage;
}

my $filter = new IniFile::Filter;

# setPreserveOrderedFields in the filter instance
if (defined $opt{'p'}) {
    $filter->setPreserveOrderedFields(1);
}

my $if;
foreach $if (@ARGV) {
    if (!$filter->readConf($if)) {
        die "$prog: $IniFile::Filter::errorString\n";
    }

    # export the filters to STDOUT
    if (defined $opt{'e'}) {
        $filter->export();
    }
}

# if we have been asked to export the filter, stop
if (defined $opt{'e'}) {
    exit 0;
}

my $in;
if (defined $inFile) {
    $in = new IO::File($inFile, 'r');
    if (!defined $in) {
        die "$prog: can't open $inFile - $!\n";
    }
}
else {
    $inFile = 'stdin';
    $in     = new IO::Handle;
    if (!$in->fdopen('STDIN', 'r')) {
        die "$prog: can't dup STDIN - $!\n";
    }
}

my $ini = new IniFile($in, 1);
if (!defined $ini) {
    die "$prog: $IniFile::errorString\n";
}

if (!$filter->filter($ini)) {
    die "$prog: error filtering key $inFile: $IniFile::Filter::errorString\n";
}

my $out = new IO::Handle;
if (!$out->fdopen('STDOUT', 'w')) {
    die "$prog: couldn't dup stdout - $!\n";
}
$ini->write($out);

exit(0);

__END__

=head1 NAME

inifilter - filter a dos/windows C<.ini> file by making substitutions and deletions to keys and entries

=head1 SYNOPSYS

B<inifilter> [B<-f> I<inifile>] [B<-V>] I<filter-file> ...

=head1 DESCRIPTION

B<inifilter> is used to modify a dos/windows ini file (or a ini file
patch) by applying to it the substitutions and deletions specified
in one or more I<filter file>s.
Such filtering is useful when one needs to do
common transformations (such as changing where the windows system directory is,
I<etc.>)
to a number of ini files.
It is also useful for filtering out common ignorable changes
from a ini diff, so only important changes remain.

=head1 Filter File Format

B<Terminology NOTE>: The following naming convention is used here:
	
	[key pattern] 
	entry line : name=value

This corresponds to the INI File Format described in the other tools:

	[key] field=value

Whereas in other documentation of INI files the naming convention is:

	[section] key=value

The  filter files that control what B<inifilter> does
consist of a number of ini key patterns (enclosed in brackets).
Each key pattern contains lines indicating which entries in matching
keys are to be modified (entries can be matched based on their name or
their value).
Finally, actions can be specified for each matching entry: an entry's
name or value can be changed or it may be deleted entirely.
Key patterns and entry name or value patterns are specified as case insensitive
B<perl> regular expressions, while name and value changes are
specified B<perl> substitution commands.

Comments are indicated by lines beginning with a # character (a # in
the middle of a line does not introduce a comment).

The following example demonstrates the syntax of filter files:

    # Read contents of another filter file:
    include "anotherFile"

    # Check for matching entries in keys starting with 'option'
    [option*]
	# Change C:\PROGRA~1\ to F:\Program files\ in matching value entries
	value .*C:\\\\PROGRA~1\\\\.*
	    subst value s/C:\\\\PROGRA~1\\\\/F:\\\\Program Files\\\\/gi
	# Do the same for entry names
	name .*C:\\\\PROGRA~1\\\\.*
	    subst name s/C:\\\\PROGRA~1\\\\/F:\\\\Program Files\\\\/gi

    # Delete any entries under the Explorer key, and delete the key section
    # (- at end of line means delete any keys matching the pattern)
    [Explorer]-

    # Delete a particular entry by name
    [UuidPersistentData]
    name LastTimeAllocated
	delete 

    # Change both the name and value of some key
    [foo]
    name something
	subst name s/X/Y/gi
	subst value s/A/B/gi

Some things to note about these files: you need lots of backslashes
in the key names (since backslash is used as a path separator,
and since it is special to perl); 
The key, name and value patterns are always anchored, so don't
forget to put an explicit C<.*> in front of or after patterns where you want
a substring match.

The C<include> command is used to read filter commands from another file.
The file is first looked for relative to the same directory as the file
that included it, then in the process's current directory.

=head1 OPTIONS

=over 4

=item B<-f> I<inifile>

Read the specified ini file instead of from standard input.

=item B<-V>

Prints the version number - the program then exits
immediately.

=back

=head1 SEE ALSO

L<inidiff>, L<iniedit>.

=head1 AUTHOR

Michael Rendell, Memorial University of Newfoundland (michael@cs.mun.ca).
