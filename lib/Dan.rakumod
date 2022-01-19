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

class Series does Positional does Iterable is export {
    has Array $.data is required;
    has Array(List) $.index;
    has Str   $.dtype;
    has Str   $.name;
    has Bool  $.copy;

    ### Constructors ###

    # Positional data arg => redispatch as Named
    multi method new( $data, *%h ) {
        samewith( :$data, |%h )
    }

    # Real (scalar) data arg => populate Array & redispatch
    multi method new( Real :$data, :$index, *%h ) {
        die "index required if data ~~ Real" unless $index;
        samewith( data => ($data xx $index.elems).Array, :$index, |%h )
    }

    method TWEAK {
        # make index from input Hash
        if $!data.first ~~ Pair {
            die "index not permitted if data is Array of Pairs" if $!index;

            $!data = gather {
                for |$!data -> $p {
                    take $p.value;
                    $!index.push: $p;
                }
            }.Array

        # make index into Array of Pairs (index => data element)
        } else {
            die "index.elems != data.elems" if ( $!index && $!index.elems != $!data.elems );

            $!index = gather {
                my $i = 0;
                for |$!data -> $d {
                    take ( ( $!index ?? $!index[$i++] !! $i++ ) => $d )
                }
            }.Array
        }

        # check & set dtype
        my %dtypes = (); 
        for |$!data -> $d {
            %dtypes{$d.^name} = 1;
        }
        if %dtypes<Bool>:exists { $!dtype = 'Bool' }
        if %dtypes<Int>:exists  { $!dtype = 'Int' }
        if %dtypes<Num>:exists  { $!dtype = 'Num' }
        ##FIXME add Str?
    }

    ### Outputs ###

    method index {
        $!index.map(*.key)
    }

    method Str {
        $!index.join("\n") ~ "\ndtype: $!dtype"
    }

    ### Role Support ###

    # Positional role support 
    # viz. https://docs.raku.org/type/Positional

    method of {
        $!dtype 
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

    # LIMITED Associative role support 
    # viz. https://docs.raku.org/type/Associative
    # Series just implements the Assoc. methods, but does not do the Assoc. role
    # ...thus very limited support for Assoc. accessors (to ensure Positional Hyper methods win)

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
        $!data.iterator
    }
    method flat {
        $!data.flat
    }
    method lazy {
        $!data.lazy
    }
    method hyper {
        $!data.hyper
    }
}

class DataFrame does Positional does Iterable is export {
    has Array $.series is required;
    has Array(List) $.index;
    has Array(List) $.columns;

    # Positional data arg => redispatch as Named
    multi method new( $data, *%h ) {
        samewith( :$data, |%h )
    }

    # 2d Array data arg => make into Series 
    multi method new( Array:D :$data, *%h ) {
        my $series = gather {
            for $data[*;] -> $d {
                take Series.new($d)    
            }
        }.Array;

        samewith( :$series, |%h )
    }

    method TWEAK {
        die "columns.elems != series.elems" if ( $!columns && $!columns.elems != $!series.elems );

        # make columns into Array of Pairs (alpha3 => Dan::Series)
        my $alpha3 = 'A'..'ZZZ';
        $!columns = gather {
            my $i = 0;
            for |$!series -> $s {
                take ( ( $!columns ?? $!columns[$i++] !! $alpha3[$i++] ) => $s )
            }
        }.Array
    }

    method Str {
        # i is inner,       j is outer
        # i is cols across, j is rows down
        # i0 is index col , j0 is row header
        gather {
            loop ( my $j=0; $j <= $!index.elems ; $j++ ) {
                loop ( my $i=0; $i <= $!columns.elems ; $i++ ) {
                    given $j, $i {
                        when 0,0  { take "\t" }
                        when *,0  { take $!index[$j-1] }
                        when 0,*  { take $!columns[$i-1].key ~ "\t\t" }
                        default   { take $!columns[$i-1].value.data[$j-1] }
                    }
                    take "\t";
                }
                take "\n";
            }
        }.join('')
    }

    method of {
        Mu
    }
}
#`[
class Series does Positional does Iterable is export {
    has Array $.data is required;
    has Array $.index;
    has Str   $.dtype;
    has Str   $.name;
    has Bool  $.copy;

    ### Constructors ###

    # Positional data arg => redispatch as Named
    multi method new( $data, *%h ) {
        samewith( :$data, |%h )
    }

    # List index arg => redispatch as Array (to next candidate as Array ~~ List)
    multi method new( List:D :$index, *%h ) {
        nextwith( index => $index.Array, |%h )
    }

    # Real (scalar) data arg => populate Array & redispatch
    multi method new( Real :$data, :$index, *%h ) {
        die "index required if data ~~ Real" unless $index;
        samewith( data => ($data xx $index.elems).Array, :$index, |%h )
    }

    method TWEAK {
        # sort out data-index dependencies
        if $!data.first ~~ Pair {
            die "index not permitted if data is Array of Pairs" if $!index;

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

        # check & set dtype
        my %dtypes = (); 
        for |$!data -> $d {
            %dtypes{$d.^name} = 1;
        }
        if %dtypes<Bool>:exists { $!dtype = 'Bool' }
        if %dtypes<Int>:exists  { $!dtype = 'Int' }
        if %dtypes<Num>:exists  { $!dtype = 'Num' }
    }

    ### Outputs ###

    method index {
        $!index.map(*.key)
    }

    method Str {
        $!index, ", dtype:", $!dtype
    }

    ### Role Support ###

    # Positional role support 
    # viz. https://docs.raku.org/type/Positional

    method of {
        $!dtype 
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

    # LIMITED Associative role support 
    # viz. https://docs.raku.org/type/Associative
    # Series just implements the Assoc. methods, but does not do the Assoc. role
    # ...thus very limited support for Assoc. accessors (to ensure Positional Hyper methods win)

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
        $!data.iterator
    }
    method flat {
        $!data.flat
    }
    method lazy {
        $!data.lazy
    }
    method hyper {
        $!data.hyper
    }
}
#]
