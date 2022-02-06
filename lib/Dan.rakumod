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

df2.A                  df2.bool
df2.abs                df2.boxplot
df2.add                df2.C
df2.add_prefix         df2.clip
df2.add_suffix         df2.columns
df2.align              df2.copy
df2.all                df2.count
df2.any                df2.combine
df2.append             df2.D
df2.apply              df2.describe
df2.applymap           df2.diff
df2.B                  df2.duplicated
#]

my $db = 0;               #debug
my @alpha3 = 'A'..'ZZZ';

class DataSlice does Positional does Iterable is export {
    has Str     $.name is rw = 'anon';
    has Any     @.data is required;
    has Int     %.index;

    # accept index as List, make Hash
    multi method new( List:D :$index, *%h ) {
        samewith( index => $index.map({ $_ => $++ }).Hash, |%h )
    }

    method TWEAK {
        # default is DataFrame row
        unless %!index {                            
            %!index{ @alpha3[$_] } = $_ for ^@!data
        }
    }

    method Str {
        %.index.join("\n") ~ "\n" ~ "name: " ~ ~$!name;
    }

    ### Role Support ###

    # Positional role support 
    # viz. https://docs.raku.org/type/Positional

    method of {
        Any
    }
    method elems {
        @!data.elems
    }
    method AT-POS( $p ) {
        @!data[$p]
    }
    method EXISTS-POS( $p ) {
        0 <= $p < @!data.elems ?? True !! False
    }

    # LIMITED Associative role support 
    # viz. https://docs.raku.org/type/Associative
    # Series just implements the Assoc. methods, but does not do the Assoc. role
    # ...thus very limited support for Assoc. accessors (to ensure Positional Hyper methods win)

    method keyof {
        Str(Any) 
    }
    method AT-KEY( $k ) {
        @!data[%!index{$k}]
    }
    method EXISTS-KEY( $k ) {
        %!index{$k}:exists
    }

    # Iterable role support 
    # viz. https://docs.raku.org/type/Iterable

    method iterator {
        @!data.iterator
    }
    method flat {
        @!data.flat
    }
    method lazy {
        @!data.lazy
    }
    method hyper {
        @!data.hyper
    }
}

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
    has Array(List) $.index;                  #Array (of row headers)

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
                # iterate series argument
                for |$!series -> $p {
                    my $name = ~$p.key;
                    given $p.value {
                        #FIXME may be more efficient to keep when Series and reset name/index
                        #ie. new Series index setter method => 
                        #when Series { take $_; $_.name = ~$p.key, $_.index: $!index }

                        # handle Series/Array with row-elems
                        when Series { take Series.new( $_.data, :$name ) }
                        when Array  { take Series.new( $_, :$name ) }

                        # handle Scalar item (set index to expand)
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
            my @labels = gather {
                for ^$!series.first.elems -> $i {
                    take ( $!columns ?? $!columns[$i] !! @alpha3[$i] )
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
                    take ( ( $!columns ?? $!columns[$i++] !! @alpha3[$i++] ) => $s )
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

        lazy gather {
            loop ( my $j=0; $j < $.row-elems; $j++ ) {
                take lazy gather {
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
    ##method AT-POS( $p, $q? ) {
        ##$.data[$p;$q // *]
        ##$.data[$p]
        $!columns[$p].value;
    }
    method EXISTS-POS( $p ) {
        0 <= $p < $!columns.elems ?? True !! False
    }

    # LIMITED Associative role support 
    # viz. https://docs.raku.org/type/Associative
    # DataFrame just implements the Assoc. methods, but does not do the Assoc. role
    # ...thus very limited support for Assoc. accessors (to ensure Positional Hyper methods win)

    method keyof {
        Str(Any) 
    }
    method AT-KEY( $k ) {
        my @new =gather {
            for |$!columns -> $col {
                my $series := $col.value;
                for |$series.index -> $row {
                    take $row.value if $row.key ~~ $k
                }
            }
        }.Array;

        Series.new( @new, name => ~$k, index => [$!columns.map(*.key)] )
    }

    method AT-KEY-N( $k ) {
        my @new =gather {
            for |$!columns -> $col {
                my $series := $col.value;
                for |$series.index -> $row {
                    take $row.value if $row.key ~~ $k
                }
            }
        }.Array;

        #Series.new( @new, name => ~$k, index => [$!columns.map(*.key)] )
    }
#`[
    method EXISTS-KEY( $k ) {
        for |$!columns -> $p {
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

### Postcircumfix overrides to handle slices
multi postcircumfix:<[ ]>( DataFrame:D $df, @slicer where Range|List ) is export {
    my @columns = [];

    my @series = gather {
        for @slicer -> $p {    
            @columns.push: $df.columns[$p].key;
            take $df.columns[$p].value;
        }
    }.Array;

    DataFrame.new( :@series, :@columns, index => |@series.first.index.map(*.key) )
}

multi postcircumfix:<{ }>( DataFrame:D $df, @slicer where Range|List ) is export {
    my @series = gather {
        for @slicer -> $p {    
        die "yo";
        #iamerejh
            take $df.AT-KEY-N($p) 
        }
    }.Array;

    DataFrame.series( @series, index => |@series.first.index.map(*.key) );
}


#EOF
