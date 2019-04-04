use Test::Cmd;
use Test2::Bundle::More;
use Cwd;

plan tests => 3;

my $dir = getcwd;

my $test = Test::Cmd->new();

my $resultsDir = $dir.'/t/results';
if (!-d $resultsDir) {
  # create
  mkdir $resultsDir;
} else {
  # do not remove files - leave them at end of run for archiving
  # unlink glob $resultsDir."/*.*"
}
my $archiveDir =  $dir.'/t/archive';
my $dataDir =  $dir.'/t/data';

$test->read(\$archive, $archiveDir.'/result_filter_sample.ini');

# FAIL: does not find the included file when run here
$test->run(
   prog => 'scripts/inifilter.pl',
   interpreter => 'perl',
   args => '-f '.$dataDir.'/sample.ini '.$dataDir.'/filter.ini',
  # verbose => 1,
);
is( $test->stdout, $archive, 'inifilter: write to stdout' );

$test->run(
  prog => 'scripts/inifilter.pl',
  interpreter => 'perl',
  args => '-f '.$dataDir.'/sample.ini -o '.$resultsDir.'/result_filter_sample.ini '.$dataDir.'/filter.ini',
);
$test->read(\$result, $resultsDir.'/result_filter_sample.ini');
is( $result, $archive, 'inifilter: write to output file');
is( $? >> 8,       0,       'exit status' );

