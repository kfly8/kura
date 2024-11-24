use Test2::V0;
use Test2::Require::Module 'Type::Tiny', '2.000000';
use Test2::Require::Perl 'v5.38';

use FindBin qw($Bin);
use lib "$Bin";

# Error! builtin-class @ISA is a read-only, but attempt to modify it
use TestBuiltinClass qw(Foo);

subtest 'Test `kura` with builtin class' => sub {
    isa_ok Foo, 'Type::Tiny';

    ok !Foo->check('');
    ok Foo->check('foo');
};

done_testing;
