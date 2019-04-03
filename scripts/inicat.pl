#!perl
#
#    inicat - cat dos/windows .ini files to standard output (regutils package)
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
# Program to test the ini reading stuff...
#
# (pod at end)
#

use strict;
use Getopt::Std;
use IO::File;
use Cwd;

# BEGIN { push(@INC, 'D:\Code\inidiffutils-code\tries\perl-App-IniDiff\lib'); }
use App::IniDiff::IniFile;

my $prog = $0;
$prog =~ s:.*\/::;

my $Usage = "Usage: $prog [-V] [-o outfile] [file ...]
	-V	Print version number and exit.
	-o	outfile - print output to outfile
	file	Read from file (defaults to stdin)
    Reads the contents of the specified .ini files (or standard input
    if no files are given), and writes them to standard output.
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
if (!&getopts('o:V', \%opt)) {
    print STDERR $Usage;
    exit 1;
}
my $outFile = defined $opt{'o'} ? $opt{'o'} : '-';
if (defined $opt{'V'}) {
    print "$prog: version 0.15\n";
    exit 0;
}

if (@ARGV == 0) {
    print STDERR "$prog: no files to cat\n";
    die $Usage;
}

my $out;
if ($outFile eq '-') {
    $out = new IO::Handle;
    if (!$out->fdopen("STDOUT", "w")) {
        die "$prog: can't fdopen STDOUT - $!\n";
    }
}
else {
    $out = new IO::File $outFile, 'w';
    if (!defined $out) {
        die "$prog: couldn't open $outFile for writing - $!\n";
    }
}

my $ok = 1;
my $file;
foreach $file (@ARGV) {
    my $in = new IO::File $file, "r";
    if (!defined $in) {
        print STDERR "$prog: can't open $file - $!\n";
        $ok = 0;
        next;
    }
    my $ini = new App::IniDiff::IniFile($in);
    $in->close;
    if (!defined $ini) {
        print STDERR "$prog: $file:${IniFile::errorString}\n";
        $ok = 0;
        next;
    }
    $ini->write($out);
}

exit $ok ? 0 : 1;

__END__

=head1 NAME

inicat - cat dos/windows C<.ini> files to standard output

=head1 SYNOPSYS

B<inicat> [B<-V>] [file ...]

=head1 DESCRIPTION

B<inicat> reads, and then writes to standard output, dos or windows
C<.ini> files.
If no files are specified, standard input is read.
If multiple files are specified, each file is read and processed
separately - they keys in the files are not merged together.

Any comments in the C<.ini> files will be discarded (as will extraneous
white space).

The B<-V> option prints the version number - the program then exits
immediately.

This program is exists to allow simple testing of the C<IniFile>
perl module.

=head1 SEE ALSO

L<inidiff>, L<iniedit>.

=head1 AUTHOR

Michael Rendell, Memorial University of Newfoundland (michael@cs.mun.ca).
