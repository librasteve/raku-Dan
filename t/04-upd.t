#!/usr/bin/env raku
#t/04.upd.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
#plan 25;

use Dan :ALL;

## Series - Updates

my \s = $;
my \t = $;

s = Series.new([b=>1, a=>0, c=>2]);
s.ix: <b c d>;
is ~s, "b\t1\nc\t0\nd\t2\ndtype: Int, name: anon\n",                        's.ix';

s.splice: *-1;
is ~s<d>, "NaN",                                                            's.pop';

s.splice(1,2,3);
ok s<c> == 3,                                                               's.splice'; 

s.splice( 1,2,(j => Nil) );
ok s.ix[1] eq 'j',                                                          's.splice(aop)';

s.fillna;
is ~s<j>, "NaN",                                                            's.fillna';

s.dropna;
ok +s.ix == 1,                                                              's.dropna';

s = Series.new([b=>1, a=>0, c=>2]);
t = Series.new([f=>1, e=>0, d=>2]);
ok (s.concat: t).ix[3] eq 'f',                                              's.concat';

## DataFrames - Updates 

my $df2 = DataFrame.new([
        A => 1.0,
        B => Date.new("2022-01-01"),
        C => Series.new(1, index => [0..^4], dtype => Num),
        D => [3 xx 4],
        E => Categorical.new(<test train test train>),
        F => "foo",
]);
my $df3 = $df2;
my $df4 = $df2;
my $df5 = $df2;

$df5.ix: <a b c d>;
is $df5.index, "a\t0\nb\t1\nc\t2\nd\t3",                                            'df.ix';

$df5.cx: <a b c d e f>;
is $df5.dtypes, "a => Rat\nb => Date\nc => Num\nd => Int\ne => Str\nf => Str",      'df.cx';

$df2.splice: *-1; 
ok $df2.ix.elems == 3,                                                              'df.pop [row]';

$df2.splice: :ax(1), *-1;
ok $df2.cx.elems == 5,                                                              'df.pop [col]';

die;
my $ds = $df3[1];
$ds.splice(4,1,7);
$ds.name = '7';

my $se = $df3.series: <A>;
$se.splice(2,1,7);
$se.name = 'X';





done-testing;
