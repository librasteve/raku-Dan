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
- demote Array to List (still does pos and iter)

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

# helper declarations & functions

my @alpha3 = 'A'..'ZZZ';

# sort Hash by value, return keys
# poor man's Ordered Hash
sub sbv( %h --> Seq ) {
    %h.sort(*.value).map(*.key)
}

role DataSlice does Positional does Iterable is export {
    has Str     $.name is rw = 'anon';
    has Any     @.data;
    has Int     %.index;

    ### Contructors ###

    # accept index as List, make Hash
    multi method new( List:D :$index, *%h ) {
        samewith( index => $index.map({ $_ => $++ }).Hash, |%h )
    }

    ### Output Methods ###

    method str-attrs {
        %( :$.name ) 
    }

    method Str {
        my $data-str = gather {
            for %!index.&sbv -> $k {
                take $k => @!data[%!index{$k}]
            }
        }.join("\n");

        my $attr-str = gather {
            for $.str-attrs.sort.map(*.kv).flat -> $k, $v {
                take "$k: " ~$v
            }
        }.join(', ');

        $data-str ~ "\n" ~ $attr-str ~ "\n"
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
    # DataSlice just implements the Assoc. methods, but does not do the Assoc. role
    # ...thus very limited support for Assoc. accessors (to ensure Positional Hyper methods win)

    method keyof {
        Str(Any) 
    }
    method AT-KEY( $k ) {
        @!data[%.index{$k}]
    }
    method EXISTS-KEY( $k ) {
        %.index{$k}:exists
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

class Series does DataSlice is export {
    has Any:U       $.dtype;                  #ie. type object

    ### Constructors ###

    # Positional data array arg => redispatch as Named
    multi method new( @data, *%h ) {
        samewith( :@data, |%h )
    }
    # Positional data scalar arg => redispatch as Named
    multi method new( $data, *%h ) {
        samewith( :$data, |%h )
    }
    # accept index as List, make Hash
    multi method new( List:D :$index, *%h ) {
        samewith( index => $index.map({ $_ => $++ }).Hash, |%h )
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
        # make index & data from %(index => data) Hash
        if @.data.first ~~ Pair {
            die "index not permitted if data is Array of Pairs" if %.index;

            @.data = gather {
                for @.data -> $p {
                    take $p.value;
                    %.index.push: $p;
                }
            }.Array

        # make index Hash (index => pos)
        } else {
            die "index.elems != data.elems" if ( %.index && %.index.elems != @.data.elems );

            if ! %.index {
                my $i = 0;
                %.index{~$i} = $i++ for ^@.data
            }
        }

        # auto set dtype if not set from args
        if $.dtype eq 'Any' {       #can't use !~~ Any since always False

            my %dtypes = (); 
            for @.data -> $d {
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
    method str-attrs {
        %( :$.name, dtype => $!dtype.^name,)
    }
}

class Categorical is Series is export {
    # Output
    method dtype {
        Str.^name
    }
}

role DataFrame does Positional does Iterable is export {
    has Str         $.name is rw = 'anon';
    has Any         @.data = [];        #redo 2d shaped Array when [; ] implemented
    has Int         %.index;            #row index
    has Int         %.columns;          #column index
    has Str         @.dtypes;

    ### Contructors ###

    # Positional data array arg => redispatch as Named
    multi method new( @data, *%h ) {
        samewith( :@data, |%h )
    }

    # accept index as List, make Hash
    multi method new( List:D :$index, *%h ) {
        samewith( index => $index.map({ $_ => $++ }).Hash, |%h )
    }

    # accept columns as List, make Hash
    multi method new( List:D :$columns, *%h ) {
        samewith( columns => $columns.map({ $_ => $++ }).Hash, |%h )
    }

    # helper functions

    method load-from-series( @series, $row-count ) {
        loop ( my $i=0; $i < @series; $i++ ) {
            loop ( my $j=0; $j < $row-count; $j++ ) {
                @!data[$j;$i] = @series[$i][$j]                             #TODO := with BIND-POS
            }
        }
    }

    method load-from-slices( @slices ) {
        loop ( my $i=0; $i < @slices; $i++ ) {
            %.index{@slices[$i].name} = $i;
            @!data[$i] := @slices[$i].data;
        }
    }

    method TWEAK {
        # data arg is 1d Array of Pairs (label => Series)
        if @!data.first ~~ Pair {
            die "columns / index not permitted if data is Array of Pairs" if %!index || %!columns;

            my $row-count = 0;
            @!data.map( $row-count max= *.value.elems );

            my @index  = 0..^$row-count;
            my @labels = @!data.map(*.key);

            # make (or update) each Series with column key as name, index as index
            my @series = gather {
                for @!data -> $p {
                    my $name = ~$p.key;
                    given $p.value {
                        # handle Series/Array with row-elems (auto index)   #TODO: avoid Series.new
                        when Series { take Series.new( $_.data, :$name, dtype => ::($_.dtype) ) }
                        when Array  { take Series.new( $_, :$name ) }

                        # handle Scalar items (set index to auto-expand)    #TODO: lazy expansion
                        when Str|Real|Date { take Series.new( $_, :$name, :@index ) }
                    }
                }
            }.Array;

            # clear and load data
            @!data = [];
            $.load-from-series: @series, +@index;

            # make index Hash (row label => pos) 
            my $j = 0;
            %!index{~$j} = $j++ for ^@index;

            # make columns Hash (col label => pos) 
            my $i = 0;
            %!columns{@labels[$i]} = $i++ for ^@labels;
        } 

        # data arg is 1d Array of DataSlice (rows)
        elsif @!data.first ~~ DataSlice {

            my @slices = @!data; 

            # clear and load data (and index)
            @!data = [];
            $.load-from-slices: @slices;

            # make columns Hash
            %.columns = @slices.first.index;
        }

        else {
            die "columns.elems != data.first.elems" if ( %!columns && %!columns.elems != @!data.first.elems );

            if ! %!index {
                [0..^@!data.elems].map( {%!index{$_.Str} = $_} )
            }

            if ! %!columns {
                @alpha3[0..^@!data.first.elems].map( {%!columns{$_} = $++} ) 
            }

            # data arg is 1d Array of Series (cols)                         #TODO: testme
            if @!data.first ~~ Series {

                my @series = @!data; 

                # clear and load data
                @!data = [];
                $.load-from-series: @series, +%!index;
            }

            # data arg is 2d Array (already) 
            else {
                #no-op
            } 

        }
    }

    ### Output methods ###

    method dtypes {                                                         #TODO: dynamic with new Series
        gather {
            for %!columns.&sbv -> $k {
                take $k ~ ' => ' ~ @!dtypes[$++]
            }
        }.join("\n")
    }
        
    method Str {
        # i is inner,       j is outer
        # i is cols across, j is rows down
        # i0 is index col , j0 is row header

        # headers
        my @row-hdrs = %!index.&sbv;
        my @col-hdrs = %!columns.&sbv;
           @col-hdrs.unshift: '';

        # rows (incl. row headers)
        my @out-rows = @!data.deepmap( * ~~ Date ?? *.Str !! * );
           @out-rows.map( *.unshift: @row-hdrs.shift );

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

        my @table = lol2table(@col-hdrs, @out-rows, |%options);
        @table.join("\n")
    }

    ### Role Support ###

    # Positional role support 
    # viz. https://docs.raku.org/type/Positional
    # delegates semilist [; ] value element access to @!data
    # override list [] access anyway

    method of {
        Any
    }
    method elems {
        @!data.elems
    }
    method AT-POS( $p, $q? ) {
        @!data[$p;$q // *]
    }
    method EXISTS-POS( $p ) {
        0 <= $p < @!data.elems ?? True !! False
    }

}

#`[[[

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
#]]]

### Postfix '^' as explicit subscript chain terminator
multi postfix:<^>( DataSlice @ds ) is export {
    DataFrame.new(@ds) 
}
multi postfix:<^>( DataSlice $ds ) is export {
    DataFrame.new(($ds,)) 
}

### Postcircumfix overrides first subscript [i] to make DataSlices (rows)

#| single DataSlice can then be [j] subscripted directly to value 
multi postcircumfix:<[ ]>( DataFrame:D $df, Int $p ) is export {
    DataSlice.new( data => $df.data[$p;*], index => $df.columns, name => $df.index.&sbv[$p] )
}

#| slices make Array of DataSlice objects
multi postcircumfix:<[ ]>( DataFrame:D $df, @s where Range|List ) is export {
    my DataSlice @aods =
    @s.map({
        DataSlice.new( data => $df.data[$_;*], index => $df.columns, name => $df.index.&sbv[$_] )
    })
}
multi postcircumfix:<[ ]>( DataFrame:D $df, WhateverCode $p ) is export {
    my @s = $p( $df.elems );
    my DataSlice @aods =
    @s.map({
        DataSlice.new( data => $df.data[$_;*], index => $df.columns, name => $df.index.&sbv[$_] )
    })
}
multi postcircumfix:<[ ]>( DataFrame:D $df, Whatever ) is export {
    my DataSlice @aods =
    $df.data.map({
        DataSlice.new( data => |$_, index => $df.columns, name => $df.index.&sbv[$++] )
    })
}

multi postcircumfix:<[ ]>( DataSlice @aods , Int $p ) is export {
    say "yo"
}

#`[[
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
#]]

#EOF



























