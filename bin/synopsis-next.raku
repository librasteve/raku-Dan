#!/usr/bin/env raku
use lib '../lib';
use Dan :ALL;

#SYNOPSIS

### Series ###

my \s = $;    

s = Series.new( data => [1, 3, 5, NaN, 6, 8], index => <a b c d e f>, name => 'john' );
#   -or-
s = Series.new( [rand xx 5], index => <a b c d e>);
#   -or-
s = Series.new( [b=>1, a=>0, c=>2] );               #from Array of Pairs

#`[[
s.ix: <b c d>;

s.splice: *-1;
s.splice(1,2,3);
s.splice( 1,2,(j => Nil) );
s.fillna;
s.dropna;
say ~s; 
say s.ix[1];

#nb must use splice to assign, delete
#]]

#`[[ concat
#say ~s.concat: s;

s = Series.new( [b=>1, a=>0, c=>2] );               #from Array of Pairs
say my \t = Series.new( [f=>1, e=>0, d=>2] );
say ~(s.concat: t).ix[3];
die;
#]]

#`[[[
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
#]]]

my \df2 = DataFrame.new([
        A => 1.0,
        B => Date.new("2022-01-01"),
        C => Series.new(1, index => [0..^4], dtype => Num),
        D => [3 xx 4],
        E => Categorical.new(<test train test train>),
        F => "foo",
]);
#say ~df2; 

#`[[
# Array of objects (DataSlice|Series) uses object .name 
# Array of Pairs uses Pair .key for index / columns
# raku Dan does not support duplicate keys (need an error)

my $mode = 
#pop';
#'array';
'pair';

#rows
my $ds = df2[1];
$ds.splice($ds.index<D>,1,7); #same as $ds.splice(4,1,7);
$ds.name = '7';

df2.splice: *-1                            if $mode eq 'pop';    #[[1 2022-01-01 1 3 train foo]]
df2.splice( 2,1,$ds )                      if $mode eq'array';
df2.splice( axis => 'row',1,2,(j => $ds,) ) if $mode eq 'pair';
say ~df2;

#cols
my $se = df2.series: <A>;
$se.name = 'X';
$se.splice(2,1,7);

df2.splice: :ax(1), *-1                    if $mode eq 'pop'; #[Dan::Series.new(dtype => Str, name => "F", ... ]
#iamerejh (pop tests)
df2.splice( :ax(1),3,2,$se)                if $mode eq 'array';
df2.splice( :ax<column>,1,2,(K => $se,) )  if $mode eq 'pair';

df2[0;0] = Nil;
df2.fillna;
say ~df2;
#]]

#[[
my \dfa = DataFrame.new(
        [['a', 1], ['b', 2]],
        columns => <letter number>,
);
say ~dfa;
#[[[
my \dfb = DataFrame.new(
        [['c', 3], ['d', 4]],
        columns => <letter number>,
);
#say ~dfb;
#]]]

#`[[[
say ~dfb;
dfa.concat: dfb;
#dfa.concat: dfa, :ii;
say ~dfa;
#]]]

#`[[[ #switch cols
my \dfb = DataFrame.new(
        [['c', 3], ['d', 4]],
        columns => <number letter>,
);
say ~dfb;
my @se = dfb.splice(:ax, dfb.columns<letter>, 1);
dfb.splice(:ax,0,0,@se);                #note :ax and 0,0
say ~dfb;
#]]]

#[[[
my \dfc = DataFrame.new(
        [['c', 3, 'cat'], ['d', 4, 'dog']],
        columns => <letter number animal>,
);
        #columns => <animal letter number>,
say ~dfc;

#dfa.concat: dfc, join => 'inner';
dfa.concat: dfc, :jn<r>;
#dfa.concat: dfc;
say ~ dfa;
#]]]

die;
#`[[[
#sort cols
for dfc.columns.sort.map(*.value) {
    my @mover = dfc.splice: :ax, $_;            #splice out mover Series
    dfc.splice: :ax, $++, 0, @mover;            #splice back in sequence
}
say ~dfc;
#]]]

my \dfd = DataFrame.new([['bird', 'polly'], ['monkey', 'george']],
                          columns=> <animal name>                );
say ~dfd;

dfa.concat: dfd, axis => 1;
say ~dfa;

say dfa.shape;

#combine

#get operand Series and leaving originals in place
my ($a, $b)  = <animal name>.map({ dfd.series($_) }); 

#or splice them out (splices return arrays, we just want the first item)
#my ($a, $b)  = <animal name>.map({ dfd.splice(:ax, dfd.columns{$_}, 1).first }); 

#use hyper operators to combine as new Series, and splice back in as named pair 
my $combo = Series.new( $a >>~<< $b );
dfd.splice: :ax, 0, 0, (:$combo);            

say ~dfd;

#]]

#`[[[
df2.ix: <a b c d>;
say ~df2; 
df2.cx: <a b c d e f>;
say ~df2; 

say "---------------------------------------------";
say df2.data;
say df2.index;
say df2.columns;
say df2.dtypes;
say "=============================================";
#]]]
