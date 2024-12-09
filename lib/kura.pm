package kura;
use strict;
use warnings;

our $VERSION = "0.05";

use Carp ();
use Sub::Util ();
use Scalar::Util ();

my %FORBIDDEN_NAME = map { $_ => 1 } qw{
    BEGIN CHECK DESTROY END INIT UNITCHECK
    AUTOLOAD STDIN STDOUT STDERR ARGV ARGVOUT ENV INC SIG
};

# This is a default constraint code to object.
# You can change this code by setting $kura::CALLABLE_TO_OBJECT.
#
# NOTE: This variable will probably change. Use caution when overriding it.
our $CALLABLE_TO_OBJECT = sub {
    my ($name, $constraint, $caller) = @_;

    require Type::Tiny;
    Type::Tiny->new(
        constraint => $constraint,
    );
};

sub import {
    my $pkg = shift;
    my $caller = caller;

    $pkg->import_into($caller, @_);
}

# Import into the caller package.
sub import_into {
    my $pkg = shift;
    my ($caller, $name, $constraint) = @_;

    my ($kura_item, $err) = _new_kura_item($name, $constraint, $caller);
    Carp::croak $err if $err;

    _save_kura_item($kura_item, $caller);
    _save_inc($caller);
}

# Create a new kura item which is Dict[name => Str, code => CodeRef].
# If the name or constraint is invalid, it returns (undef, $error_message).
# Otherwise, it returns ($kura_item, undef).
sub _new_kura_item {
    my ($name, $constraint, $caller) = @_;

    {
        return (undef, 'name is required') if !defined $name;
        return (undef, "'$name' is forbidden.") if $FORBIDDEN_NAME{$name};
        return (undef, "'$name' is already defined") if $caller->can($name);
    }

    {
        return (undef, 'constraint is required') if !defined $constraint;

        if (Scalar::Util::blessed($constraint)) {
            return (undef, 'Invalid constraint. It requires a `check` method.') if !$constraint->can('check');
        }
        elsif ( (Scalar::Util::reftype($constraint)||'') eq 'CODE') {
            $constraint = $CALLABLE_TO_OBJECT->($name, $constraint, $caller);
        }
        else {
            return (undef, 'Invalid constraint. It must be an object that has a `check` method or a code reference.');
        }
    }

    # Prefix '_' means private, so it is not exported.
    my $is_private = $name =~ /^_/ ? 1 : 0;

    my $kura_item = { name => $name, code => sub { $constraint }, is_private => $is_private };
    return ($kura_item, undef);
}

# Save the kura item to the caller package
sub _save_kura_item {
    my ($kura_item, $caller) = @_;

    my $name = $kura_item->{name};
    my $code = Sub::Util::set_subname("$caller\::$name", $kura_item->{code});

    no strict "refs";
    no warnings "once";
    *{"$caller\::$name"} = $code;

    if (!$kura_item->{is_private}) {
        push @{"$caller\::EXPORT_OK"}, $name;
        push @{"$caller\::KURA"}, $name;
    }

    return;
}

