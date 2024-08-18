package MyFoo;

our @EXPORT_OK;
push @EXPORT_OK, qw(hello);

use lib 't/lib';
use MyChecker;

use kura Foo => MyChecker->new;

sub hello { 'Hello, Foo!' }

1;
