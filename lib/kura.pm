package kura;
use strict;
use warnings;
use feature qw(state);

our $VERSION = "0.01";

use Carp ();
use Sub::Util ();
use Scalar::Util ();

my %forbidden_kura_name = map { $_ => 1 } qw{
    BEGIN CHECK DESTROY END INIT UNITCHECK
    AUTOLOAD STDIN STDOUT STDERR ARGV ARGVOUT ENV INC SIG
};

sub import {
    my $pkg = shift;
    my $caller = caller;

    $pkg->import_into($caller, @_);
}

sub import_into {
    my $pkg = shift;
    my ($caller, $name, $checker) = @_;

    state $validate_name = sub {
        my ($name) = @_;

        if (!$name) {
            return 'name is required';
        }
        elsif ($forbidden_kura_name{$name}) {
            return "'$name' is forbidden.";
        }
        return;
    };

    state $validate_checker = sub {
        my ($checker) = @_;

        unless (defined $checker) {
            return 'checker is required';
        }

        return if Scalar::Util::blessed($checker) && $checker->can('check');

        my $ref = Scalar::Util::reftype($checker) // '';

        return if $ref eq 'CODE';

        return 'Not a valid checker';
    };

    state $checker_to_code = sub {
        my ($checker) = @_;

        if (Scalar::Util::reftype($checker) eq 'CODE') {
            require Type::Tiny;
            $checker = Type::Tiny->new(
                constraint => $checker,
            );
        }

        sub { $checker };
    };

    state $install_checker = sub {
        my ($name, $checker, $caller) = @_;

        if ($caller->can($name)) {
            return "'$name' is already defined";
        }

        my $code = $checker_to_code->($checker);

        {
            no strict "refs";
            *{"$caller\::$name"} = Sub::Util::set_subname( "$caller\::$name", $code);
            push @{"$caller\::EXPORT_OK"}, $name;
        }

        return;
    };

    state $setup_exporter = sub {
        my ($caller) = @_;

        my $exporter_class = 'Exporter';

        unless ($caller->isa($exporter_class)) {
            no strict "refs";
            push @{ "$caller\::ISA" }, $exporter_class;
            ( my $file = $caller ) =~ s{::}{/}g;
            $INC{"$file.pm"} ||= __FILE__;
        }

        return;
    };

    my $err;

    $err = $validate_name->($name);
    Carp::croak $err if $err;

    $err = $validate_checker->($checker);
    Carp::croak $err if $err;

    $err = $install_checker->($name, $checker, $caller);
    Carp::croak $err if $err;

    $err = $setup_exporter->($caller);
    Carp::croak $err if $err;
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

