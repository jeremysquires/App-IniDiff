#!perl
#
#    iniedit - edit (or patch) an .ini file
#

use strict;
use Getopt::Std;
use IO::File;
use IO::Handle;

use App::IniDiff::IniFile;

my $prog = $0;
$prog =~ s:.*\/::;

my $Usage = "Usage: $prog [-V] [-o outfile] -i patchfile -f inoutfile
	-f file	File to patch; if -o not given, file is overwritten with
		new file; \"-\" means read (write) from stdin (stdout).
	-i file	File containing patches; \"-\" means read from stdin.
	-o file	File to save result to (instead of -f file); \"-\" means write
		to stdout.
	-V	Print version number and exit.
    Reads .ini file patches and applies them to the specified file.
";

# add support for --help and --version
$Getopt::Std::STANDARD_HELP_VERSION = "true";
my $VERSION = '0.15';
sub VERSION_MESSAGE {
    print "$prog: version $VERSION\n";
}
sub HELP_MESSAGE {
    print STDERR $Usage;
}

my %opt;
if (!getopts('f:i:o:V', \%opt)) {
    print STDERR $Usage;
    exit 1;
}
if (defined $opt{'V'}) {
    print "$prog: version $VERSION\n";
    exit 0;
}

if (!defined $opt{'f'} || !defined $opt{'i'}) {
    die "$prog: -f and -i options are required\n$Usage";
}

my $stdinUsed = 0;

my $inFile    = $opt{'f'};
my $patchFile = $opt{'i'};
my $outFile   = defined $opt{'o'} ? $opt{'o'} : $inFile;
my $saveOrig  = !defined $opt{'o'} && $inFile ne '-';

if (@ARGV != 0) {
    print STDERR "$prog: don't know what to do with command line arguments\n";
    die $Usage;
}

my $fIn;
if ($inFile eq '-') {
    if ($stdinUsed) {
        die "$prog: stdin (-) used for multiple options\n";
    }
    $stdinUsed = 1;
    $fIn       = new IO::Handle;
    if (!$fIn->fdopen('STDIN', 'r')) {
        die "$prog: can't fdopen STDIN - $!\n";
    }
    $inFile = 'stdin';
}
else {
    $fIn = new IO::File $inFile, 'r';
    if (!defined $fIn) {
        die "$prog: can't open $inFile - $!\n";
    }
}
my $pIn;
if ($patchFile eq '-') {
    if ($stdinUsed) {
        die "$prog: stdin (-) used for multiple options\n";
    }
    $stdinUsed = 1;
    $patchFile = 'stdin';
    $pIn       = new IO::Handle;
    if (!$pIn->fdopen('STDIN', 'r')) {
        die "$prog: can't fdopen STDIN - $!\n";
    }
}
else {
    $pIn = new IO::File $patchFile, 'r';
    if (!defined $pIn) {
        die "$prog: can't open $patchFile - $!\n";
    }
}

my $fIni = new App::IniDiff::IniFile($fIn, 0);
die "$prog: Line", __LINE__, ": $inFile:$App::IniDiff::IniFile::errorString\n"
  if (!defined $fIni);
my $pIni = new App::IniDiff::IniFile($pIn, 1);
die "$prog: Line ", __LINE__, ": $patchFile:$App::IniDiff::IniFile::errorString\n"
  if (!defined $pIni);

# Apply the patch...
my $pKey;
my $lastOrderId = -1;
foreach $pKey (@{$pIni->keys}) {
    if ($pKey->deleted) {
        $fIni->removeKey($pKey->name);
    }
    else {
        my $fKey = $fIni->findKey($pKey->name);

        $lastOrderId = $fKey->orderId if (defined $fKey);
        my $field;
        foreach $field (@{$pKey->fields}) {
            if ($field->deleted) {
                $fKey->removeField($field->name) if defined $fKey;
            }
            else {
                if (!defined $fKey) {
                    $fKey =
                      $fIni->addKey(new App::IniDiff::IniFile::Key($pKey->name, 0, undef));

                    # Attempt to preserve order of keys in file
                    $fKey->orderId($lastOrderId += 0.0000001);
                }

                # Replaces existing field if there is one...
                $fKey->addField(
                    new App::IniDiff::IniFile::Field($field->name, $field->value, 0, undef));
            }
        }
    }
}

