use nqp;

my sub atkeyish(Mu \h, \k) {
    nqp::atkey(nqp::findmethod(h, 'hash')(h), k)
}

# Hand a handler's return value to the parser as a compile-time constant.
# The RakuAST frontend has no $*W, and reading a missing dynamic throws,
# so probe for it with getlexdyn rather than naming it. The node class is
# fetched by string for a similar reason. Naming RakuAST:: outright needs
# 'use experimental :rakuast', which compilers before 2023.02 reject.
my sub constantize(Mu \actions, Mu $/, Mu $value) {
    if nqp::isnull(nqp::getlexdyn('$*W')) {
        actions.attach: $/, ::("RakuAST::Constant").new(nqp::decont($value))
    }
    else {
        $/.make(do given nqp::decont($value) {
            when Str { $*W.add_string_constant(nqp::unbox_s($_)) }
            when Int { $*W.add_numeric_constant($/, 'Int', nqp::unbox_i($_)) }
            when Num { $*W.add_numeric_constant($/, 'Num', nqp::unbox_n($_)) }
            when Rat { $*W.add_numeric_constant($/, 'Num', nqp::unbox_n($_.Num)) }
        })
    }
}

my role Numish[%handlers] {
    method numish(Mu $/) {
        my $handler;
        my $source;

        if atkeyish($/, 'integer') -> $v {
            $handler := %handlers<integer>;
            $source  := $v.Str;
        }
        elsif (atkeyish($/, 'decimal-number') || atkeyish($/, 'dec_number')) -> $v {
            $handler := %handlers<decimal>;
            $source  := $v.Str;
        }
        elsif (atkeyish($/, 'radix-number') || atkeyish($/, 'rad_number')) -> $v {
            $handler := %handlers<radix>;
            $source  := $v.Str;
        }
        else {
            $handler := %handlers<numish>;
            $source  := $/.Str;
        }

        nextsame unless $handler;
        constantize(self, $/, $handler(nqp::p6box_s($source)))
    }
}

sub EXPORT(*@handlers) {
    my %handlers = @handlers.map({$_.name => $_});

    $*LANG.refine_slang('MAIN', role {}, Numish[%handlers]);

    BEGIN Map.new
}

=begin pod

=head1 NAME

overload::constant - Change stringification behaviour of literals

=head1 SYNOPSIS

=begin code :lang<raku>

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

=end code

=head1 DESCRIPTION

It is meant to work a bit like Perl's 
L<overload::constant|https://perldoc.perl.org/overload#Overloading-Constants>,
though it is kind of pre-alpha here.

=head1 AUTHOR

Tobias Leich

=head1 COPYRIGHT AND LICENSE

Copyright 2014 - 2017 Tobias Leich

Copyright 2024 Raku Community

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
