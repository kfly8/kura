[![Actions Status](https://github.com/kfly8/kura/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/kura/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/kura/main.svg?style=flat)](https://coveralls.io/r/kfly8/kura?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/kura.svg)](https://metacpan.org/release/kura)
# NAME

kura - Store value constraints for Type::Tiny, Moose, Data::Checks, etc.

# SYNOPSIS

```perl
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
```

# DESCRIPTION

Kura - means "Traditional Japanese storehouse" - stores value constraints, such as [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny), [Moose::Meta::TypeConstraint](https://metacpan.org/pod/Moose%3A%3AMeta%3A%3ATypeConstraint) and [Data::Checks](https://metacpan.org/pod/Data%3A%3AChecks).

Simply put, it's a way to define a constraint and store it in a package.

```perl
use kura NAME => CONSTRAINT;
```

This constraint must be a any object that has a `check` method, or a code reference that returns true or false.

Kura inherits [Exporter](https://metacpan.org/pod/Exporter) and automatically adds the declared constraint to `@EXPORT_OK`. This means you can import types as follows:

```perl
use MyX qw(X);
X->check('x'); # true
```

Order of type declarations is important, child types must be declared before parent types.

```perl
# Bad order
use kura Parent => Dict[ name => Child ];
use kura Child => Str;

# Good order
use kura Child => Str;
use kura Parent => Dict[ name => Child ];
```

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>
