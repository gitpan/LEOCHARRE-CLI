use Test::Simple 'no_plan';
use lib './lib';

use base 'LEOCHARRE::CLI';
use Cwd;

$DEBUG = 1;

ok( DEBUG , 'DEBUG ok');

my $scriptname;
ok( $scriptname = _scriptname(),'scriptname returns');

ok( $scriptname eq '0.t', 'scriptname is what we expect');

#print STDERR " scriptname $scriptname\n";

#ok( yn('please enter y to confirm this works..'),'yn works');


ok( -f './t/test.conf', 'test conf file exists');


my $cwd = cwd();
my $c;

if (defined $cwd and $cwd){
   ok(1,'cwd() does return');
   $c = config( $cwd.'/t/test.conf' );

}

else {
   ok(1,'cwd() does NOT return.. trying without..');
   $c = config('./t/test.conf');
}

ok($c," config returned ");
   
ok( $c->{result} == 4,'config innards have what we expect');





my $iam = whoami();

ok($iam, "whoami() $iam");


my $tmpd;
ok($tmpd = mktmpdir(),'make temp dir returns');
ok($tmpd=~/\//, 'tmp dir has at least one slash');
ok(-d $tmpd, "temp dir exists");







