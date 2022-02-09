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

        $data-str ~ "\n" ~ $attr-str
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
    has DataSlice   @.row-cache = [];

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

    method load-from-series( @series, $rows ) {
        loop ( my $j=0; $j < $rows; $j++ ) {
            loop ( my $i=0; $i < @series; $i++ ) {
                @!data[$j;$i] = @series[$i][$j]                             #TODO := with BIND-POS
            }
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
                        when Series { take Series.new( $_.data, :$name ) }
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

#`[ #iamerejh
    method dtypes {
        gather {
            for |$!columns -> $p {
                take $p.key ~ ' => ' ~ $p.value.dtype;
            } }.join("\n")
    }
#]

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

}

#`[[[

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
#]]]

#`[[   hopefully no need for pcf s
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
#]]

#EOF
