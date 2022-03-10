#!/usr/bin/env raku
use lib '../lib';
use Dan;

#SYNOPSIS

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

# Updates

# splice is the core method for all add, drop,
# move, delete, update & insert operations 
# viz. https://docs.raku.org/routine/splice
s.ix: <b c d>;      #re-index
s.splice: *-1;      #pop
s.splice(1,2,3);      #$start, $elems, *@replace
s.splice(1,2,(j=>3)); #update index & value
s.fillna;           #fill NaN if undef 
s.dropna;           #drop NaN elements 

# concat is the core method for all join,
# merge & combine operations
my \t = Series.new( [f=>1, e=>0, d=>2] );
s.concat: t;        #concatenate

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
say ~df.T;                  # Transpose

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
# works on data "in place" - make a copy first if you need to keep it 
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

### DataFrame Updates ###

df2.ix: <a b c d>;      # re-index
df2.cx: <a b c d e f>;  # re-label

# splice is the core method for all add, drop,
# move, delete, update & insert operations 
# viz. https://docs.raku.org/routine/splice
# 
# named param 'axis' indicates if row(0) or col(1)
# if omitted, default=0 (row) / 'ax' is an alias
# use a Pair literal like :!axis, :axis(1) or :ax 

# prep DataSlice 
my $ds := df2[1];                       
$ds.splice($ds.index<D>,1,7);

# splice rows
$ds.name = 'j';                         #new index from ds.name
df2.splice( :!axis, 2, 1, $ds );        #$start, $elems, *@replace
#-or-
df2.splice( 1, 2, (j => $ds) );         #new index from Pair(s)

# prep Series 
my $se = df2.series: <A>;               
$se.splice(2,1,7);

# splice on cols 
$se.name = 'K';                         #new column label from se.name 
df2.splice( (axis => 1), 3, 2, $se);    #$start, $elems, *@replace
#-or-
df2.splice( :ax, 1, 2, (K => $se) );    #new column label from Pairs

say "=============================================";

### DataFrame Concatenation ###







# concat is the core method for all join,
# merge & combine operations
my \t = Series.new( [f=>1, e=>0, d=>2] );
s.concat: t;        #concatenate