# Hack to make the caller package already loaded. Useful for multi-packages in a single file.
sub _save_inc {
    my ($caller) = @_;

    ( my $file = $caller ) =~ s{::}{/}g;
    $INC{"$file.pm"} ||= __FILE__;

    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

kura - Store constraints for Data::Checks, Type::Tiny, Moose, and more.

=head1 SYNOPSIS

    use Exporter 'import';

    use Types::Common -types;
    use Email::Valid;

    use kura Name  => StrLength[1, 255];
    use kura Email => sub { Email::Valid->address($_[0]) };

=head1 DESCRIPTION

Kura - means "Traditional Japanese storehouse" - stores constraints, such as L<Data::Checks>, L<Type::Tiny>, L<Moose::Meta::TypeConstraint>, L<Mouse::Meta::TypeConstraint>, L<Specio>, and more.
This module is useful for storing constraints in a package and exporting them to other packages. Following are the features of Kura:

=over 2

=item * Simple Declaration

=item * Export Constraints

=item * Store Multiple Constraints

=back

=head2 FEATURES

=head3 Simple Declaration

Kura makes it easy to store constraints in a package.

    use kura NAME => CONSTRAINT;

C<CONSTRAINT> must be a any object that has a C<check> method or a code reference that returns true or false.
The following is an example of a constraint declaration:

    use kura Name => StrLength[1, 255];

=head3 Export Constraints

Kura allows you to export constraints to other packages using your favorite exporter such as L<Exporter>, L<Exporter::Tiny>, and more.

    package MyPkg {
        use parent 'Exporter::Tiny';
        use Data::Checks qw(StrEq);

        use kura Foo => StrEq('foo');
    }

    use MyPkg qw(Foo);
    Foo->check('foo'); # true
    Foo->check('bar'); # false

=head3 Store Multiple Constraints

Kura supports multiple constraints such as L<Data::Checks>, L<Type::Tiny>, L<Moose::Meta::TypeConstraint>, L<Mouse::Meta::TypeConstraint>, L<Specio>, and more.

    Data::Checks -----------------> +--------+
                                    |        |
    Type::Tiny -------------------> |        |
                                    |  Kura  | ---> Named Value Constraints!
    Moose::Meta::TypeConstraint --> |        |
                                    |        |
    YourFavoriteConstraint -------> +--------+

If your project uses multiple constraint libraries, kura allows you to simplify your codes and making it easier to manage different constraint systems. This is especially useful in large projects or when migrating from one constraint system to another.
Here is an example of using multiple constraints:

    package MyFoo {
        use Exporter 'import';
        use Data::Checks qw(StrEq);
        use kura Foo => StrEq('foo');
    }

    package MyBar {
        use Exporter 'import';
        use Types::Standard -types;
        use kura Bar => Str & sub { $_[0] eq 'bar' };
    }

    package MyBaz {
        use Exporter 'import';
        use Moose::Util::TypeConstraints;
        use kura Baz => subtype as 'Str' => where { $_[0] eq 'baz' };
    }

    package MyQux {
        use Exporter 'import';
        use kura Qux => sub { $_[0] eq 'qux' };
    }

    use MyFoo qw(Foo);
    use MyBar qw(Bar);
    use MyBaz qw(Baz);
    use MyQux qw(Qux); # CodeRef converted to Type::Tiny

    ok  Foo->check('foo') && !Foo->check('bar') && !Foo->check('baz') && !Foo->check('qux');
    ok !Bar->check('foo') &&  Bar->check('bar') && !Bar->check('baz') && !Bar->check('qux');
    ok !Baz->check('foo') && !Baz->check('bar') &&  Baz->check('baz') && !Baz->check('qux');
    ok !Qux->check('foo') && !Qux->check('bar') && !Qux->check('baz') &&  Qux->check('qux');

=head2 WHY USE KURA

Kura serves a similar purpose to L<Type::Library> which is bundled with L<Type::Tiny> but provides distinct advantages in specific use cases:

=over 2

=item * Built-in Class Support

While Type::Library tightly integrates with Type::Tiny, Kura works with built-in classes.

    class Fruit {
        use Exporter 'import';
        use Types::Common -types;

        # kura meets built-in class!
        use kura Name => StrLength[1, 255];

        field $name :param :reader;
    }

=item * Simpler Declaration

Kura simplifies type constraint declarations. Unlike Type::Library, there's no need to write name twice.

Kura:

    use Exporter 'import';
    use Types::Common -types;

    use kura Name => StrLength[1, 255];
    use kura Level => IntRange[1, 100];
    use kura Player => Dict[ name => Name, level => Level ];

Type::Library:

    use Types::Library -declare => [qw(Name Level Player)]; # Need to write name twice
    use Types::Common -types;
    use Type::Utils -all;

    declare Name, as StrLength[1, 255];
    declare Level, as IntRange[1, 100];
    declare Player, as Dict[ name => Name, level => Level ];

=item * Minimal Exported Functions

Kura avoids the extra C<is_*>, C<assert_*>, and C<to_*> functions exported by Type::Library.
This keeps your namespace cleaner and focuses on the essential C<check> method.

=item * Multiple Constraints

Kura is not limited to Type::Tiny. It supports multiple constraint libraries such as Moose, Mouse, Specio, and Data::Checks.
This flexibility allows consistent management of type constraints in projects that mix different libraries.

=back

While Type::Library is powerful and versatile, Kura stands out for its simplicity, flexibility, and ability to integrate with multiple constraint systems.
It’s particularly useful in projects where multiple type constraint libraries coexist or when leveraging built-in class syntax.

=head2 NOTE

=head3 Order of declaration

When declaring constraints, it is important to define child constraints before their parent constraints to avoid errors.
If constraints are declared in the wrong order, you might encounter errors like B<Bareword not allowed>. Ensure that all dependencies are declared beforehand to prevent such issues.
For example:

    # Bad order
    use kura Parent => Dict[ name => Child ]; # => Bareword "Child" not allowed
    use kura Child => Str;

    # Good order
    use kura Child => Str;
    use kura Parent => Dict[ name => Child ];


=head3 Need to load Exporter

If you forget to put C<use Exporter 'import';>, you get an error like this:

    package MyFoo {
        # use Exporter 'import'; # Forgot to load Exporter!!
        use Data::Checks qw(StrEq);
        use kura Foo => StrEq('foo');
    }

    use MyFoo qw(Foo);
    # => ERROR!
    Attempt to call undefined import method with arguments ("Foo" ...) via package "MyFoo"
    (Perhaps you forgot to load the package?)

=head2 C<@EXPORT_OK> and C<@KURA> are automatically set

Package variables C<@EXPORT_OK> and C<@KURA> are automatically set when you use C<kura> in your package:

    package MyFoo {
        use Exporter 'import';
        use Types::Common -types;
        use kura Foo1 => StrLength[1, 255];
        use kura Foo2 => StrLength[1, 1000];

        our @EXPORT_OK;
        push @EXPORT_OK, qw(hello);

        sub hello { 'Hello, Foo!' }
    }

    # Automatically set the caller package to MyFoo
    MyFoo::EXPORT_OK # => ('Foo1', 'Foo2', 'hello')
    MyFoo::KURA      # => ('Foo1', 'Foo2')

It is useful when you want to export constraints. For example, you can tag C<@KURA> with C<%EXPORT_TAGS>:

    package MyBar {
        use Exporter 'import';
        use Types::Common -types;
        use kura Bar1 => StrLength[1, 255];
        use kura Bar2 => StrLength[1, 1000];

        our %EXPORT_TAGS = (
            types => \@MyBar::KURA,
        );
    }

    use MyBar qw(:types);
    # => Bar1, Bar2 are exported

If you don't want to export constraints, put a prefix C<_> to the constraint name:

    use kura _PrivateFoo => Str;
    # => "_PrivateFoo" is not exported

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut

