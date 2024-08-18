package mykura;
use strict;
use warnings;

use kura ();

sub import {
    my $class = shift;
    my $caller = caller;

    my ($name, $checker) = @_;

    $name = 'My' . $name;

    kura->import_into($caller, $name, $checker);
}

1;
