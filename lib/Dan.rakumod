unit module Dan:ver<0.0.1>:auth<Steve Roe (p6steve@furnival.net)>;

use Text::Table::Simple;

#`[
Todos
- slice
- nd indexing
- dtype (manual/auto)
- map
- pipe
- operators
- hyper
- META6.json with deps
#]


my $db = 0;               #debug

class Categorical does Positional does Iterable is export {
    has Array(List) $.data is required;

    # Positional constructor
    multi method new( $data, *%h ) {
        samewith( :$data, |%h )
    }

    # Output
    method dtype {
        Str.^name
    }

    # Positional role support 
    # viz. https://docs.raku.org/type/Positional

    method of {
        Str 
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

class Series does Positional does Iterable is export {
    has Array $.data is required;
    has Array(List) $.index;
    has Any:U $.dtype;      #ie. type object
    has Str   $.name;
    has Bool  $.copy;

    ### Constructors ###

    # Positional data arg => redispatch as Named
    multi method new( $data, *%h ) {
        samewith( :$data, |%h )
    }

    # Real (scalar) data arg => populate Array & redispatch
    multi method new( Real:D :$data, :$index, *%h ) {
        die "index required if data ~~ Real" unless $index;
        samewith( data => ($data xx $index.elems).Array, :$index, |%h )
    }

    # Str (scalar) data arg => populate Array & redispatch
    multi method new( Str:D :$data, :$index, *%h ) {
        die "index required if data ~~ Str" unless $index;
        samewith( data => ($data xx $index.elems).Array, :$index, |%h )
    }

    # Date (scalar) data arg => populate Array & redispatch
    multi method new( Date:D :$data, :$index, *%h ) {
        die "index required if data ~~ Date" unless $index;
        samewith( data => ($data xx $index.elems).Array, :$index, |%h )
    }

    multi method dtype {
        $!dtype.^name       #provide ^name of type object eg. for output
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

        # auto set dtype if not set from args
        if $.dtype eq 'Any' {       #can't use !~~ Any since always False

            my %dtypes = (); 
            for |$!data -> $d {
                %dtypes{$d.^name} = 1;
            }

            given %dtypes.keys.all {
                when 'Str'  { $!dtype = Str }
                when 'Rat'  { $!dtype = Rat }
                when 'Num'  { $!dtype = Num }
                when 'Int'  { $!dtype = Int }
                when 'Bool' { $!dtype = Bool }
                when 'Date' { $!dtype = Date }
            }
        }

    }

    ### Outputs ###

    method index {
        $!index.map(*.key)
    }

    method Str {
        $!index.join("\n") ~ "\ndtype: " ~ $!dtype.^name
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

    # Positional series arg => redispatch as Named
    multi method new( $series, *%h ) {
        samewith( :$series, |%h )
    }

    method  row-elems {
        my $row-elems = 0;
        for |$!series {
            when Pair { $row-elems max= .value.elems } 
            default   { $row-elems max= .elems }
        }
        $row-elems
    }

    method TWEAK {
        # series arg is Array of Pairs (no index)
        if $!series.first ~~ Pair {
            die "columns / index not permitted if data is Array of Pairs" if $!index || $!columns;

            my @labels = $!series.map(*.key);

            # make series a plain Array of Series objects 
            $!series = gather {
                for |$!series -> $p {
                    given $p.value {
                        when Series      { take $p.value }
                        when Array       { take Series.new( $_ ) }
                        when Str         { take Series.new( $_, index => [0..^$.row-elems] ) }
                        when Real        { take Series.new( $_, index => [0..^$.row-elems] ) }
                        when Date        { take Series.new( $_, index => [0..^$.row-elems] ) }
                        when Categorical { take $p.value }
                    }
                }
            }.Array;

            # make columns into Array of Pairs (label => Series) 
            my $i = 0;
            for |$!series -> $s {
                $!columns.push: @labels[$i++] => $s
            }

        } else {
            # series arg is 2d Array => make into Series 
            if $!series.first ~~ Array {
                die "columns.elems != series.elems" if ( $!columns && $!columns.elems != $!series.elems );

                # make Series from array columns
                $!series = gather {
                    for $!series[*;] -> $s {
                        take Series.new($s)    
                    }
                }.Array
            }

            # make columns into Array of Pairs (alpha3 => Dan::Series)
            my $alpha3 = 'A'..'ZZZ';

            $!columns = gather {
                my $i = 0;
                for |$!series -> $s {
                    take ( ( $!columns ?? $!columns[$i++] !! $alpha3[$i++] ) => $s )
                }
            }.Array
        }

        if $!index {
            die "index.elems != row-elems" if ( $!index && $!index.elems != $.row-elems );

        } else {
            $!index = [0..^$.row-elems];
        }
    }

    ### Getter & Output Methods ###

    method dtypes {
        gather {
            for |$!columns -> $p {
                take $p.key ~ ' => ' ~ $p.value.dtype;
            }
        }.join("\n")
    }

    method Str {
        # i is inner,       j is outer
        # i is cols across, j is rows down
        # i0 is index col , j0 is row header

        # column headers
        my @out-cols = $!columns.map(*.key);
        @out-cols.unshift: '';

        # rows (incl. row headers)
        my @out-rows = gather {
            loop ( my $j=1; $j <= $.row-elems; $j++ ) {
                take gather {
                    loop ( my $i=0; $i <= $!columns.elems; $i++ ) {
                        given $j, $i {
                            when *,0  { take ~$!index[$j-1] }
                            when 0,*  { take ~$!columns[$i-1].key }
                            default   { take ~$!columns[$i-1].value.data[$j-1] }
                        }
                    }
                }.Array
            }
        }.Array;

        # set table options 
        my %options = %(
            rows => {
                column_separator     => '',
                corner_marker        => '',
                bottom_border        => '',
            },
            headers => {
                top_border           => '',
                column_separator     => '',
                corner_marker        => '',
                bottom_border        => '',
            },
            footers => {
                column_separator     => '',
                corner_marker        => '',
                bottom_border        => '',
            },
        );

        my @table = lol2table(@out-cols, @out-rows, |%options);
        @table.join("\n")
    }

    method data {
        # i is inner,       j is outer
        # i is cols across, j is rows down
        # no headers, just data elems

        gather {
            loop ( my $j=0; $j < $.row-elems; $j++ ) {
                take gather {
                    loop ( my $i=0; $i < $!columns.elems; $i++ ) {
                        take ~$!columns[$i].value.data[$j]
                    }
                }.Array
            }
        }.Array
    }

    method of {
        Mu
    }
}

#EOF
