#!perl
#
#    inidiff - generate diffs between two .ini files
#

use strict;
use Getopt::Std;
use IO::File;
use IO::Handle;

use App::IniDiff::IniFile;

my $prog = $0;
$prog =~ s:.*\/::;

my $Usage = "Usage: $prog [-q] [-V] [-i] [-M] [-c] [-o outfile] file1 file2
    -q	don't generate comments indicating new/old values
    -V	Print version number and exit.
    -i	ignore the case of comparisons.
    -M	add ^M to output to support old (pre-NT) Windows/DOS systems
    -c	strip trailing inline comments after semicolon
    -o  file File to save result to (instead of -f file); \"-\" means write
        to stdout.
    Compare two .ini files and generate a differences file.
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
if (!&getopts('o:qViMc', \%opt)) {
    print STDERR $Usage;
    exit 1;
}
my $outFile = defined $opt{'o'} ? $opt{'o'} : '-';
if (defined $opt{'V'}) {
    print "$prog: version $VERSION\n";
    exit 0;
}
my $genComments   = defined $opt{'q'} ? 0 : 1;
my $ignoreCase    = defined $opt{'i'} ? 1 : 0;
my $addM          = defined $opt{'M'} ? 1 : 0;
my $stripComments = defined $opt{'c'} ? 1 : 0;

if (@ARGV < 2) {
    print STDERR "$prog: wrong number of arguments\n";
    die $Usage;
}

my $file1 = $ARGV[0];
my $file2 = $ARGV[1];

if ($file1 eq '-' && $file2 eq '-') {
    die "$prog: both files can't be from stdin!\n";
}

my $f1 = new IO::File $file1, "r";
if (!defined $f1) {
    die "$prog: can't open $file1 - $!\n";
}

my $f2 = new IO::File $file2, "r";
if (!defined $f2) {
    die "$prog: can't open $file2 - $!\n";
}

my $f1Ini = new App::IniDiff::IniFile($f1, 0, $addM, $stripComments);
die "$prog: $file1:$App::IniDiff::IniFile::errorString\n" if (!defined $f1Ini);
my $f2Ini = new App::IniDiff::IniFile($f2, 0, $addM, $stripComments);
die "$prog: $file1:$App::IniDiff::IniFile::errorString\n" if (!defined $f2Ini);

#
# Generate the diffs...
#

# using default () would not allow ^M and stripcomments to be passed in
my $dIni = new App::IniDiff::IniFile("", 0, $addM, $stripComments);

my %doneKeys = ();
my $key1;
foreach $key1 (@{$f1Ini->keys}) {
    my $key2       = $f2Ini->findKey($key1->name);
    my %doneFields = ();
    if (defined $key2) {
        my $keyd = undef;
        $doneKeys{$key2->name} = $key1->orderId;
        my $field1;
        my $field2;
        foreach $field1 (@{$key1->fields}) {
            # returns canonicalized (lc) name
            $field2 = $key2->findField($field1->name); 
            if (defined $field2) {
                $doneFields{$field2->name} = 1;

                # if case should be ignored (-i opt) and 
                # they are equivalent otherwise
                # then do not find them unequal
                if (($field1->value ne $field2->value) &&
                    !(($ignoreCase) and 
                      (lc($field1->value) eq lc($field2->value))))
                {
                    $keyd =
                      $dIni->addKey(new App::IniDiff::IniFile::Key($key2->name, 0, undef))
                      if !defined $keyd;

                    # Changed
                    $keyd->addField(
                        new App::IniDiff::IniFile::Field(
                            $field2->name, $field2->value, 0,
                            &comment("Old value: " . $field1->value)));
                }
            }
            else {
                $keyd = $dIni->addKey(new App::IniDiff::IniFile::Key($key2->name, 0, undef))
                  if !defined $keyd;

                # Old - not in new version
                $keyd->addField(
                    new App::IniDiff::IniFile::Field(
                        $field1->name, $field1->value, 1,
                        &comment("Old value: " . $field1->value)));
            }
        }
        foreach $field2 (@{$key2->fields}) {
            if (!exists $doneFields{$field2->name}) {
                $keyd = $dIni->addKey(new App::IniDiff::IniFile::Key($key2->name, 0, undef))
                  if !defined $keyd;

                # New addition
                $keyd->addField(
                    new App::IniDiff::IniFile::Field(
                        $field2->name, $field2->value, 0, &comment('New')));
            }
        }
    }
    else {

        # Whole key is deleted
        $dIni->addKey(new App::IniDiff::IniFile::Key($key1->name, 1, undef));
    }
}

