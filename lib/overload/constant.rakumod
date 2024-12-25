use nqp;

my sub atkeyish(Mu \h, \k) {
    nqp::atkey(nqp::findmethod(h, 'hash')(h), k)
}

my role Numish[%handlers] {
    method numish(Mu $/) {

        sub call-handler($r) {
            do given nqp::decont($r) {
                when Str { $*W.add_string_constant( nqp::unbox_s($_) ) }
                when Int { $*W.add_numeric_constant($/, 'Int', nqp::unbox_i($_)) }
                when Num { $*W.add_numeric_constant($/, 'Num', nqp::unbox_n($_)) }
                when Rat { $*W.add_numeric_constant($/, 'Num', nqp::unbox_n($_.Num)) }
            }
        }
        if atkeyish($/, 'integer') -> $v {
            $/.make( %handlers<integer>
              ?? call-handler(%handlers<integer>(nqp::p6box_s($v.Str)))
              !! $*W.add_numeric_constant($/, 'Int', $v.made) )
        }
        elsif atkeyish($/, 'dec_number') -> $v {
            $/.make( %handlers<decimal>
              ?? call-handler(%handlers<decimal>(nqp::p6box_s($v.Str)))
              !! $v.made )
        }
        elsif atkeyish($/, 'rad_number') -> $v {
            $/.make( %handlers<radix>
              ?? call-handler(%handlers<radix>(nqp::p6box_s($v.Str)))
              !! $v.made )
        }
        else {
            $/.make( %handlers<numish>
              ?? call-handler(%handlers<numish>(nqp::p6box_s($/.Str)))
              !! $*W.add_numeric_constant($/, 'Num', +nqp::p6box_s($/.Str)) )
        }
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
