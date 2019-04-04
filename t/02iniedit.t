use Test::Cmd;
use Test2::Bundle::More;
use Cwd;

plan tests => 9;

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
  prog => 'scripts/iniedit.pl',
  args => '-f '.$dataDir.'/sample.ini -i '.$dataDir.'/add_section_nc.ini -o '.$resultsDir.'/result_add_section_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_add_section_nc.ini');
$test->read(\$result, $resultsDir.'/result_add_section_nc.ini');
is( $result, $archive, 'iniedit: add section' );

$test->run(
  interpreter => 'perl',
  prog => 'scripts/iniedit.pl',
  args => '-f '.$resultsDir.'/result_add_section_nc.ini -i '.$dataDir.'/del_section_nc.ini -o '.$resultsDir.'/result_del_section_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_del_section_nc.ini');
$test->read(\$result, $resultsDir.'/result_del_section_nc.ini');
is( $result, $archive, 'iniedit: delete section' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'scripts/iniedit.pl',
  args => '-f '.$resultsDir.'/result_add_section_nc.ini -i '.$dataDir.'/del_setting_nc.ini -o '.$resultsDir.'/result_del_setting_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_del_setting_nc.ini');
$test->read(\$result, $resultsDir.'/result_del_setting_nc.ini');
is( $result, $archive, 'iniedit: delete setting' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'scripts/iniedit.pl',
  args => '-f '.$resultsDir.'/result_add_section_nc.ini -i '.$dataDir.'/modify_setting_nc.ini -o '.$resultsDir.'/result_modify_setting_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_modify_setting_nc.ini');
$test->read(\$result, $resultsDir.'/result_modify_setting_nc.ini');
is( $result, $archive, 'iniedit: modify setting' );
is( $? >> 8,       0,       'exit status' );

$test->run(
  interpreter => 'perl',
  prog => 'scripts/iniedit.pl',
  args => '-f '.$resultsDir.'/result_add_section_nc.ini -i '.$dataDir.'/add_setting_nc.ini -o '.$resultsDir.'/result_add_setting_nc.ini',
  # verbose => 1,
);
$test->read(\$archive, $archiveDir.'/result_add_setting_nc.ini');
$test->read(\$result, $resultsDir.'/result_add_setting_nc.ini');
is( $result, $archive, 'iniedit: add setting' );
is( $? >> 8,       0,       'exit status' );
