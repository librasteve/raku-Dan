FROM p6steve/rakudo:basic

RUN git clone https://github.com/p6steve/raku-Dan.git

CMD ["raku", "-I/raku-Dan/lib", "/raku-Dan/bin/synopsis-dan.raku"]
