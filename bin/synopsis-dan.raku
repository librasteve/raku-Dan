#!/usr/bin/env raku
use lib '../lib';
use Dan;

#SYNOPSIS

#viz. https://pandas.pydata.org/docs/user_guide/10min.html
#viz. https://pandas.pydata.org/docs/user_guide/dsintro.html#dsintro

### DataSlice ###

# used for the row (or column) of a DataFrame

#`[
my $ds = DataSlice.new( data => [1, 3, 5, NaN, 6, 8], index => <a b c d e f>, name => 'john' );
dd $ds;
say $ds.index;
say $ds.data;
say ~$ds;

say $ds[1];
say $ds[0..2];
say $ds[*];

say $ds{'b'};
say $ds<b d>;
say "=============================================";
#]

### Series ###

my \s = $;    

#`[
#s = pd.Series([1, 3, 5, np.nan, 6, 8])
#s = Series.new([1, 3, 5, NaN, 6, 8]);                                   
s = Series.new([1, 3, 5, NaN, 6, 8], name => "mary");                                   
#s = Series.new(data => [1, 3, 5, NaN, 6, 8], name => "mary");                                   
#s.name = "john";

say ~s; say "=============================================";
#]

#s = pd.Series(np.random.randn(5), index=["a", "b", "c", "d", "e"])
s = Series.new([rand xx 5], index => <a b c d e>);

say s.index;
say ~s; say "=============================================";

#`[
#s = pd.Series({"b": 1, "a": 0, "c": 2})

#canonical form is (ordered) Array of Pairs
s = Series.new([b=>1, a=>0, c=>2]);

#or coerce an (unordered) Hash to an Array
#my %h = %(b=>1, a=>0, c=>2); 
#s = Series.new(%h.Array);

say ~s; say "=============================================";

#s = pd.Series(5.0, index=["a", "b", "c", "d", "e"])
s = Series.new(5e0, index => <a b c d e>);

say ~s; say "=============================================";

say s[1];
say s{"c"};
say s<c>;
say s.data;
say s.index.sort(*.value).map(*.key);
say s.of;
say s.dtype;
#]

### Datatypes ###

#`[
The pandas / python base numeric datatypes map as follows:

- float             Num 
- int               Int
- bool              Bool

... TBD (check precision)
- timedelta64[ns]   Duration
- datetime64[ns]    Instance

... representation in pandas
- float             Real
- float             Rat

pandas ExtensionTypes are TBD
string / object dtypes are TBD

The general approach is:
- raku only - everything is Mu and works as usual
... is this efficient?
... do we care?
... how to handle (eg.) Measure types?
- raku2pandas - map dtypes suitably
... maybe remember original types on round trip (name, label?)
- pandas2raku - map dtypes suitably
... remember original type on round trip

So, functions are:
- Dan ... dtype is a courtesy attr, does nothing
#]

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
dd s.hyper;
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

die;
#`[[[
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

#]]]
