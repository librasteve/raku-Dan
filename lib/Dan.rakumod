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
- df.describe
- df.T (transpose)
- df.sort
- coerce to dtype (on new or get value?)
#]

my $db = 0;               #debug


class Series does Positional does Iterable is export {
    has Array(List) $.data is required;       #Array of data elements
    has Array(List) $.index;                  #Array of Pairs (index element => data element)
    has Any:U       $.dtype;                  #ie. type object
    has Str         $.name is rw;
    has Bool        $.copy;

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

            given %dtypes.keys.any {
                # if any are Str/Date, then whole Series must be
                when 'Str'  { 
                    $!dtype = Str;
                    die "Cannot mix other dtypes with Str!" unless %dtypes.keys.all ~~ 'Str'
                }
                when 'Date' { 
                    $!dtype = Date;
                    die "Cannot mix other dtypes with Date!" unless %dtypes.keys.all ~~ 'Date'
                }

                # Real types are handled in descending sequence
                when 'Num'  { $!dtype = Num }
                when 'Rat'  { $!dtype = Rat }
                when 'Int'  { $!dtype = Int }
                when 'Bool' { $!dtype = Bool }
            }
        }

    }

    ### Outputs ###

    method index {
        $!index.map(*.key)
    }

    method Str {
        my $attr-str = gather {
            take "name: " ~$!name if $!name;
            take "dtype: " ~$!dtype.^name if $!dtype.^name !~~ 'Any';
        }.join(', ');
        $!index.join("\n") ~ "\n" ~ $attr-str;
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

class Categorical is Series is export {
    # Output
    method dtype {
        Str.^name
    }
}

class DataFrame does Positional does Iterable is export {
    has Array       $.series is required;     #Array of Series
    has Array(List) $.columns;                #Array of Pairs (column label => Series)
    has Array(List) $.index;                  #Array (of row header)

    # Positional series arg => redispatch as Named
    multi method new( $series, *%h ) {
        samewith( :$series, |%h )
    }

    # helper methods
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
            my $index = [0..^$.row-elems];

            # make series a plain Array of Series elems 
            # make or update each Series with col key as name, index as index
            $!series = gather {
                for |$!series -> $p {
                    my $name = ~$p.key;
                    given $p.value {
                        #FIXME may be more efficient to keep when Series and reset name/index
                        #ie. new Series index setter method => when Series { take $_; $_.name = ~$p.key, $_.index: $!index }

                        when Series { take Series.new( $_.data, :$name ) }
                        when Array  { take Series.new( $_, :$name ) }
                        when Str    { take Series.new( $_, :$name, :$index ) }
                        when Real   { take Series.new( $_, :$name, :$index ) }
                        when Date   { take Series.new( $_, :$name, :$index ) }
                    }
                }
            }.Array;

            # make columns into Array of Pairs (column label => Series) 
            my $i = 0;
            for |$!series -> $s {
                $!columns.push: @labels[$i++] => $s
            }

        } else {

            # set up column labels
            my $alpha3 = 'A'..'ZZZ';

            my @labels = gather {
                for ^$!series.first.elems -> $i {
                    take ( $!columns ?? $!columns[$i] !! $alpha3[$i] )
                }
            }

            # set up index attr
            my $index = $!index ?? $!index !! [0..^$.row-elems];

            # series arg is 2d Array => make into Array of Series 
            if $!series.first ~~ Array {
                die "columns.elems != series.elems" if ( $!columns && $!columns.elems != $!series.elems );

                # make Series from 2d Array columns
                $!series = gather {
                    for $!series[*;] -> $d {
                        my $name = @labels.shift;
                        take Series.new( $d, :$name, :$index )
                    }
                }.Array

            } else {

                # make Series from Array of Series 
                $!series = gather {
                    for |$!series -> $s {
                        my $name = @labels.shift;
                        take Series.new( $s.data, :$name, :$index )
                    }
                }.Array

            }

            # make columns into Array of Pairs (alpha3 => Series)
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
            } }.join("\n")
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

    ### Role Support ###

    # Positional role support 
    # viz. https://docs.raku.org/type/Positional

    method of {
        Series
    }
    method elems {
        $!columns.elems
    }
    method AT-POS( $p ) {
        $!columns[$p].value;
    }
    method EXISTS-POS( $p ) {
        0 <= $p < $!columns.elems ?? True !! False
    }

#`[
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
#]
}

multi postcircumfix:<[ ]>( DataFrame:D $df, @slicer ) is export {
    my @new = gather {
        for @slicer -> $p {    
            take $df.AT-POS($p) 
        }
    }.Array;

    DataFrame.new( @new, index => |@new.first.index )
}

#EOF
