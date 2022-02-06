#!/usr/bin/env raku
#t/01.san.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
#plan 1;

use Dan;

my \s = $;    

## Series

# Constructors

s = Series.new([1, 3, 5, NaN, 6, 8], name => "mary");                                   
s.name = "john";
is ~s, "0\t1\n1\t3\n2\t5\n3\tNaN\n4\t6\n5\t8\nname: john, dtype: Num",      'new Series'; 

s = Series.new([0.23945079728503804e0 xx 5], index => <a b c d e>);
is ~s, "a\t0.23945079728503804\nb\t0.23945079728503804\nc\t0.23945079728503804\nd\t0.23945079728503804\ne\t0.23945079728503804\ndtype: Num",                                                   'explicit index';

s = Series.new([b=>1, a=>0, c=>2]);
is ~s, "b\t1\na\t0\nc\t2\ndtype: Int",                                      'Array of Pairs';

s = Series.new(5e0, index => <a b c d e>);
is ~s, "a\t5\nb\t5\nc\t5\nd\t5\ne\t5\ndtype: Num",                          'expand Scalar';

# Accessors

ok s[1]==5,                                                                 'Positional';
ok s{2}~~Nil,                                                               'Associative not Int';
ok s<c>==5,                                                                 'Associative <>';
ok s{"c"}==5,                                                               'Associative {}';
ok s.data == [5 xx 5],                                                      '.data';
ok s.index.map(*.key) == 'a'..'e',                                          '.index keys';
ok s.of ~~ Num,                                                             '.of';
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

## DataFrames

my \dates = (Date.new("2022-01-01"), *+1 ... *)[^6];    #say dates;
my @d2-array = [[rand xx 6] xx 4];

my \df = DataFrame.new( @d2-array, index => dates, columns => <A B C D> );

ok df.columns.elems == 4,                                                   'new DataFrame';
is df.index, "2022-01-01 2022-01-02 2022-01-03 2022-01-04 2022-01-05 2022-01-06", '.index';
ok df.columns.keys == 0..3,                                                 '.columns keys';
ok df.elems == 4,                                                           '.elems';
#should be 6!

##my @d2-sum = ([+] @d2-array[*;*]); 
##ok ([+] df.data[*;*]) == @d2-sum,                                             'data check';

my \df2 = DataFrame.new([
        A => 1.0,
        B => Date.new("2022-01-01"),
        C => Series.new(1, index => [0..^4], dtype => Num),
        D => [3 xx 4],
        E => Categorical.new(<test train test train>),
        F => "foo",
]);
ok df2.columns.elems == 6,                                                   'Array of Series';
is df2.dtypes, "A => Rat\nB => Date\nC => Int\nD => Int\nE => Str\nF => Str",'.dtypes';

done-testing;

#EOF
