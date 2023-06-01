#!/usr/bin/env raku
#t/01.ser.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
plan 30;

use Dan :ALL;

## DataSlices

my $ds = DataSlice.new( data => [1, 3, 5, NaN, 6, 8], index => <a b c d e f>, name => 'john' );
is ~$ds.index, "a\t0\nb\t1\nc\t2\nd\t3\ne\t4\nf\t5",                        'DataSlice.index';
is ~$ds.data, "1 3 5 NaN 6 8",                                              'DataSlice.data';
ok $ds[1] == 3,                                                             'DataSlice[1]';
ok $ds[0..2] == (1,3,5),                                                    'DataSlice[0..2]';
ok $ds[*] == (1,3,5,NaN,6,8),                                               'DataSlice[*]';
ok $ds{"b"} == 3,                                                           'DataSlice{"b"}';
ok $ds<b d> == (3,NaN),                                                     'DataSlice<b d>'; 

## Series

# Constructors

my \s0 = Series.new([1, 3, 5, NaN, 6, 8], name => "mary");                                   
s0.name = "john";
is ~s0, "0\t1\n1\t3\n2\t5\n3\tNaN\n4\t6\n5\t8\ndtype: Real, name: john\n",    'new Series'; 

my \s1 = Series.new([0.23945079728503804e0 xx 5], index => <a b c d e>);
is ~s1, "a\t0.23945079728503804\nb\t0.23945079728503804\nc\t0.23945079728503804\nd\t0.23945079728503804\ne\t0.23945079728503804\ndtype: Num, name: anon\n",                                     'explicit index';

my \s2 = Series.new([b=>1, a=>0, c=>2]);
is ~s2, "b\t1\na\t0\nc\t2\ndtype: Int, name: anon\n",                        'Array of Pairs';

my \s3 = Series.new(5e0, index => <a b c d e>);
is ~s3, "a\t5\nb\t5\nc\t5\nd\t5\ne\t5\ndtype: Num, name: anon\n",            'expand Scalar';

# Accessors

ok s3.ix == <a b c d e>,                                                     'Series.ix';
ok s3[1]==5,                                                                 'Positional';
ok s3{'b'}==5,                                                               'Associative not Int';
ok s3<c>==5,                                                                 'Associative <>';
ok s3{"c"}==5,                                                               'Associative {}';
ok s3.data == [5 xx 5],                                                      '.data';
ok s3.index.map(*.key) == 'a'..'e',                                          '.index keys';
ok s3.of ~~ Any,                                                             '.of';
ok s3.dtype ~~ Num,                                                          '.dtype';

# Operations 

ok s3[*] == 5 xx 5,                                                          'Whatever slice';
##ok s3[] == 5 xx 5,                                                           'Zen slice';
ok s3[*-1] == 5,                                                             'Whatever Pos';
ok s3[0..2] == 5 xx 3,                                                       'Range slice';
ok s3[2] + 2 == 7,                                                           'Element math';
ok s3.map(*+2) == 7 xx 5,                                                    '.map math';
ok ([+] s3) == 25,                                                           '[] operator';
ok s3.hyper ~~ HyperSeq,                                                     '.hyper';
ok (s3 >>+>> 2) == 7 xx 5,                                                   '>>+>>';
ok (s3 >>+<< s3) == 10 xx 5,                                                 '>>+<<';
my \t = s3; 
ok ([+] t) == 25,                                                           'assignment';

#done-testing;
