#!/usr/bin/env raku
#t/01.san.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
#plan 1;

use Dan;

my \s = $;    

s = Series.new([1, 3, 5, NaN, 6, 8], name => "mary");                                   
s.name = "john";
is ~s, "0\t1\n1\t3\n2\t5\n3\tNaN\n4\t6\n5\t8\nname: john, dtype: Num",      'new Series'; 

s = Series.new([0.23945079728503804e0 xx 5], index => <a b c d e>);
is ~s, "a\t0.23945079728503804\nb\t0.23945079728503804\nc\t0.23945079728503804\nd\t0.23945079728503804\ne\t0.23945079728503804\ndtype: Num",                                                   'explicit index';

s = Series.new([b=>1, a=>0, c=>2]);
is ~s, "b\t1\na\t0\nc\t2\ndtype: Int",                                      'Array of Pairs';

s = Series.new(5e0, index => <a b c d e>);
is ~s, "a\t5\nb\t5\nc\t5\nd\t5\ne\t5\ndtype: Num",                          'expand Scalar';

ok s[1]==5,                                                                 'Positional';
ok s{2}~~Nil,                                                               'Associative not Int';
ok s<c>==5,                                                                 'Associative <>';
ok s{"c"}==5,                                                               'Associative {}';
ok s.data == [5 xx 5],                                                      '.data';
ok s.index.map(*.key) == 'a'..'e',                                          '.index keys';
ok s.of ~~ Num,                                                             '.of';
ok s.dtype eq 'Num',                                                        '.dtype';

done-testing;
die;


#`[
### Operations ###

# Array Index Slices
say s[*-1];
say s[0..2];
say s[2] + 2;

# Math
say s.map(*+2);
say [+] s;

# Hyper
#dd s.hyper;
say s >>+>> 2;
say s >>+<< s;
my \t = s; say ~t;
#]

### DataFrames ###

#`[
dates = pd.date_range("20130101", periods=6)

DatetimeIndex(['2013-01-01', '2013-01-02', '2013-01-03', '2013-01-04',
               '2013-01-05', '2013-01-06'],
              dtype='datetime64[ns]', freq='D')

df = pd.DataFrame(np.random.randn(6, 4), index=dates, columns=list("ABCD"))
#]

my \dates = (Date.new("2022-01-01"), *+1 ... *)[^6];    #say dates;

my \df = DataFrame.new( [[rand xx 6] xx 4], index => dates, columns => <A B C D> );

say ~df; say "=============================================";

#`[
df2 = pd.DataFrame(
   ...:     {
   ...:         "A": 1.0,
   ...:         "B": pd.Timestamp("20130102"),
   ...:         "C": pd.Series(1, index=list(range(4)), dtype="float32"),
   ...:         "D": np.array([3] * 4, dtype="int32"),
   ...:         "E": pd.Categorical(["test", "train", "test", "train"]),
   ...:         "F": "foo",
   ...:     }
   ...: )

#]
my \df2 = DataFrame.new([
        A => 1.0,
        B => Date.new("2022-01-01"),
        C => Series.new(1, index => [0..^4], dtype => Num),
        D => [3 xx 4],
        E => Categorical.new(<test train test train>),
        F => "foo",
]);
say ~df2; say "=============================================";
say df2.dtypes;

say df.index;
say df.columns.keys;
say df.data;
say df.elems;

say "=============================================";
# Positional Access
say ~df[2];
say ~df[0..1];
say ~df[0,3];
##say ~df[0;1];

say "=============================================";
# Associative Access
#say dates[0];
say ~df{dates[0]}; 
#say ~df<A C>;


#`[
Notes:
- NaN is raku built in
- Series from Hash(Array) - order is unspecified (thus canonical is List of Pairs)
-
#]

