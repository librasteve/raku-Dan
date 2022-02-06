# need to swap i<=>j, or not

#viz. https://stackoverflow.com/questions/70976231

class Series does Positional {
    has Real @.data = [0.1,0.2,0.3];
    has Int  %.index = %(0 => 0, 1 => 1, 2 => 2);

    method elems {
        @!data.elems
    }

    method AT-POS( |p ) is raw {
        @!data.AT-POS( |p )
    }
}

class DataFrame does Positional {
    has Series @.series;
    has Int    %.columns = %(A => 0, B => 1, C => 2);

    method elems {
        @!series.elems
    }

    method AT-POS( |p ) is raw {
        @!series.AT-POS( |p )
    }
}

#iamerejh - 
#something like deepmap Pairs to List of Ints
#also to try {; } for semilist

multi postcircumfix:<{ }>( Series:D $se, \i ) is export {
    #dd i; say i.^name; say $df.index{i};

    given i {
        when Str {
            $se.AT-POS( $se.index{ $_ } ) 
        }
        when List && .all ~~ Str {
            $se.index{ $_ }.map( {$se.AT-POS( $_ )} )
        }
        default {
            die "associative indexing requires Str key(s)" 
        }
    }
}

multi postcircumfix:<{ }>( DataFrame:D $df, \c ) is export {
    #dd c; say c.^name; say $df.columns{c};

    given c {
        when Str {
            $df.AT-POS( $df.columns{ $_ } ) 
        }
        when List && .all ~~ Str {
            $df.columns{ $_ }.map( {$df.AT-POS( $_ )} )
        }
        default {
            die "associative indexing requires Str key(s)" 
        }
    }
}

multi postcircumfix:<{; }>( DataFrame:D $df, \c ) is export {
    #say $df; dd c; say c.^name; say c.elems;

    die "DataFrame semilist indexing requires two dimensions only" unless c.elems == 2;

    my @se-pos;
    
    given my ( \j, \i ) = c {           say j,i;
        when Str, Str {                 #say "ss";
            $df{~j}{~i}
        }
        when List, Str {                #say "ls";
            given j {
                when .all ~~ Str {
                    @se-pos = j.map({ $df.columns{|j} })
                }
                when .all ~~ Int {
                    @se-pos = j.map({ $df.AT-POS(|j) }) 
                }
                default {
                    die "you can't mix Int and Str slicers"
                }
            }
            $df[@se-pos].map( *{~i} )
        }
        when Str, List {                say "sl";
        }
        when List, List {               say "ll"
        }
    }
}

my $df = DataFrame.new( series => Series.new xx 3 );

#`[
say $df;
say $df[1];
say $df[1].data;            #[0.1 0.2 0.3]
say $df[1][2];              #0.3
say $df[0,1];               #(Series.new(data => $[0.1, 0.2, 0.3]) Series.new(data => $[0.1, 0.2, 0.3]))
say $df[1,0];
say $df[1..2];
say $df[1;2];               #0.3
say $df[1;*];               #(0.1 0.2 0.3)
say $df[*;1];               #(0.2 0.2 0.2)
say $df.columns<A C>;
say $df[$df.columns<A C>];
say $df<A>;
say $df<A B>;
my $k = "C"; say $df{$k};
#say $df{1};                 #dies
say $df<A>;
say $df<A B>;
my $k = "C"; say $df{$k};
say $df{"A"};
say $df{"A"}.^name;
say $df{"A"}[1];
say $df{"A"}{"0"};
say $df{"A";"0";"z"};       #dies
say $df{"A";"0"};
say $df{<A>;<0>};
#]

say $df{<A B>;<0>};
say $df{(0,2);<0>};
say $df{[0,1];<0>};
say $df{0..2;<0>};          #False




#`[
Tree
-Int
-Range|List
-Pair

say $df{:columns<A C>};
dd $df[1,:exists]; #not implemented
#]







#`[
    my @series;
    my @data;

    given $p {
        when Int {                          say "Int";
            $df.series[$p]
        }
        when Range|List {                   say "Range|List";
            when .elems == 2 {              say "elems == 2";
                given .[0] {
                    when Int {              say ".[0] Int";
                        @series.push: $_ 
                    }
                    when Range|List {       say ".[0] Range|List";
                        @series = $_
                    }
                    when Pair {

                    }

                }
            }
        }
        default {
            say "default";
        }
    }
    say "series is @series[]";
#]
