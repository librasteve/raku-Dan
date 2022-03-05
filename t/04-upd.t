#!/usr/bin/env raku
#t/04.upd.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
#plan 25;

use Dan :ALL;

## Series - Updates

my \s = Series.new([b=>1, a=>0, c=>2]);
s.ix: <b c d>;
is ~s, "b\t1\nc\t0\nd\t2\ndtype: Int, name: anon\n",                        's.ix';

## DataFrames - Updates 

my \df2 = DataFrame.new([
        A => 1.0,
        B => Date.new("2022-01-01"),
        C => Series.new(1, index => [0..^4], dtype => Num),
        D => [3 xx 4],
        E => Categorical.new(<test train test train>),
        F => "foo",
]);

df2.ix: <a b c d>;
is df2.index, "a\t0\nb\t1\nc\t2\nd\t3",                                            'df.ix';

df2.cx: <a b c d e f>;
is df2.dtypes, "a => Rat\nb => Date\nc => Num\nd => Int\ne => Str\nf => Str",      'df.cx';

#`[[[
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
#]]]

done-testing;
