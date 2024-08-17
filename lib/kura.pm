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

kura - It's new $module

=head1 SYNOPSIS

    use kura;

=head1 DESCRIPTION

kura is ...

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut

