**Very much a work in progress - contributions very welcome!**

# raku Dan
Top level raku **D**ata **An**alysis Module

Dan aims to capture some helper datatypes, classes & roles, functions & operators for raku Data Analysis 

Dan can be a common parent for the raku end of some Data Analytic, Numeric & Scientific bindings
- Dan::Curve    - binding to pandas via Inline::Python
- Dan::Quinling - binding to polars via Rust FFI
- Dan::Paddle   - binding to Perl(5) Data Language using Inline::Perl5
- NumRa
- SciRa

The initial focus is on a minimal set of functions to cover the raku equivalent of:
- ndarray (eg. shaped arrays)
- Series
- DataFrames

Dan is also a place for common tests and documentation of what it means to do Data Analysis in raku

raku Dan is rather a zen concept since:
- raku contains many Data Analysis constructs & concepts natively anyway
- it's a stub for future high-performance, native implementations

So what are we getting from raku core that others do in libraries?
- pipes & maps
- multi-dimensional arrays
- slicing & indexing
- references & views
- map, reduce, hyper operators
- operator overloading
- concurrency
