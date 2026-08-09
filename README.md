[![Actions Status](https://github.com/raku-community-modules/overload-constant/actions/workflows/linux.yml/badge.svg)](https://github.com/raku-community-modules/overload-constant/actions) [![Actions Status](https://github.com/raku-community-modules/overload-constant/actions/workflows/macos.yml/badge.svg)](https://github.com/raku-community-modules/overload-constant/actions) [![Actions Status](https://github.com/raku-community-modules/overload-constant/actions/workflows/windows.yml/badge.svg)](https://github.com/raku-community-modules/overload-constant/actions)

NAME
====

overload::constant - Change stringification behaviour of literals

SYNOPSIS
========

```raku
use overload::constant;

sub integer { "i$^a" }
sub decimal { "d$^a" }
sub radix   { "r$^a" }
sub numish  { "n$^a" }
use overload::constant &integer, &decimal, &radix, &numish;

ok 42      ~~ Str && 42      eq 'i42',      'can overload integer';
ok 0.12    ~~ Str && 0.12    eq 'd0.12',    'can overload decimal';
ok .1e-003 ~~ Str && .1e-003 eq 'd.1e-003', 'can overload decimal in scientific notation';
ok :16<FF> ~~ Str && :16<FF> eq 'r:16<FF>', 'can overload radix';
ok NaN     ~~ Str && NaN     eq 'nNaN',     'can overload other numish things';
```

DESCRIPTION
===========

It is meant to work a bit like Perl's [overload::constant](https://perldoc.perl.org/overload#Overloading-Constants).

The positional arguments given to `use overload::constant` are keyed to the name of the subroutine being passed.

AUTHOR
======

Tobias Leich

Source can be located at: https://github.com/raku-community-modules/overload-constant . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2014 - 2017 Tobias Leich

Copyright 2024, 2026 Raku Community

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

