# LaTeXEscapes.jl

![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)
[![CI](https://github.com/tpapp/LaTeXEscapes.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/tpapp/LaTeXEscapes.jl/actions/workflows/CI.yml)
[![codecov.io](http://codecov.io/github/tpapp/LaTeXEscapes.jl/coverage.svg?branch=master)](http://codecov.io/github/tpapp/LaTeXEscapes.jl?branch=master)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

Julia package for escaping strings for LaTeX and wrapping LaTeX code.

It is intended to be used by other packages that accept strings and/or LaTeX code from the user, and output LaTeX code.

## Overview

The `LaTeX` wrapper indicates the string contained within should be treated as LaTeX code.

```julia
julia> using LaTeXEscapes

julia> l1 = lx"\copyright"             # LaTeX
LaTeX(\copyright)

julia> l2 = lx"\cos(\phi)"             # LaTeX wrapped in math
LaTeX(\cos(\phi))

julia> s3 = "1 < 3"                    # String
"1 < 3"

julia> print_escaped(stdout, l2)
\cos(\phi)

julia> print_escaped(stdout, s3)
1 \textless{} 3
```

Some rudimentary checks are performed with `print_escaped`, these can be skipped if desired.

```julia
julia> print_escaped(stdout, lx"{unbalanced")
ERROR: ArgumentError: 1 too many opening curly braces ('{')
   
julia> print_escaped(stdout, lx"{unbalanced"; check = false)  
{unbalanced
```

Interpolation is *not supported*. Use the concatenation `*` operator:

``` julia
julia> lx"$a + " * lx"b$"
LaTeX($a + b$)
```

If the first argument is not a `LaTeX` wrapper, precede it with an empty wrapper to force escaping and conversion:

``` julia
julia> lx"" * "We are 100% sure that " * lx"$a + " * lx"b$"
LaTeX(We are 100\% sure that $a + b$)
```

## Differences from other packages

Generally, this package
1. does not make the wrapper a subtype of string, as it is *code*.
2. focuses on providing a type that users can use to signal that the input is intended to be LaTeX code.

[LaTeXStrings.jl](https://github.com/JuliaStrings/LaTeXStrings.jl) provides a similar wrapper, defaulting to math expressions. It does not handle escaping. `print_escaped` above works with the `LaTeXString` type from this package.
