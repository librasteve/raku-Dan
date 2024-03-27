[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)
[![raku-dan:latest -> DH](https://github.com/librasteve/raku-Dan/actions/workflows/dan-weekly.yaml/badge.svg)](https://github.com/librasteve/raku-Dan/actions/workflows/dan-weekly.yaml)

*THIS MODULE IS EXPERIMENTAL AND SUBJECT TO CHANGE WITHOUT NOITCE*

# raku Dan
Top level raku **D**ata **AN**alysis Module that provides **a base set of raku-style** datatype roles, accessors & methods, primarily:
- Series
- DataFrames

A common basis for bindings such as ... [Dan::Pandas](https://github.com/librasteve/raku-Dan-Pandas) (via Inline::Python), [Dan::Polars](https://github.com/librasteve/raku-Dan-Polars) (via NativeCall / Rust FFI), etc.

It's rather a zen concept since raku contains many Data Analysis constructs & concepts natively anyway (see note 7 below)

Contributions via PR are very welcome - please see the backlog Issue, or just email librasteve@furnival.net to share ideas!

# INSTALLATION
```
zef install Dan;
```

# SYNOPSIS
more examples in [bin/synopsis.raku](https://github.com/librasteve/raku-Dan/blob/main/bin/synopsis-dan.raku)
```raku
use Dan :ALL;

### Series ###

my \s = Series.new( [b=>1, a=>0, c=>2] );               #from Array of Pairs
#  -or- Series.new( [rand xx 5], index => <a b c d e>);
#  -or- Series.new( data => [1, 3, 5, NaN, 6, 8], index => <a b c d e f>, name => 'john' );
say ~s;

# Accessors
say s[1];           #2   (positional)
say s<b c>;         #2 1 (associative with slice)

# Map/Reduce
say s.map(*+2);     #(3 2 4)
say [+] s;          #3  

# Hyper
say s >>+>> 2;      #(3 2 4)
say s >>+<< s;      #(2 0 4)

# Update
s.data[1] = 1;            # set value
s.splice(1,2,(j=>3));     # update index & value

# Combine
my \t = Series.new( [f=>1, e=>0, d=>2] );
s.concat: t;              # concatenate

say "=============================================";

### DataFrames ###

my \dates = (Date.new("2022-01-01"), *+1 ... *)[^6];
my \df = DataFrame.new( [[rand xx 4] xx 6], index => dates, columns => <A B C D> );
#  -or- DataFrame.new( [rand xx 5], columns => <A B C D>);
#  -or- DataFrame.new( [rand xx 5] );
say ~df;

say "---------------------------------------------";

# Data Accessors [row;col]
say df[0;0];
df[0;0] = 3;                # set value

# Cascading Accessors (ok to mix Positional and Associative)
say df[0][0];
say df[0]<A>;
say df{"2022-01-03"}[1];

# Object Accessors & Slices (see note 1)
say ~df[0];                 # 1d Row 0 (DataSlice)
say ~df[*]<A>;              # 1d Col A (Series)
say ~df[0..*-2][1..*-1];    # 2d DataFrame
say ~df{dates[0..1]}^;      # the ^ postfix converts an Array of DataSlices into a new DataFrame

say "---------------------------------------------";

### DataFrame Operations ###

# 2d Map/Reduce
say df.map(*.map(*+2).eager);
say [+] df[*;1];
say [+] df[*;*];

# Hyper
say df >>+>> 2;
say df >>+<< df;

# Transpose
say ~df.T;

# Describe
say ~df[0..^3]^;            # head
say ~df[(*-3..*-1)]^;       # tail
say ~df.shape;
say ~df.describe;

# Sort
say ~df.sort: { .[1] };         # sort by 2nd col (ascending)
say ~df.sort: { -.[1] };        # sort by 2nd col (descending)
say ~df.sort: { df[$++]<C> };   # sort by col C
say ~df.sort: { df.ix[$++] };   # sort by index

# Grep (binary filter)
say ~df.grep( { .[1] < 0.5 } );                                # by 2nd column 
say ~df.grep( { df.ix[$++] eq <2022-01-02 2022-01-06>.any } ); # by index (multiple) 

say "---------------------------------------------";

my \df2 = DataFrame.new([
        A => 1.0,
        B => Date.new("2022-01-01"),
        C => Series.new(1, index => [0..^4], dtype => Num),
        D => [3 xx 4],
        E => Categorical.new(<test train test train>),
        F => "foo",
]);
say ~df2;
say df2.data;
say df2.dtypes;
say df2.index;    #Hash (name => row number)   -or- df.ix; #Array
say df2.columns;  #Hash (label => col number)  -or- df.cx; #Array

say "---------------------------------------------";

### DataFrame Splicing ### (see notes 2 & 3)

# row-wise splice:
my $ds = df2[1];                        # get a DataSlice 
$ds.splice($ds.index<d>,1,7);           # tweak it a bit
df2.splice( 1, 2, [j => $ds] );         # default

# column-wise splice:
my $se = df2.series: <a>;               # get a Series 
$se.splice(2,1,7);                      # tweak it a bit
df2.splice( :ax, 1, 2, [K => $se] );    # axis => 1

say "---------------------------------------------";

### DataFrame Concatenation ### (see notes 4 & 5)

my \dfa = DataFrame.new(
        [['a', 1], ['b', 2]],
        columns => <letter number>,
);
#`[
    letter  number
 0  a       1
 1  b       2
#]

my \dfc = DataFrame.new(
        [['c', 3, 'cat'], ['d', 4, 'dog']],
        columns => <animal letter number>,
);
#`[
    letter  number  animal
 0  c       3       cat 
 1  d       4       dog 
#]

dfa.concat: dfc;        # row-wise / outer join is default
#`[
       letter  number  animal
 0    a       1       NaN 
 1    b       2       NaN 
 0⋅1  c       3       cat 
 1⋅1  d       4       dog 
#]

dfa.concat: dfc, join => 'inner';
#`[
      letter  number
 0    a       1
 1    b       2
 0⋅1  c       3
 1⋅1  d       4
#]

my \dfd = DataFrame.new( [['bird', 'polly'], ['monkey', 'george']],
                         columns=> <animal name>,                   );

dfa.concat: dfd, axis => 1;             #column-wise
#`[
    letter  number  animal  name
 0  a       1       bird    polly
 1  b       2       monkey  george
#]

say "=============================================";
```

Notes:

[1] raku accessors may use any function that makes a List, e.g.

Positional slices: ```[1,3,4], [0..3], [0..*-2], [*]```

Associative slices: ```<A C D>, {'A'..'C'}```
        
viz. https://docs.raku.org/language/subscripts
        
[2] splice is the core update method 
        
for all add, drop, move, delete, update & insert operations 
        
viz. https://docs.raku.org/routine/splice

[3] named parameter 'axis' indicates if row(0) or col(1)
        
if omitted, default=0 (row) / 'ax' is an alias
        
use a Pair literal like ```:!axis, :axis(1) or :ax```

[4] concat is the core combine method 

for all join, merge & combine operations

duplicate labels are extended with ```$mark ~ $i++```

```# $mark = '⋅'; # unicode Dot Operator U+22C5```

use ```:ii (:ignore-index)``` to reset the index (row or col)

[5] concat supports ```join => outer|inner|right|left```

unknown values are set to NaN

default is outer, :jn is alias, and you can go :jn<r> on first letter

set axis param (see splice above) for col-wise concatenation

[6] relies on hypers instead of overriding dyadic operators [+-*/]

```raku
say ~my \quants = Series.new([100, 15, 50, 15, 25]);
say ~my \prices = Series.new([1.1, 4.3, 2.2, 7.41, 2.89]); 
say ~my \costs  = Series.new( quants >>*<< prices );
```
        
[7] what are we getting from raku core that others do in libraries?
- pipes & maps
- multi-dimensional arrays
- slicing & indexing
- references & views
- map, reduce, hyper operators
- operator overloading
- concurrency
- types (incl. NaN)

copyright(c) 2022-2024 Henley Cloud Consulting Ltd.
        
