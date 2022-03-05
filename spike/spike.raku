# this is the top level model for combining Dan and Dan::Pandas, etc.
# going forward a good place to model roles for method groups

use lib './lib';
use Dan::Pandas;
#use Dan :ALL;
#use Dan;

my $s = Series.new;                         
#my $s = Dan::Series.new;                         
#my $s = Dan::Pandas::Series.new;            

#say $s.no, $s.yo, $s.^name;
say $s.no, $s.^name;