my $key2;
my $lastOrderId = -1;
foreach $key2 (@{$f2Ini->keys}) {
    if (!exists $doneKeys{$key2->name}) {

        # New key (and contents)
        my $keyd =
          $dIni->addKey(new App::IniDiff::IniFile::Key($key2->name, 0, &comment('New')));

        # Attempt to the preserve order in the file...
        $keyd->orderId($lastOrderId += 0.000001);
        my $field2;
        foreach $field2 (@{$key2->fields}) {
            $keyd->addField(
                new App::IniDiff::IniFile::Field($field2->name, $field2->value, 0, undef));
        }
    }
    else {
        $lastOrderId = $doneKeys{$key2->name};
    }
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

$dIni->write($out);
if (!$out->close) {
    die "$prog: error writing to STDOUT - $!\n";
}
exit 0;

sub comment
{
    return $genComments ? $_[0] : undef;
}

__END__

=head1 NAME

inidiff - generate the differences between two C<.ini> files

=head1 SYNOPSYS

B<inidiff> [B<-q>] [B<-V>] [B<-i>] [B<-M>] [B<-c>] [B<-o outfile>] file1 file2

=head1 DESCRIPTION

B<inidiff> reads the two specified C<.ini> files and prints
the differences between the two.

The output is suitable for use with the B<iniedit> program.
Either of file1 or file2 may be "-", indicating standard input
should be read.

The output consists of key names in brackets followed by the 
fields that have been added or changed in that key.

Keys are separated by blank lines.

Deleted keys are indicated by a minus at the end of the line containing
the key name, while deleted fields are indicated by a minus after the field
name (there is no equals or value after the field name).

New keys and fields are preceded by comments indicating they are new.
Changed fields are preceded by comments indicating the previous value
of the field.

All output lines end in a carriage return.

See L<iniedit> for information about the format of C<.ini> files and
C<.ini> patch files.

B<Terminology NOTE>: The following naming convention is used here:
	
	[key] entry=value

Whereas in other documentation of INI files the naming convention is:

	[section] key=value

=head1 OPTIONS

=over 4

=item B<-q>

Suppresses the generation of comments indicating new keys and fields,
and previous values of existing and deleted fields.

=item B<-V>

Prints the version number - the program then exits immediately.

=item B<-i>

Ignores case in values for comparison purposes (always does so for 
key names anyway).

=item B<-M>

Add ^M to output to support old (pre-NT) Windows/DOS systems.

=item B<-c>

Strip trailing inline comments after semicolon.

=item B<-o> I<file>

Allows an output file to be specified. "-" means write to stdout.

=back

=head1 KNOWN BUGS

The only (known) problem with B<inidiff> (and patch files) is that they
don't handle changes to keys which have multiple fields with the same name.
This kind of thing doesn't seem too common, so it hasn't been a problem.

=head1 SEE ALSO

L<inicat>, L<iniedit>, L<inifilter>.

=head1 AUTHOR

    Michael Rendell, Memorial University of Newfoundland

=head1 MAINTAINERS
 
    Jeremy Squires <j.squires at computer.org>

=head1 SOURCE

=over 4

=item * The source for this package is available here:

L<https://github.com/jeremysquires/App-IniDiff>

=back

=head1 ACKNOWLEDGEMENTS

    Michael Rendell, Memorial University of Newfoundland
    produced the first version of the Regutils package from which
    this package was derived.

=over 4

=item * It is still available from:

L<https://sourceforge.net/projects/regutils/>

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-inidiff-inifile at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-IniDiff-IniFile>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::IniDiff::IniFile

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-IniDiff-IniFile>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-IniDiff-IniFile>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-IniDiff-IniFile>

=item * Search CPAN

L<https://metacpan.org/release/App-IniDiff-IniFile>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 1998 Memorial University of Newfoundland

This is free software, licensed under:

The GNU General Public License, Version 3, July 2007

See F<LICENSE>

