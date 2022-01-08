#!/usr/bin/env raku
use lib '../lib';
use Dan;

#SYNOPSIS

#viz. https://pandas.pydata.org/docs/user_guide/10min.html
#viz. https://pandas.pydata.org/docs/user_guide/dsintro.html#dsintro
#s = pd.Series([1, 3, 5, np.nan, 6, 8])

#my $a = Array.new( [1, 3, 5, NaN, 6, 8] );     #say $a[2];

my $s1 = Series.new( data => [1, 3, 5, NaN, 6, 8] );
#my $s1 = Series.new( [1, 3, 5, NaN, 6, 8] );

say ~$s1;
say $s1[1];
say $s1{2};
say $s1.data;
say $s1.index;
say $s1.of;
say "=================";


#s = pd.Series(np.random.randn(5), index=["a", "b", "c", "d", "e"])

my $s2 = Series.new(
            data => [rand xx 5],
            index => <a b c d e>,
            #dtype => Nil,
            #name => Nil,
            #copy => Nil,
        );

say ~$s2;
say $s2[1];
say $s2<c>;
say $s2.data;
say $s2.index;
say $s2.of;
say "=================";

#d = {"b": 1, "a": 0, "c": 2}
#pd.Series(d)

my $s3 = Series.new( data => [b => 1, a => 0, c => 2] );

say ~$s3;
say $s3[1];
say $s3<c>;
say $s3.data;
say $s3.index;
say $s3.of;
say "=================";

#`[
Notes:
- NaN is cool
- assign Series from Hash order is unspecified (maybe a Map?)
#]

