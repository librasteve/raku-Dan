#!/usr/bin/env raku
use lib '../lib';
use Dan;

#SYNOPSIS

#viz. https://pandas.pydata.org/docs/user_guide/10min.html
#viz. https://pandas.pydata.org/docs/user_guide/dsintro.html#dsintro

my \s = $;    

### Declarations ###

#s = pd.Series([1, 3, 5, np.nan, 6, 8])
s = Series.new([1, 3, 5, NaN, 6, 8]);                                   

say ~s; say "=============================================";

#s = pd.Series(np.random.randn(5), index=["a", "b", "c", "d", "e"])
s = Series.new([rand xx 5], index => <a b c d e>);

say ~s; say "=============================================";

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
say s{2};
say s<c>;
say s.data;
say s.index;
say s.of;
say s.dtype;

### Operations ###

#say s >>+ 2;
#say s [+] 2;

#`[
Notes:
- NaN is cool
- Series from Hash - order is unspecified (thus canonical is List of Pairs)
#]

