#!/usr/bin/env raku
#t/03.dfo.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
plan 26;

use Dan :ALL;

## DataFrames - Operations

my \dates = (Date.new("2022-01-01"), *+1 ... *)[^6];    #say dates;
my \df = DataFrame.new( [[0..3] xx 6], index => dates, columns => <A B C D> );

# Math
ok df.map(*.map(*+2)) == ((2,3,4,5),(2,3,4,5),(2,3,4,5),(2,3,4,5),(2,3,4,5),(2,3,4,5)), '.map.map';
ok df[1].map(*+3) == (3,4,5,6),                                                         '.[1].map';
ok df[1][1,2].map(*+3) == (4,5),                                                        '.[1][1,2].map';
ok ([+] df[1;*]) == 6,                                                                  '[+] df[1;*]';
ok ([+] df[*;1]) == 6,                                                                  '[+] df[*;1]';
ok ([+] df[*;*]) == 36,                                                                 '[+] df[*;*]';
ok ([Z] @ = df) == ((0,0,0,0,0,0),(1,1,1,1,1,1),(2,2,2,2,2,2),(3,3,3,3,3,3)),           '[Z] @=df';
ok ([Z] df.data) == ((0,0,0,0,0,0),(1,1,1,1,1,1),(2,2,2,2,2,2),(3,3,3,3,3,3)),          '[Z] df.data';
ok df.T eq DataFrame.new( data => ([Z] df.data), index => df.columns, columns => df.index ), 'df.T';

# Hyper
ok (df >>+>> 2)[1;1] == 3,                                                              'df >>+>> 2';
ok (df >>+<< df)[1;1] ==2,                                                              'df >>+<< df'; 

# Head & Tail
ok df[0..^3]^[1;1] == 1,                                                                '.head';
ok df[(*-3..*-1)]^[1;1] == 1,                                                           '.tail';

# Describe
ok df[*]<A>.describe<count> == 6,                                                       's.describe';
ok df.describe<count><A> == 6,                                                          'df.describe';

# Sort
#viz. https://docs.raku.org/routine/sort#(List)_routine_sort

ok (df.sort: { .[1] })[1][1] == 1,                                                      '.sort: {.[1]}';
ok (df.sort: { .[1], .[2] })[1][1] == 1,                                                '.sort: {.[1],.[2]}';
ok (df.sort: { -.[1] })[1][1] == 1,                                                     '.sort: {-.[1]}';
ok (df.sort: { df[$++]<C> })[1][1] ==1,                                                 '.sort: {df[$++]<C>}';
ok (df.sort: { df.ix[$++] })[1][1] ==1,                                                 '.sort: {df.ix[$++]}';
ok (df.sort: { df.ix.reverse.[$++] })[1][1] == 1,                               '.sort: {df.ix.reverse.[$++]}';

# Grep MOVE TO END AS DESTRUCTIVE
is ~df.grep( { .[1] < 0.5 } ), "   A  B  C  D ",                                        '.grep: {.[1] < 0.5}';
is ~df.grep( { df.ix[$++] eq <2022-01-02 2022-01-06>.any } ), "   A  B  C  D ",         '.grep index (multiple)';

my \df2 = DataFrame.new([
        A => 1.0,
        B => Date.new("2022-01-01"),
        C => Series.new(1, index => [0..^4], dtype => Num),
        D => [3 xx 4],
        E => Categorical.new(<test train test train>),
        F => "foo",
]);
ok df2.columns.elems == 6,                                                              '.columns';
is df2.dtypes, "A => Rat\nB => Date\nC => Num\nD => Int\nE => Str\nF => Str",           '.dtypes';

is df2.shape, "4 6",                                                                  '.shape';

#done-testing;
