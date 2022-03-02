FROM p6steve/rakudo:ubuntu-arm64-2022.02

RUN git clone https://github.com/p6steve/raku-Dan.git

CMD ["raku", "-I/raku-Dan/lib", "/raku-Dan/bin/synopsis-dan.raku"]
