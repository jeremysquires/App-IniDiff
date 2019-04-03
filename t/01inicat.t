use Test::Cmd;
use Test2::Bundle::More;
use Cwd;

plan tests => 5;

my $dir = getcwd;

my $test = Test::Cmd->new();

my $resultsDir = $dir.'/t/results';
if (!-d $resultsDir) {
  # create
  mkdir $resultsDir;
} else {
  # remove files
  unlink glob $resultsDir."/*.*"
}
my $archiveDir =  $dir.'/t/archive';
my $dataDir =  $dir.'/t/data';

$test->run(
  interpreter => 'perl',
  prog => 'scripts/inicat.pl '.$dataDir.'/sample.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_cat_sample.ini');
is( $test->stdout, $archive, 'inicat: write to stdout' );

$test->run(
  prog => 'scripts/inicat.pl',
  interpreter => 'perl',
  args => '-o '.$resultsDir.'/result_cat_sample.ini '.$dataDir.'/sample.ini',
);
$test->read(\$result, $resultsDir.'/result_cat_sample.ini');
is( $result, $archive, 'inicat: write to output file');
is( $? >> 8,       1,       'exit status' );

$test->run(
  prog => 'scripts/inicat.pl',
  interpreter => 'perl',
  args => '-o '.$resultsDir.'/result_cat_sample_duplicate_section.ini '.$dataDir.'/sample_duplicate_section.ini',
);
$test->write($resultsDir.'/result_cat_sample_duplicate_section.ini', $test->stderr);
like($test->stderr, qr/duplicate key: onekey/, 'inicat: duplicate section');
is( $? >> 8,       0,       'exit status' );
