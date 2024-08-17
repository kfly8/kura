use Test2::V0;
use Test2::Require::Module 'Type::Tiny', '2.000000';

package MyX {
    use Types::Standard -types;
    use kura X => Str & sub { $_[0] eq 'x' };
}

package MyY {
    use Moose::Util::TypeConstraints;
    use kura Y => subtype as 'Str' => where { $_[0] eq 'y' };
}

package MyZ {
    use kura Z => sub { $_[0] eq 'z' };
}

package MyW {
    use Data::Checks qw(StrMatch);
    use kura W => StrMatch(qr/w/);
}

use MyX qw(X);
use MyY qw(Y);
use MyZ qw(Z);
use MyW qw(W);

ok  X->check('x') && !X->check('y') && !X->check('z') && !X->check('w');
ok !Y->check('x') &&  Y->check('y') && !Y->check('z') && !Y->check('w');
ok !Z->check('x') && !Z->check('y') &&  Z->check('z') && !Z->check('w');
ok !W->check('x') && !W->check('y') && !W->check('z') &&  W->check('w');

done_testing;
