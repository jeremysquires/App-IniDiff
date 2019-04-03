use Test::Cmd;
use Test2::Bundle::More;
use Cwd;

plan tests => 3;

my $dir = getcwd;

my $test = Test::Cmd->new();

$test->run(
  interpreter => 'perl',
  prog => 'scripts/inicat.pl '.$dir.'/t/data/sample.ini',
  # verbose => 1,
);
$test->read(\$archive, $dir.'/t/archive/result_cat_sample.ini');
is( $test->stdout, $archive, 'stdout' );

$test->run(
  prog => 'scripts/inicat.pl',
  interpreter => 'perl',
  args => '-o '.$dir.'/t/result_cat_sample.ini '.$dir.'/t/data/sample.ini',
);
$test->read(\$result, $dir.'/t/result_cat_sample.ini');
is( $result, $archive, 'o outfile');

is( $? >> 8,       1,       'exit status' );
