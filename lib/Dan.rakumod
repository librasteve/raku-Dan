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
- Dan::Pandas spike 
- Array MACs 
-- ix,cx (for reindex)
-- splice (for drop, assign, append, push, pop, shift, unshift)
- Missing data
-- fillna, dropna, dropem
- Concat 
-- concat (for join [outer|inner|left|right], merge)
- Shape (just simple)
^^^ done

v2 Backlog 
(much of this is test / synopsis examples / new mezzanine methods)
- Set style ops
-- expose series eg. df.A, etc
-- see notes
- Combine
-- .splice ok
- Apply?
-- .map ok 
- Duplicate labels?
-- don't support, need to detect and error
- Index alignment?
-- just an outer concat with fillna
- String ops?
-- .map ok (regex example)
- Merge & Join?
-- .concat ok
- Column sort
-- splice ok
- Exceptions
- Stats
- Histogramming
- SQL style ops
-- Group by
- Reshaping (stacking)
- Pivot tables
- Time Series
- Categoricals (Enums)
- Plotting

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

# set mark for index/column duplicates
constant $mark = '⋅'; # unicode Dot Operator U+22C5
my regex notmark { <-[⋅]> }

# generates default column labels
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

    #| splice as Array of values or Array of Pairs
    #| viz. https://docs.raku.org/routine/splice
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
    }

    #| set empty data slots to Nan
    method fillna {
        self.aop.grep(! *.value.defined).map({ $_.value = NaN });
    }

    #| drop index and data when Nan
    method dropna {
        self.aop: self.aop.grep(*.value ne NaN);
    }

    #| drop index and data when empty 
    method dropem {
        self.aop: self.aop.grep(*.value.defined).Array;
    }

    # concat
    method concat( DataSlice:D $dsr ) {
        self.index.map({ 
            if $dsr.index{$_.key}:exists {
                warn "duplicate key {$_.key} not permitted" 
            } 
        });

        my $start = self.index.elems;
        my $elems = $dsr.index.elems;
        my @replace = $dsr.aop;

        self.splice: $start, $elems, @replace;    
        self
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

#| Series is a shim on DataSlice to mix in dtype and legacy constructors
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

    # provide ^name of type object eg. for output
    multi method dtype {
        $!dtype.^name       
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
    method load-from-series( :$row-count, *@series ) {
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
                $.load-from-series: row-count => +@index, |@series;

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
                $.load-from-series: :$row-count, |@series;

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
                }
                #no-op
            } 
        }
    }

    #### MAC Methods #####
    #Moves, Adds, Changes#

    #| get index as Array (ordered by %.index.values)
    multi method ix {
        %!index.&sbv
    }

    #| set (re)index from Array
    multi method ix( @new-index ) {
        %.index.keys.map: { %.index{$_}:delete };
        @new-index.map:   { %.index{$_} = $++  };
    }

    #| get columns as Array (ordered by %.column.values)
    multi method cx {
        %!columns.&sbv
    }

    #| set columns (relabel) from Array
    multi method cx( @new-labels ) {
        %.columns.keys.map: { %.columns{$_}:delete };
        @new-labels.map:    { %.columns{$_} = $++  };
    }

    ### Splicing ###

    #| reset attributes
    method reset( :$axis ) {

        @!data = [];

        if ! $axis {
            %!index = %()
        } else {
            @!dtypes  = [];
            %!columns = %()
        }
    }

    #| get as Array or Array of Pairs - [index|columns =>] DataSlice|Series
    method get-ap( :$axis, :$pair ) {
        given $axis, $pair {
            when 0, 0 {
                self.[*]
            }
            when 0, 1 {
                my @slices = self.[*];
                self.ix.map({ $_ => @slices[$++] })
            }
            when 1, 0 {
                self.cx.map({self.series($_)}).Array
            }
            when 1, 1 {
                my @series = self.cx.map({self.series($_)}).Array;
                self.cx.map({ $_ => @series[$++] })
            }
        }
    }

    #| set from Array or Array of Pairs - [index|columns =>] DataSlice|Series
    method set-ap( :$axis, :$pair, *@set ) {

        self.reset: :$axis;

        given $axis, $pair {
            when 0, 0 {                         # row - array
                self.load-from-slices: @set
            }
            when 0, 1 {                         # row - aops 
                self.load-from-slices: @set.map(*.value);
                self.ix: @set.map(*.key)
            }
            when 1, 0 {                         # col - array
                self.load-from-series: row-count => @set.first.elems, |@set
            }
            when 1, 1 {                         # col - aops
                self.load-from-series: row-count => @set.first.value.elems, |@set.map(*.value);
                self.cx: @set.map(*.key)
            }
        }
    }

    sub clean-axis( :$axis ) {
        given $axis {
            when ! .so || /row/ { 0 }
            when   .so || /col/ { 1 }
        }
    }

    #| splice as Array or Array of Pairs - [index|columns =>] DataSlice|Series
    #| viz. https://docs.raku.org/routine/splice
    method splice( DataFrame:D: $start = 0, $elems?, :ax(:$axis) is copy, *@replace ) {

        $axis = clean-axis(:$axis);

        my $pair = @replace.first ~~ Pair ?? 1 !! 0;
        my @wip = self.get-ap: :$axis, :$pair;
        my @res = @wip.splice: $start, $elems//*, @replace;
                  self.set-ap: :$axis, :$pair, @wip;

        @res
    }

    # concat
    method concat( DataFrame:D $dfr, :ax(:$axis) is copy,           #TODO - refactor for speed?   
                     :jn(:$join) = 'outer', :ii(:$ignore-index) ) {

        $axis = clean-axis(:$axis);
        my $ax = ! $axis;        #AX IS INVERSE AXIS

        my ( $start,   $elems   );
        my ( @left,    @right   );
        my ( $l-empty, $r-empty );
        my ( %l-drops, %r-drops );

        if ! $axis {            # row-wise

            # set extent of main slice 
            $start = self.index.elems;
            $elems = $dfr.index.elems;

            # take stock of cols
            @left   = self.cx;
            @right  = $dfr.cx;

            # make some empties
            $l-empty = Series.new( NaN, index => [self.ix] );
            $r-empty = Series.new( NaN, index => [$dfr.ix] );

            # load drop hashes
            %l-drops = self.columns;
            %r-drops = $dfr.columns;

        } else {                # col-wise

            # set extent of main slice
            $start = self.columns.elems;
            $elems = $dfr.columns.elems;

            # take stock of rows
            @left   = self.ix;
            @right  = $dfr.ix;

            # make some empties
            $l-empty = DataSlice.new( data => [NaN xx self.cx.elems], index => [self.cx] );
            $r-empty = DataSlice.new( data => [NaN xx $dfr.cx.elems], index => [$dfr.cx] );

            # load drop hashes
            %l-drops = self.index;
            %r-drops = $dfr.index;

        }

        my @inner  = @left.grep(  * ∈ @right );
        my @l-only = @left.grep(  * ∉ @inner );
        my @r-only = @right.grep( * ∉ @inner );
        my @outer  = |@l-only, |@r-only;

        # helper functions for adjusting columns

        sub add-ronly-to-left {
            for @r-only -> $name {
                self.splice: :$ax, *, *, ($name => $l-empty)
            }
        }
        sub add-lonly-to-right {
            for @l-only -> $name {
                $dfr.splice: :$ax, *, *, ($name => $r-empty)
            }
        }
        sub drop-outers-from-left {
            for @l-only -> $name {
                self.splice: :$ax, %l-drops{$name}, 1
            }
        }
        sub drop-outers-from-right {
            for @r-only -> $name {
                $dfr.splice: :$ax, %r-drops{$name}, 1
            }
        }

        # re-arrange left and right 
        given $join {
            when /^o/ {          #outer
                add-ronly-to-left;
                add-lonly-to-right;
            }
            when /^i/ {          #inner
                drop-outers-from-left;
                drop-outers-from-right;
            }
            when /^l/ {          #left
                add-lonly-to-right;
                drop-outers-from-right;
            }
            when /^r/ {          #right
                add-ronly-to-left;
                drop-outers-from-left;
            }
        }

        # load new row/col info
        my ( @new-left, @new-right );
        my ( %new-left, %new-right );

        if ! $axis {    #row-wise
            @new-left  = self.cx;       @new-right = $dfr.cx;
            %new-left  = self.columns;  %new-right = $dfr.columns;
        } else {        #column-wise
            @new-left  = self.ix;       @new-right = $dfr.ix;
            %new-left  = self.index;    %new-right = $dfr.index;
        }

        # align new right to new left
        for 0..^+@new-left -> $i {
            if @new-left[$i] ne @new-right[$i] {
                my @mover = $dfr.splice: :$ax, %new-right{@new-left[$i]}, 1; 
                $dfr.splice: :$ax, $i, 0, @mover; 
            }
        }

        # load name duplicates
        my $dupes = ().BagHash;
        my ( @new-main, %new-main );

        if ! $axis {    #row-wise
            @new-main = self.ix;
            %new-main = self.index;
        } else {        #column-wise
            @new-main = self.cx;
            %new-main = self.columns;
        }

        @new-main.map({ $_ ~~ / ^ (<notmark>*) /; $dupes.add(~$0) }); 

        # load @replace as array of pairs
        my @replace = $dfr.get-ap( :$axis, pair => 1 );

        # handle name duplicates
        @replace.map({ 
            if %new-main{$_.key}:exists {
                #warn "duplicate key {$_.key}";

                $_.key ~~ / ^ (<notmark>*) /;
                my $b-key = ~$0;
                my $n-key = $b-key ~ $mark ~ $dupes{$b-key};

                $_ = $n-key => $_.value; 
                $dupes{$b-key}++;
            } 
        });

        # do the main splice
        self.splice: :$axis, $start, $elems, @replace;    

        # handle ignore-index
        if $ignore-index {
            if ! $axis {
                my $size = self.ix.elems;
                self.index = %();
                self.index{~$_} = $_ for 0..^$size
            } else {
                my $size = self.cx.elems;
                self.columns = %();
                self.columns{~$_} = $_ for 0..^$size
            }
        } 

        self
    }

    ### Mezzanine methods ###  
    # (these use Accessors) #

    method fillna {
        self.map(*.map({ $_ //= NaN }).eager);
    }

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

    method shape {
        self.ix.elems, self.cx.elems
    }

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

