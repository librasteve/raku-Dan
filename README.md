**Very much a work in progress - contributions very welcome!**

# raku Dan
Top level raku **D**ata **AN**alysis Module

The initial focus is a minimal set of datatype roles:
- Dan::DataSlices
- Dan::Series
- Dan::DataFrames

These roles provide a common raku presentation for Data Analytic, Numeric & Scientific bindings...
- Dan::Pandas  - binding to pandas via Inline::Python
- Dan::Polars  - binding to polars via Rust FFI
- Dan::Paddle  - binding to Perl(5) Data Language using Inline::Perl5
- NumRa
- SciRa
- [to my knowledge none of this exists yet]

raku Dan is rather a zen concept since:
- raku contains many Data Analysis constructs & concepts natively anyway
- it's a stub for future high-performance, native implementations

So what are we getting from raku core that others do in libraries?
- pipes & maps
- multi-dimensional arrays
- slicing & indexing
- references & views
- map, reduce, hyper operators
- operator overloading
- concurrency

# SYNOPOSIS

```raku
### Series ###

my \s = $;    

s = Series.new( data => [1, 3, 5, NaN, 6, 8], index => <a b c d e f>, name => 'john' );
#   -or-
s = Series.new( [rand xx 5], index => <a b c d e>);
#   -or-
s = Series.new( [b=>1, a=>0, c=>2] );               #from Array of Pairs

say ~s; 
say "---------------------------------------------";

# Accessors
say s[1];           #2   (positional)
say s<b c>;         #2 1 (associative with slice)

# Map/Reduce
say s.map(*+2);     #(3 2 4)
say [+] s;          #3  

# Hyper
say s >>+>> 2;      #(3 2 4)
say s >>+<< s;      #(2 0 4)

say "=============================================";

### DataFrames ###

my \dates = (Date.new("2022-01-01"), *+1 ... *)[^6];
my \df = DataFrame.new( [[rand xx 4] xx 6], index => dates, columns => <A B C D> );

say ~df;
say "---------------------------------------------";

# Value Accessors
say df[0][0];
say df[0]<A>;
say df{dates[0]}[0];
say df{dates[0]}<A>;
say df[0][*];               #1d Row 0 (Values)

# Object Accessors
say ~df[0];                 #1d Row 0 (DataSlice)
say ~df[*]<A>;              #1d Col A (Series)
say ~df[0..*-2][1..*-1];    #2d DataFrame

# raku accessors use any function that makes a List, e.g.
# Positional slices: [1,3,4], [0..3], [0..*-2], [*]
# Associative slices: <A C D>, {'A'..'C'}
# viz. https://docs.raku.org/language/subscripts

# Taking a row slice makes an Array of DataSlices
# the ^ postfix converts them into a new DataFrame
say ~df{dates[0..1]}^;    

say "=============================================";

### DataFrame Operations ###

# 2d Map/Reduce
say df.map(*.map(*+2));
say [+] df[*][1];
say [+] df[*][*];
say ~df.T;                  #Transpose

# Hyper
say df >>+>> 2;
say df >>+<< df;

# Head & Tail
say ~df[0..^3]^;            # head
say ~df[(*-3..*-1)]^;       # tail

# Describe
say ~df[*]<A>.describe;
say ~df.describe;

# Sort
#viz. https://docs.raku.org/routine/sort#(List)_routine_sort

say ~df.sort: { .[1] };         # sort by 2nd col (ascending)
say ~df.sort: { .[1], .[2] };   # sort by 2nd col, then 3rd col (and so on)
say ~df.sort: { -.[1] };        # sort by 2nd col (descending)
say ~df.sort: { df[$++]<C> };   # sort by col C
say ~df.sort: { df.ix[$++] };   # sort by index
say ~df.sort: { df.ix.reverse.[$++] };   # sort by index (descending)

# Grep
# global replace binary filter
# works on data "in place" - so make a copy first if you need to keep all the data
say ~df.grep( { .[1] < 0.5 } ); # grep by 2nd column 
say ~df.grep( { df.ix[$++] eq <2022-01-02 2022-01-06>.any } ); # grep index (multiple) 

say "=============================================";

my \df2 = DataFrame.new([
        A => 1.0,
        B => Date.new("2022-01-01"),
        C => Series.new(1, index => [0..^4], dtype => Num),
        D => [3 xx 4],
        E => Categorical.new(<test train test train>),
        F => "foo",
]);

say ~df2;
say "---------------------------------------------";
say df2.data;
say df2.index;
say df2.columns;
say df2.dtypes;
say "=============================================";
```
