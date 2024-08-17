package kura;
use strict;
use warnings;

our $VERSION = "0.01";

use Carp qw(croak);
use Sub::Util qw(set_subname);
use Scalar::Util qw(blessed reftype);

my %forbidden_kura_name = map { $_ => 1 } qw{
    BEGIN CHECK DESTROY END INIT UNITCHECK
    AUTOLOAD STDIN STDOUT STDERR ARGV ARGVOUT ENV INC SIG
};

sub import {
    my $class = shift;
    my ($name, $checker) = @_;

    my $err;

    $err = $class->_validate_name($name);
    croak $err if $err;

    $err = $class->_validate_checker($checker);
    croak $err if $err;

    my $caller = caller;
    $err = $class->_install_checker($name, $checker, $caller);
    croak $err if $err;

    $err = $class->_setup_exporter($caller);
    croak $err if $err;
}

sub _validate_name {
    my ($class, $name) = @_;

    if (!$name) {
        return 'name is required';
    }
    elsif ($forbidden_kura_name{$name}) {
        return "'$name' is forbidden.";
    }

    return;
}

sub _validate_checker {
    my ($class, $checker) = @_;

    unless (defined $checker) {
        return 'checker is required';
    }

    return if blessed($checker) && $checker->can('check');

    my $ref = reftype($checker) // '';

    return if $ref eq 'CODE';

    return 'Not a valid checker';
}

sub _checker_to_code {
    my ($class, $checker) = @_;

    if (reftype($checker) eq 'CODE') {
        require Type::Tiny;
        $checker = Type::Tiny->new(
            constraint => $checker,
        );
    }

    sub { $checker };
}

sub _install_checker {
    my ($class, $name, $checker, $caller) = @_;

    if ($caller->can($name)) {
        return "'$name' is already defined";
    }

    my $code = $class->_checker_to_code($checker);

    {
        no strict "refs";
        *{"$caller\::$name"} = set_subname( "$caller\::$name", $code);
        push @{"$caller\::EXPORT_OK"}, $name;
    }

    return;
}

sub _exporter_class {
    'Exporter';
}

sub _setup_exporter {
    my ($class, $caller) = @_;

    my $exporter_class = $class->_exporter_class;

    unless ($caller->isa($exporter_class)) {
        no strict "refs";
        push @{ "$caller\::ISA" }, $exporter_class;
        ( my $file = $caller ) =~ s{::}{/}g;
        $INC{"$file.pm"} ||= __FILE__;
    }

    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

kura - Store value constraints for Type::Tiny, Moose, Data::Checks, etc.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Kura - means "Traditional Japanese storehouse" - stores value constraints, such as L<Type::Tiny>, L<Moose::Meta::TypeConstraint> and L<Data::Checks>.

Simply put, it's a way to define a constraint and store it in a package.

    use kura NAME => CONSTRAINT;

This constraint must be a any object that has a C<check> method, or a code reference that returns true or false.

Kura inherits L<Exporter> and automatically adds the declared constraint to C<@EXPORT_OK>. This means you can import types as follows:

    use MyX qw(X);
    X->check('x'); # true

Order of type declarations is important, child types must be declared before parent types.

    # Bad order
    use kura Parent => Dict[ name => Child ];
    use kura Child => Str;

    # Good order
    use kura Child => Str;
    use kura Parent => Dict[ name => Child ];

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut

