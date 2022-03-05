unit module Dan:ver<0.0.1>:auth<Steve Roe (p6steve@furnival.net)>;

use Text::Table::Simple;

#`[
Todos
- slice
- nd indexing
- dtype (manual/auto)
- map
- pipe
- hyper
- operators
- df.T (transpose)
- df.series
- df.dtypes (dynamic)
- df.sort
- df.grep
- df.describe
- META6.json with deps

v1 Backlog
- Apply Dan::Pandas spike 
- Setting data
-- reindex
^^^ done
-- drop
-- assign
-- combine
-- concat (cover append, join, merge)
- Shape (just simple)
- Input/Output (just csv)

v2 Backlog 
(much of this is test / synopsis examples / new mezzanine methods)
- Exceptions
- Apply
- Index alignment
- Missing data
- Duplicate labels
- Stats
- Histogramming
- String ops
- Merge
- Join 
- Group
- SQL style ops
- Reshaping (stacking)
- Pivot tables
- Time Series
- Categoricals (Enums)
- Plotting

Issues/Questions
- keep manual Series dtype over column slicing (?)

Operations
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

# helper declarations & functions

#generates default column labels
constant @alphi = 'A'..∞; 

# sorts Hash by value, returns keys (poor woman's Ordered Hash)
sub sbv( %h --> Seq ) is export(:ALL) {
    %h.sort(*.value).map(*.key)
}

role DataSlice does Positional does Iterable is export(:ALL) {
    has Str     $.name is rw = 'anon';
    has Any     @.data;
    has Int     %.index;

    ### Constructors ###

    # accept index as List, make Hash
    multi method new( List:D :$index, *%h ) {
        samewith( index => $index.map({ $_ => $++ }).Hash, |%h )
    }

    #### MAC Methods #####
    #Moves, Adds, Changes#

    #| get index as Array (ordered by %.index.values)
    multi method ix {
        %.index.&sbv
    }

    #| set (re)index from Array
    multi method ix( @new-index ) {
        %.index.keys.map: { %.index{$_}:delete };
        @new-index.map:   { %.index{$_} = $++  };
    }

    #| get self as Array of Pairs
    multi method aop {
        self.ix.map({ $_ => @.data[$++] })
    }

    #| set data and index from Array of Pairs
    multi method aop( @aop ) {
        self.ix:    @aop.map(*.key);
        self.data = @aop.map(*.value);
    }

    #| set empty data slots to Nan
    method fillna {
        my @emt := self.aop.grep(! *.value.defined).Array;
        @emt.map({ $_.value = NaN });
    }

    #| drop index and data when Nan
    method dropna {
        my @aok = self.aop.grep(*.value ne NaN).Array;
        self.aop: @aok
    }

    #| drop index and data when empty 
    method dropem {
        my @aok = self.aop.grep(*.value.defined).Array;
        self.aop: @aok
    }

    method splice( DataSlice:D: $start = 0, $elems?, *@replace ) {

        given @replace {
            when .first ~~ Pair {
                my @aop = self.aop;
                my @res = @aop.splice($start, $elems//*, @replace);
                self.aop: @aop;
                @res
            }
            default {
                my @res = @!data.splice($start, $elems//*, @replace); 
                self.fillna; 
                @res
            }
        }

#`[[
        my $new-start;
        given $start {
            when Callable     { $new-start = $new-start( self.elems ) }
            when Whatever     { $new-start = self.elems }
        }

        my $size = self.elems - $new-start;

        my $new-elems;
        given $elems {
            when Callable     { $new-elems = $new-elems( $size ) }
            when Whatever     { $new-elems = $size }
        }
#]]

        #@!data
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
}

role Series does DataSlice is export(:ALL) {
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
                    %.index{$p.key} = $++;
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

    ### Mezzanine methods ###  (these use Accessors)

    method count { 
        $.elems 
    }

    method mean {
        $.sum / $.elems 
    }

    method std {
        sqrt ( [+] $.data.map({ $^x - $.mean }).map({ $^x ** 2 }) / ( $.elems - 1 ) )
    }

    # fivenum code adapted from https://rosettacode.org/wiki/Fivenum#Raku
    sub fourths ( Int $end ) {
        my $end_22 = $end div 2 / 2;

        return 0, $end_22, $end/2, $end - $end_22, $end;
    }

    method fivenum {
        my @x = self.data.sort(+*)
            or die 'Input must have at least one element';

        my @d = fourths(@x.end);

        ( @x[@d».floor] Z+ @x[@d».ceiling] ) »/» 2
    }

    method describe {
        Series.new(
            :$.name,
            index => <count mean std min 25% 50% 75% max>,
            data => [$.count, $.mean, $.std, |@.fivenum],
        )
    }

    ### Outputs ###
    method str-attrs {
        %( :$.name, dtype => $!dtype.^name,)
    }
}

role Categorical is Series is export(:ALL) {
    # Output
    method dtype {
        Str.^name
    }
}

role DataFrame does Positional does Iterable is export(:ALL) {
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

            @!dtypes.push: @series[$i].dtype;

            my $key = @series[$i].name // @alphi[$i];
            %!columns{ $key } = $i;

            loop ( my $j=0; $j < $row-count; $j++ ) {
                @!data[$j;$i] = @series[$i][$j]                             #TODO := with BIND-POS
            }
        }
    }

    method load-from-slices( @slices ) {
        loop ( my $i=0; $i < @slices; $i++ ) {

            my $key = @slices[$i].name // ~$i;
            %!index{ $key } = $i;

            @!data[$i] := @slices[$i].data
        }
    }

    method TWEAK {
        given @!data.first {

            # data arg is 1d Array of Pairs (label => Series)
            when Pair {
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

            # data arg is 1d Array of Series (cols)
            when Series {
                die "columns.elems != data.first.elems" if ( %!columns && %!columns.elems != @!data.first.elems );

                my $row-count = @!data.first.elems;
                my @series = @!data; 

                # clear and load data (and columns)
                @!data = [];
                $.load-from-series: @series, $row-count;

                # make index Hash
                %!index = @series.first.index;
            }

            # data arg is 1d Array of DataSlice (rows)
            when DataSlice {
                my @slices = @!data; 

                # clear and load data (and index)
                @!data = [];
                $.load-from-slices: @slices;

                # make columns Hash
                %!columns = @slices.first.index;
            }

            # data arg is 2d Array (already) 
            default {
                die "columns.elems != data.first.elems" if ( %!columns && %!columns.elems != @!data.first.elems );

                if ! %!index {
                    [0..^@!data.elems].map( {%!index{$_.Str} = $_} );
                }
                if ! %!columns {
                    @alphi[0..^@!data.first.elems].map( {%!columns{$_} = $++} ).eager;
                    #eager @alphi[0..^@!data.first.elems].map( {%!columns{$_} = $++} );
                    #%!columns  #<== have to "touch" %!columns to avoid empty hash
                }
                #no-op
            } 
        }
    }

    #### MAC Methods #####
    #Moves, Adds, Changes#

    multi method ix {
        %!index.&sbv
    }

    multi method ix( @new-index ) {
        die "New index must be List with {%.index.elems} elems" unless @new-index.elems == %.index.elems;

        %.index.keys.map: { %.index{$_}:delete };
        @new-index.map:   { %.index{$_} = $++  };
    }

    multi method cx {
        %!columns.&sbv
    }

    multi method cx( @new-labels ) {
        die "New labels must be List with {%.columns.elems} elems" unless @new-labels.elems == %.columns.elems;

        %.columns.keys.map: { %.columns{$_}:delete };
        @new-labels.map:    { %.columns{$_} = $++  };
    }

    ### Mezzanine methods ###  (these use Accessors)

    method T {
        DataFrame.new( data => ([Z] @.data), index => %.columns, columns => %.index )
    }

    method series( $k ) {
        self.[*]{$k}
    }

    method sort( &cruton ) {  #&custom-routine-to-use
        my $i;
        loop ( $i=0; $i < @!data; $i++ ) {
            @!data[$i].push: %!index.&sbv[$i]
        }

        @!data .= sort: &cruton;
        %!index = %();

        loop ( $i=0; $i < @!data; $i++ ) {
            %!index{@!data[$i].pop} = $i
        }
        self
    }

    method grep( &cruton ) {  #&custom-routine-to-use
        my $i;
        loop ( $i=0; $i < @!data; $i++ ) {
            @!data[$i].push: %!index.&sbv[$i]
        }

        @!data .= grep: &cruton;
        %!index = %();

        loop ( $i=0; $i < @!data; $i++ ) {
            %!index{@!data[$i].pop} = $i
        }
        self
    }

    method describe {
        my @series = $.cx.map({ $.series: $_ });
        my @data = @series.map({ $_.describe }); 

        DataFrame.new( :@data )
    }

    ### Output methods ###

    method dtypes {
        my @labels = self.columns.&sbv;

        if ! @!dtypes {
            my @series = @labels.map({ self.series($_) });
              @!dtypes = @series.map({ ~$_.dtype });
        }

        gather {
            for @labels -> $k {
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
           @out-rows.map({ 
                $_ .= Array; 
                $_.unshift: @row-hdrs.shift
            });

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

### Postfix '^' as explicit subscript chain terminator
multi postfix:<^>( DataSlice @ds ) is export(:ALL) {
    DataFrame.new(@ds) 
}
multi postfix:<^>( DataSlice $ds ) is export(:ALL) {
    DataFrame.new(($ds,)) 
}

### Override first subscript [i] to make DataSlices (rows)

#| provides single DataSlice which can be [j] subscripted directly to value 
multi postcircumfix:<[ ]>( DataFrame:D $df, Int $p ) is export(:ALL) {
    DataSlice.new( data => $df.data[$p;*], index => $df.columns, name => $df.index.&sbv[$p] )
}

# helper
sub make-aods( $df, @s ) {
    my DataSlice @ = @s.map({
        DataSlice.new( data => $df.data[$_;*], index => $df.columns, name => $df.index.&sbv[$_] )
    })
}

#| slices make Array of DataSlice objects
multi postcircumfix:<[ ]>( DataFrame:D $df, @s where Range|List ) is export(:ALL) {
    make-aods( $df, @s )
}
multi postcircumfix:<[ ]>( DataFrame:D $df, WhateverCode $p ) is export(:ALL) {
    my @s = $p( |($df.elems xx $p.arity) );
    make-aods( $df, @s )
}
multi postcircumfix:<[ ]>( DataFrame:D $df, Whatever ) is export(:ALL) {
    my @s = 0..^$df.elems; 
    make-aods( $df, @s )
}


### Override second subscript [j] to make DataFrame

# helper
sub sliced-slices( @aods, @s ) {
    gather {
        @aods.map({ take DataSlice.new( data => $_[@s], index => $_.index.&sbv[@s], name => $_.name )}) 
    }   
}
sub make-series( @sls ) {
    my @data  = @sls.map({ $_.data[0] });
    my @index = @sls.map({ $_.name[0] });
    my $name  = @sls.first.index.&sbv[0];

    Series.new( :@data, :@index, :$name )
}

#| provides single Series which can be [j] subscripted directly to value 
multi postcircumfix:<[ ]>( DataSlice @aods , Int $p ) is export(:ALL) {
    make-series( sliced-slices(@aods, ($p,)) )
}

#| make DataFrame from sliced DataSlices 
multi postcircumfix:<[ ]>( DataSlice @aods , @s where Range|List ) is export(:ALL) {
    DataFrame.new( sliced-slices(@aods, @s) )
}
multi postcircumfix:<[ ]>( DataSlice @aods, WhateverCode $p ) is export(:ALL) {
    my @s = $p( |(@aods.first.elems xx $p.arity) );
    DataFrame.new( sliced-slices(@aods, @s) )
}
multi postcircumfix:<[ ]>( DataSlice @aods, Whatever ) is export(:ALL) {
    my @s = 0..^@aods.first.elems;
    DataFrame.new( sliced-slices(@aods, @s) )
}

### Override first assoc subscript {i}

multi postcircumfix:<{ }>( DataFrame:D $df, $k ) is export(:ALL) {
    $df[$df.index{$k}]
}
multi postcircumfix:<{ }>( DataFrame:D $df, @ks ) is export(:ALL) {
    $df[$df.index{@ks}]
}

### Override second subscript [j] to make DataFrame

multi postcircumfix:<{ }>( DataSlice @aods , $k ) is export(:ALL) {
    my $p = @aods.first.index{$k};
    make-series( sliced-slices(@aods, ($p,)) )
}
multi postcircumfix:<{ }>( DataSlice @aods , @ks ) is export(:ALL) {
    my @s = @aods.first.index{@ks};
    DataFrame.new( sliced-slices(@aods, @s) )
}

#EOF

