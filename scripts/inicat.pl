#!perl
#
#    inicat - cat .ini files to standard output
#

use strict;
use Getopt::Std;
use IO::File;
use Cwd;
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
my $VERSION = '0.16';
sub VERSION_MESSAGE {
    print "$prog: version $VERSION\n";
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
    print "$prog: version $VERSION\n";
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

inicat - cat C<.ini> files to standard output

=head1 SYNOPSYS

B<inicat> [B<-V>] [B<-o> outfile] [file ...]

=head1 DESCRIPTION

B<inicat> reads and then writes C<.ini> files. If no output file is
specified using the B<-o> option, then it will write to stdout.

If multiple files are specified, each file is read and processed
separately - the keys in the files are not merged together.

Comments in the C<.ini> files will NOT be discarded.
Extraneous white space, however, will be discarded.

=head1 OPTIONS

=over 4

=item B<-o> I<file>

Allows an output file to be specified.

=item B<-V>

Prints the version number - the program then exits immediately.

=back

=head1 SEE ALSO

L<inidiff>, L<iniedit>, L<inifilter>.

=head1 AUTHOR

=item Michael Rendell, Memorial University of Newfoundland
 
=head1 MAINTAINERS
 
=item Jeremy Squires C<< <j.squires at computer.org> >>

=head1 ACKNOWLEDGEMENTS

Michael Rendell, Memorial University of Newfoundland
produced the first version of the Regutils package from which
this package was derived. It is still available from:

    L<https://sourceforge.net/projects/regutils/>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 1998 Memorial University of Newfoundland

This is free software, licensed under:

The GNU General Public License, Version 3, July 2007

See F<LICENSE>

