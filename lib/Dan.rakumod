unit module Dan:ver<0.0.1>:auth<Steve Roe (p6steve@furnival.net)>;

#`[
Todos
- slice
- nd indexing
- dtype (manual/auto)
- map
- pipe
- operators
- hyper
#]


my $db = 0;               #debug

class Series does Positional is export {
    has Array $.data is required;
    has Array $.index;
    has Str   $.dtype;
    has Str   $.name;
    has Bool  $.copy;

    method TWEAK {
        if $!data.first ~~ Pair {
            die "index not permitted if data.first ~~ Pair" if $!index;

            $!data = gather {
                for |$!data -> $p {
                    take $p.value;
                    $!index.push: $p;
                }
            }.Array

        } else {
            die "index.elems != data.elems" if ( $!index && $!index.elems != $!data.elems );

            $!index = gather {
                my $i = 0;
                for |$!data -> $d {
                    take ( ( $!index ?? $!index[$i++] !! $i++ ) => $d )
                }
            }.Array
        }
    }

    # Positional data arg
    multi method new( $data, *%h ) {
        samewith( :$data, |%h )
    }

    # Positional data arg with List index arg
    multi method new( $data, List:D :$index, *%h ) {
        samewith( :$data, index => $index.Array, |%h )
    }

    method index {
        $!index.map(*.key)
    }

    method Str {
        $!index
    }

    # Positional role support 
    # viz. https://docs.raku.org/type/Positional

    method of {
        Mu
    }
    method elems {
        $!data.elems
    }
    method AT-POS( $p ) {
        $!data[$p]
    }
    method EXISTS-POS( $p ) {
        0 <= $p < $!data.elems ?? True !! False
    }

    # Associative role support 
    # viz. https://docs.raku.org/type/Associative

    method keyof {
        Str(Any) 
    }
    method AT-KEY( $k ) {
        for |$!index -> $p {
            return $p.value if $p.key ~~ $k
        }
    }
    method EXISTS-KEY( $k ) {
        for |$!index -> $p {
            return True if $p.key ~~ $k
        }
    }

    # Iterable role support 
    # viz. https://docs.raku.org/type/Iterable

    method iterator {
    }
    method flat {
    }
    method lazy {
    }
    method hyper {
    }

    #`[
    #]
}
