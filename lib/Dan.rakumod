unit module Dan:ver<0.0.1>:auth<Steve Roe (p6steve@furnival.net)>;

my $db = 0;               #debug

class Series is export {
    has $.data is required where * ~~ Array|Hash;
    has $.index            where * ~~ List|Map;
    has Str   $.dtype;
    has Str   $.name;
    has Bool  $.copy;

    method TWEAK {
        die "index.elems != data.elems" if ( $!index && $!index.elems != $!data.elems );

        $!index = gather {
            my $i = 0;
            for |$!data -> $d {
                take ( $!index ?? $!index[$i++] !! $i++ ) => $d 
            }
        }.Hash
    }

    method index {
        $!index.keys
    }

    method Str {
        $!index
    }

    #`[
    #]
}
