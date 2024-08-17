use Test2::V0;

use lib 't/lib';
use MyChecker;

subtest 'Test `kura` features' => sub {
    subtest '`kura` import checker into caller' => sub {
        use kura Foo => MyChecker->new;
        isa_ok Foo, 'MyChecker';
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

    subtest 'Invalid checker' => sub {
        eval "use kura Bar => sub { 1 }";
        like $@, qr/^Not a valid checker/;

        eval "use kura Bar => 1";
        like $@, qr/^Not a valid checker/;
    };
};


done_testing;
