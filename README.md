[![Actions Status](https://github.com/kfly8/kura/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/kura/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/kura/main.svg?style=flat)](https://coveralls.io/r/kfly8/kura?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/kura.svg)](https://metacpan.org/release/kura)
# NAME

kura - Store constraints for Data::Checks, Type::Tiny, Moose and more.

# SYNOPSIS

```perl
package MyFoo {
    use Data::Checks qw(StrEq);
    use kura Foo => StrEq('foo');
}

package MyBar {
    use Types::Standard -types;
    use kura Bar => Str & sub { $_[0] eq 'bar' };
}

package MyBaz {
    use Moose::Util::TypeConstraints;
    use kura Baz => subtype as 'Str' => where { $_[0] eq 'baz' };
}

package MyQux {
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
```

# DESCRIPTION

Kura - means "Traditional Japanese storehouse" - stores constraints, such as [Data::Checks](https://metacpan.org/pod/Data%3A%3AChecks), [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny), [Moose::Meta::TypeConstraint](https://metacpan.org/pod/Moose%3A%3AMeta%3A%3ATypeConstraint), [Mouse::Meta::TypeConstraint](https://metacpan.org/pod/Mouse%3A%3AMeta%3A%3ATypeConstraint), [Specio](https://metacpan.org/pod/Specio) and more. It can even be used with [Moo](https://metacpan.org/pod/Moo) when combined with [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny) constraints.

```
Data::Checks -----------------> +--------+
                                |        |
Type::Tiny -------------------> |        |
                                |  Kura  | ---> Named Value Constraints!
Moose::Meta::TypeConstraint --> |        |
                                |        |
YourFavoriteConstraint -------> +--------+
```

If your project uses multiple constraint libraries, kura allows you to simplify your codes and making it easier to manage different constraint systems. This is especially useful in large projects or when migrating from one constraint system to another.

# HOW TO USE

## Declaring a constraint

It's easy to use to store constraints in a package:

```perl
use kura NAME => CONSTRAINT;
```

This constraint must be a any object that has a `check` method or a code reference that returns true or false.

When declaring constraints, it is important to define child constraints before their parent constraints to avoid errors. For example:

```perl
# Bad order
use kura Parent => Dict[ name => Child ]; # => Bareword "Child" not allowed
use kura Child => Str;

# Good order
use kura Child => Str;
use kura Parent => Dict[ name => Child ];
```

If constraints are declared in the wrong order, you might encounter errors like “Bareword not allowed.” Ensure that all dependencies are declared beforehand to prevent such issues.

## Using a constraint

You can use the declared constraint as follows:

```perl
package MyFoo {
    use Data::Checks qw(StrEq);
    use kura Foo => StrEq('foo');
}

use MyFoo qw(Foo);
Foo->check('foo'); # true
```

Internally, Kura inherits [Exporter](https://metacpan.org/pod/Exporter) and automatically adds the declared constraint to `@EXPORT_OK`:

```
MyFoo->isa('Exporter'); # true
@MyFoo::EXPORT_OK; # ('Foo')
```

So, you can add other functions to `@EXPORT_OK`:

```perl
 package MyFoo {
     our @EXPORT_OK;
     push @EXPORT_OK => qw(hello);

     use kura Foo => sub { $_[0] eq 'foo' };

     sub hello { 'Hello, World!' }
}

use MyFoo qw(Foo hello);
hello(); # 'Hello, World!'
```

# Customizing

## `$EXPORTER_CLASS`

`$EXPORTER_CLASS` is a package name of the Exporter class, default is [Exporter](https://metacpan.org/pod/Exporter).
You can change this class by setting `$kura::EXPORTER_CLASS`.

```perl
package mykura {
    use kura ();

    sub import {
        my $pkg = shift;
        my $caller = caller;

        local $kura::EXPORTER_CLASS = 'Exporter::Tiny';
        kura->import_into($caller, @_);
    }
}

package MyFoo {
    use mykura Foo => sub { $_[0] eq 'foo' };
}

# Exporter::Tiny accepts the `-as` option
use MyFoo Foo => { -as => 'CheckerFoo' };

CheckerFoo->check('foo'); # true
```

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>
