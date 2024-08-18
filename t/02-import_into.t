use Test2::V0;
use lib 't/lib';
use MyChecker;

subtest 'Test `import_into` method' => sub {
    subtest 'Customize the import method to your taste' => sub {
        use MyKura Foo => MyChecker->new;

        # MyKura customize the name of the checker
        isa_ok MyFoo, 'MyChecker';
    }
};

done_testing;
