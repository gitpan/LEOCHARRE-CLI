use Test::Simple 'no_plan';
BEGIN { use lib './lib'; }
use base 'LEOCHARRE::CLI';
use Cwd;

$DEBUG = 1;

ok( DEBUG , 'DEBUG ok');

ok( _scriptname(),'scriptname returns');

#ok( yn('please enter y to confirm this works..'),'yn works');


my $c = config( cwd().'/t/test.conf' );

ok($c->{result} == 4,'config() works');

my $iam = whoami();

ok($iam, "whoami() $iam");



my $tmpd = mktmpdir();

ok($tmpd, "made temp dir $tmpd");
