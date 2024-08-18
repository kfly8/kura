use Test2::V0;
use lib 't/lib';
use MyChecker;

subtest 'Test `import_into` method' => sub {
    subtest 'Checker is imported into $target_package' => sub {
        package Foo {}
        my $target_package = 'Foo';

        use kura ();
        kura->import_into($target_package, Hello => MyChecker->new);

        isa_ok Foo::Hello(), 'MyChecker';
    };

    subtest 'So, you can customize the import method to your taste' => sub {
        use MyKura Foo => MyChecker->new;

        # MyKura customize the name of the checker
        isa_ok MyFoo, 'MyChecker';
    }
};

done_testing;
