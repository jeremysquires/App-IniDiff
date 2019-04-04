use Test::Cmd;
use Test2::Bundle::More;
use Cwd;

plan tests => 15;

my $dir = getcwd;

my $test = Test::Cmd->new();

my $resultsDir = $dir.'/t/results';
if (!-d $resultsDir) {
  # create
  mkdir $resultsDir;
} else {
  # do not remove files :- this test uses the inidiff.t results
  # unlink glob $resultsDir."/*.*"
}
my $archiveDir =  $dir.'/t/archive';
my $dataDir =  $dir.'/t/data';

$test->run(
  interpreter => 'perl',
  prog => 'scripts/inidiff.pl',
  args =>  '-o - '.$dataDir.'/sample.ini '.$dataDir.'/result_cat_sample.ini',
  # verbose => 1,
);
# won't write an empty INI file
$test->read(\$archive, $archiveDir.'/result_cat_test.ini');
is( $test->stdout, $archive, 'inidiff: compare identical' );

$test->run(
  interpreter => 'perl',
  prog => 'scripts/inidiff.pl',
  args => '-o '.$resultsDir.'/result_inidiff_add_section_nc_test.ini -q '.$dataDir.'/sample.ini '.$resultsDir.'/result_add_section_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_inidiff_add_section_nc_test.ini');
$test->read(\$result, $resultsDir.'/result_inidiff_add_section_nc_test.ini');
is( $result, $archive, 'inidiff: add section no comments' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'scripts/inidiff.pl',
  args =>  '-o '.$resultsDir.'/result_inidiff_add_section_wc_test.ini '.$dataDir.'/sample.ini '.$resultsDir.'/result_add_section_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_inidiff_add_section_wc_test.ini');
$test->read(\$result, $resultsDir.'/result_inidiff_add_section_wc_test.ini');
is( $result, $archive, 'inidiff: add section with comments' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'scripts/inidiff.pl',
  args =>  '-o '.$resultsDir.'/result_del_section_test.ini '.$dataDir.'/sample.ini '.$resultsDir.'/result_del_section_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_del_section_test.ini');
$test->read(\$result, $resultsDir.'/result_del_section_test.ini');
is( $result, $archive, 'inidiff: delete section' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'scripts/inidiff.pl',
  args => '-o '.$resultsDir.'/result_inidiff_del_section_nc_test.ini -q '.$resultsDir.'/result_add_section_nc.ini '.$resultsDir.'/result_del_section_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_inidiff_del_section_nc_test.ini');
$test->read(\$result, $resultsDir.'/result_inidiff_del_section_nc_test.ini');
is( $result, $archive, 'inidiff: del section no comments' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'scripts/inidiff.pl',
  args => '-o '.$resultsDir.'/result_inidiff_del_section_wc_test.ini '.$resultsDir.'/result_add_section_nc.ini '.$resultsDir.'/result_del_section_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_inidiff_del_section_wc_test.ini');
$test->read(\$result, $resultsDir.'/result_inidiff_del_section_wc_test.ini');
is( $result, $archive, 'inidiff: del section with comments' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'scripts/inidiff.pl',
  args => '-o '.$resultsDir.'/result_inidiff_add_setting_nc_test.ini -q '.$resultsDir.'/result_add_section_nc.ini '.$resultsDir.'/result_add_setting_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_inidiff_add_setting_nc_test.ini');
$test->read(\$result, $resultsDir.'/result_inidiff_add_setting_nc_test.ini');
is( $result, $archive, 'inidiff: add setting no comments' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'scripts/inidiff.pl',
  args => '-o '.$resultsDir.'/result_inidiff_add_setting_wc_test.ini '.$resultsDir.'/result_add_section_nc.ini '.$resultsDir.'/result_add_setting_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_inidiff_add_setting_wc_test.ini');
$test->read(\$result, $resultsDir.'/result_inidiff_add_setting_wc_test.ini');
is( $result, $archive, 'inidiff: add setting with comments' );
is( $? >> 8,       0,       'exit status' );


