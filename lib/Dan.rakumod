unit module Dan:ver<0.0.1>:auth<Steve Roe (p6steve@furnival.net)>;

my $db = 0;               #debug

class Series is export {
    has Array $.data is required;
    has       $.index where * ~~ List|Map;
    has Str   $.dtype;
    has Str   $.name;
    has Bool  $.copy;

    method TWEAK {
        if $!index {
            die "index.elems != data.elems" if $!index.elems != $!data.elems;
            given $!index {
                when List {
                    $!index = gather {
                        my $i = 0;
                        for |$!data -> $d {
                            take $!index[$i++] => $d 
                        }
                    }.Hash
                }
                when Map {
                    say 'hash'
                }
            }
        } else {
            $!index = gather {
                my $i = 0;
                for |$!data -> $d {
                    take $i++ => $d 
                }
            }.Hash
        }
    }
    #`[
    #]

    method Str {
        $!data
    }

}
