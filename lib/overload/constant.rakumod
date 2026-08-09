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
        actions.attach: $/, ::("RakuAST::Constant").new(nqp::decont($value))  # UNCOVERABLE
    }
    else {
        $/.make(do given nqp::decont($value) {
            my $W := $*W;
            when Str { $W.add_string_constant(nqp::unbox_s($_)) }  # UNCOVERABLE
            when Int { $W.add_numeric_constant($/, 'Int', nqp::unbox_i($_)) }  # UNCOVERABLE
            when Num { $W.add_numeric_constant($/, 'Num', nqp::unbox_n($_)) }  # UNCOVERABLE
            when Rat { $W.add_numeric_constant($/, 'Num', nqp::unbox_n($_.Num)) }  # UNCOVERABLE
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

# vim: expandtab shiftwidth=4