if ($outFile eq '-') {
    my $out = new IO::Handle;
    if (!$out->fdopen('STDOUT', 'w')) {
        die "$prog: can't fdopen STDOUT - $!\n";
    }
    $fIni->write($out);
    if (!$out->close) {
        print STDERR "$prog: error writing to stdout - $!\n";
        exit(1);
    }
}
elsif (!$saveOrig) {
    my $out = new IO::File $outFile, 'w';
    if (!defined $out) {
        die "$prog: couldn't open $outFile for writing - $!\n";
    }
    $fIni->write($out);
    if (!$out->close) {
        die "$prog: error writing to $outFile - $!\n";
    }
}
else {
    my $tmp = "$outFile.$$";
    my $out = new IO::File $tmp, 'w';
    if (!defined $out) {
        die "$prog: couldn't open $tmp for writing - $!\n";
    }
    $fIni->write($out);
    if (!$out->close) {
        print STDERR "$prog: error writing to $tmp - $!\n";
        unlink($tmp);
        exit(1);
    }
    if (!rename($outFile, "$outFile.orig")) {
        print STDERR "$prog: couldn't rename $outFile to $outFile.orig - $!\n";
        unlink($tmp);
        exit(1);
    }
    if (!rename($tmp, $outFile)) {
        print STDERR
"$prog: couldn't rename $tmp to $outFile - $! (will attemp to restore orig)\n";
        rename("$outFile.orig", $outFile);
        exit(1);
    }
}

exit(0);

__END__

=head1 NAME

iniedit - edit (or patch) a C<.ini> file.

=head1 SYNOPSYS

B<iniedit> [B<-V>] B<-f> I<file> B<-i> I<file> [B<-o> I<file>]

=head1 DESCRIPTION

B<iniedit> edits or patches the C<.ini> file specified
by the B<-f> option using the patch in the file indicated by the B<-i>
option.

If the B<-o> option is used, the result is written the specified file, 
otherwise the original file is over-written with the result.

The patch file basically lists the keys and fields to add, remove
or change - it is typically the result of running B<inidiff>.

=head1 OPTIONS

=over 4

=item B<-f> I<file>

Specifies the C<.ini> file that is to be patched. A "-" means
read the file from standard input.

=item B<-i> I<file>

Specifies the file containing the C<.ini> patch (usually generated by
B<inidiff>).  A "-" means the patch should be read from standard input.

=item B<-o> I<file>

Specifies the file where the result of the edit should be written.
A "-" means the patch should be written to standard output.
If this option is not specified, the original file is overwritten
(if the original file was read from standard input, the result is
written to standard output).

=item B<-V>

Prints the version number - the program then exits immediately.

=back

=head1 FILE FORMATS

=head2 INI File Format

Disclaimer: this is my understanding of C<.ini>, gained from looking at
a few files, and may be incorrect.

B<Terminology NOTE>: The following naming convention is used here:
	
	[key] field=value

Whereas in other documentation of INI files the naming convention is:

	[section] key=value

Your typical C<.ini> file looks like this:

    ; A comment
    [firstkey]
    field=value		; More comments
    foo=bar
    
    [Another key name]
    A field=The value
    moreFields="values and ; stuff"

and so on.

In general, C<.ini> files consist of a number of keys, each
key has a number of fields, and each field has a value.  Key names are
inclosed in brackets and appear on a line by themselves - they
may contain pretty much any character except brackets.
Keys can appear in any order in the file, but no two keys should
have the same name.

Field names and their values are separated by an equals.
Field names within a key are usually, but not always, unique.
Double quotes are (somewhat) special in field names and values: they can
be used to quote characters that would otherwise not be allowed
(I<e.g.>, equals and semi-colon).

Quotes should be balanced (though I've seen some C<.ini> files with
a single quote in the value - check your HP printer C<.ini> files).

Blank lines are completely ignored, though they are
typically used to separate keys.

Comments in C<.ini> files begin with a semi-colon and go the the end of
the line.

Comments may be on lines by themselves or they may appear after a key name
or after a I<field>C<=>I<value>.

A semi-colon inside the brackets of a key name is not considered a comment.

=head2 Patch File Format

An C<.ini> patch file is mostly the same as an C<.ini> file with the
following differences:

=over 4

=item *

A minus after a key name (outside the brackets) indicates the key is to be
deleted.

=item *

A minus after a field name indicates the field is to be deleted (the field
has no equals and no value).

=item *

Key names can be repeated - the changes contained in the keys are combined;
the last change mentioned wins.

=back

=head1 SEE ALSO

L<inidiff>, L<inicat>, L<inifilter>.

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

