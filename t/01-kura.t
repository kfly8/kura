use Test2::V0;

use lib './t/lib';
use MyChecker;

subtest 'Test `kura` features' => sub {
    subtest '`kura` import checker into caller' => sub {
        use kura X => MyChecker->new;
        isa_ok X, 'MyChecker';
    };

    subtest '`kura` with constarint and other function.' => sub {
        use MyFoo qw(Foo hello);
        isa_ok Foo, 'MyChecker';
        is hello(), 'Hello, Foo!';
    };
};

subtest 'Test `kura` exceptions' => sub {
    subtest 'Checker already defined' => sub {
        eval "use kura Foo => MyChecker->new";
        like $@, qr/^'Foo' is already defined/;
    };

    subtest 'Not given name' => sub {
        eval "use kura";
        like $@, qr/^name is required/;
    };

    subtest 'Forbidden name' => sub {
        eval "use kura BEGIN => MyChecker->new";
        like $@, qr/^'BEGIN' is forbidden/;
    };

    subtest 'Not given checker' => sub {
        eval "use kura Foo";
        like $@, qr/^checker is required/;
    };

    subtest 'Invalid checker' => sub {
        eval "use kura Bar => 1";
        like $@, qr/^Not a valid checker/;
    };

    subtest 'Invalid orders' => sub {
        eval "
            use kura B => A;
            use kura A => MyChecker->new;
        ";
        like $@, qr/^Bareword "A" not allowed/;
    };
};

done_testing;
