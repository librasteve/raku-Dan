FROM p6steve/rakudo:ubuntu-arm64-2021.05

RUN git clone https://github.com/p6steve/raku-Dan.git

CMD ["cd raku-Dan/bin && raku synopsis-dan.raku"]
