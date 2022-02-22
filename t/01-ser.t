#!/usr/bin/env raku
#t/01.ser.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
plan 30;

use Dan;

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
my \s = $;    

# Constructors

s = Series.new([1, 3, 5, NaN, 6, 8], name => "mary");                                   
s.name = "john";
is ~s, "0\t1\n1\t3\n2\t5\n3\tNaN\n4\t6\n5\t8\ndtype: Num, name: john\n",    'new Series'; 

s = Series.new([0.23945079728503804e0 xx 5], index => <a b c d e>);
is ~s, "a\t0.23945079728503804\nb\t0.23945079728503804\nc\t0.23945079728503804\nd\t0.23945079728503804\ne\t0.23945079728503804\ndtype: Num, name: anon\n",                                     'explicit index';

s = Series.new([b=>1, a=>0, c=>2]);
is ~s, "a\t1\nb\t0\nc\t2\ndtype: Int, name: anon\n",                        'Array of Pairs';

s = Series.new(5e0, index => <a b c d e>);
is ~s, "a\t5\nb\t5\nc\t5\nd\t5\ne\t5\ndtype: Num, name: anon\n",            'expand Scalar';

# Accessors

ok s.ix == <a b c d e>,                                                     'Series.ix';
ok s[1]==5,                                                                 'Positional';
ok s{'b'}==5,                                                               'Associative not Int';
ok s<c>==5,                                                                 'Associative <>';
ok s{"c"}==5,                                                               'Associative {}';
ok s.data == [5 xx 5],                                                      '.data';
ok s.index.map(*.key) == 'a'..'e',                                          '.index keys';
ok s.of ~~ Any,                                                             '.of';
ok s.dtype eq 'Num',                                                        '.dtype';

# Operations 

ok s[*] == 5 xx 5,                                                          'Whatever slice';
##ok s[] == 5 xx 5,                                                           'Zen slice';
ok s[*-1] == 5,                                                             'Whatever Pos';
ok s[0..2] == 5 xx 3,                                                       'Range slice';
ok s[2] + 2 == 7,                                                           'Element math';
ok s.map(*+2) == 7 xx 5,                                                    '.map math';
ok ([+] s) == 25,                                                           '[] operator';
ok s.hyper ~~ HyperSeq,                                                     '.hyper';
ok (s >>+>> 2) == 7 xx 5,                                                   '>>+>>';
ok (s >>+<< s) == 10 xx 5,                                                  '>>+<<';
my \t = s; 
ok ([+] t) == 25,                                                           'assignment';

#done-testing;
