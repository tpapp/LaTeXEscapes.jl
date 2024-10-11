"""
$(DocStringExtensions.README)

# Exported symbols

$(DocStringExtensions.EXPORTS)
"""
module LaTeXEscapes

export LaTeX, @lx_str, wrap_math, print_escaped

using Automa: make_tokenizer, tokenize, @re_str
using DocStringExtensions: DocStringExtensions, SIGNATURES
using LaTeXStrings: LaTeXString

####
#### basic LaTeX checks
####

@enum LaTeXToken error CHAR MATHMODE COMMAND LEFT_CURLY RIGHT_CURLY

LaTeX_tokens = [
    CHAR => re".",
    MATHMODE => re"$",
    COMMAND => re"\\[a-zA-Z]+" | re"\\.",
    LEFT_CURLY => re"{",
    RIGHT_CURLY => re"}",
]

make_tokenizer((error, LaTeX_tokens)) |> eval

"""
$(SIGNATURES)

Internal function that performs some basic checks on its argument interpreted as a piece
of LaTeX code. The purpose of this function is to catch some simple mistakes (unbalanced
parentheses or dollar signs) that would lead to an error message that is hard to
intepret, possibly at a location very far from the actual error.

If there is an error message, it returns a string which can be used as an error message.

If all checks pass, return `nothing`. Note that this does not mean that `latex_str` is
correct LaTeX code, just that it passed some basic checks.
"""
function check_latex_msg(raw_latex)
    flag_mathmode::Bool = false
    count_curly::Int = 0
    for (_, _, token) in tokenize(LaTeXToken, raw_latex)
        if token == MATHMODE
            flag_mathmode = !flag_mathmode
        elseif token == LEFT_CURLY
            count_curly += 1
        elseif token == RIGHT_CURLY
            count_curly -= 1
        end
    end
    if flag_mathmode
        "Math mode not closed (missing '\$')."
    elseif count_curly > 0
        "$(count_curly) too many opening curly braces ('{')"
    elseif count_curly < 0
        "$(-count_curly) too many closing curly braces ('}')"
    else
        nothing
    end
end

####
#### wrappers and printing
####

struct LaTeX
    raw_latex::String
    @doc """
    $(SIGNATURES)

    A wrapper that allows its contents to be passed to LaTeX directly.

    It is the responsibility of the user to ensure that this is valid LaTeX code within the
    document.

    The string literal `lx` provides a convenient way to enter raw strings. When
    followed by `m`, it wraps its input in `\$`s.

    ```jldoctest
    julia> lx"\\cos(\\phi)"
    LaTeX("\\\\cos(\\\\phi)")

    julia> lx"\\cos(\\phi)"m
    LaTeX("\\\$\\\\cos(\\\\phi)\\\$")
    ```

    The type supports concatenation with `*`, just ensure that the first argument is of
    this type (can be empty).

    Interpolation syntax (`\$`) is not supported.

    `parent` can be used to obtain the wrapped code.
    """
    function LaTeX(raw_latex::AbstractString)
        if !(raw_latex isa String)
            raw_latex = convert(String, raw_latex)
        end
        new(raw_latex)
    end
end

function Base.show(io::IO, str::LaTeX)
    (; raw_latex) = str
    print(io, "lx\"")
    if check_latex_msg(raw_latex) ≡ nothing
        print(io, raw_latex)
    else
        printstyled(io, raw_latex; color = :red)
    end
    print(io, '"')
end

Base.parent(latex::LaTeX) = latex.raw_latex

"""
$(SIGNATURES)

Put \$'s around the string wrapped in [`LaTeX`](@ref).
"""
wrap_math(str::LaTeX) = LaTeX("\$" * str.raw_latex * "\$")

"""
$(SIGNATURES)

Indicate the argument is to be treated as (valid, self-contained) LaTeX code.
"""
macro lx_str(str, flag = nothing)
    if flag ≡ nothing
        LaTeX(str)
    else
        if flag == "m"
            wrap_math(LaTeX(str))
        else
            error("The only accepted flag is `m`.")
        end
    end
end

function print_escaped(io::IO, str::LaTeX; check::Bool = true)
    (; raw_latex) = str
    if check
        msg = check_latex_msg(raw_latex)
        msg ≡ nothing || throw(ArgumentError(msg))
    end
    print(io, raw_latex)
end

"""
$(SIGNATURES)

Outputs a version of `str` to `io` so that special characters (in LaTeX) are escaped to
produce the expected output.

When `check` (default: `true`), some basic checks are performed on strings already in
LaTex format. These do not guarantee valid LaTeX code, just catch some common mistakes
(unbalanced braces, etc).
"""
function print_escaped(io::IO, str::AbstractString; check::Bool = true)
    # NOTE: check is ignored, this should always be valid output
    for c in str
        if c == '\\'
            print(io, raw"\textbackslash{}")
        elseif c == '~'
            print(io, raw"\textasciitilde{}")
        elseif c == '^'
            print(io, raw"\textasciicircum{}")
        elseif c == '<'
            print(io, raw"\textless{}")
        elseif c == '>'
            print(io, raw"\textgreater{}")
        elseif c == '|'
            print(io, raw"\textbar{}")
        else
            c ∈ raw"#$%&_{}" && print(io, '\\')
            print(io, c)
        end
    end
end

function print_escaped(io::IO, x; check::Bool = true)
    print_escaped(io, string(x); check)
end

function print_escaped(io::IO, x::LaTeXString; check::Bool = true)
    write(io, x)
end

function Base.:(*)(str1::LaTeX, str_rest...)
    io = IOBuffer()
    for str in (str1, str_rest...)
        print_escaped(io, str; check = false)
    end
    LaTeX(String(take!(io)))
end

if isdefined(Base.Experimental, :register_error_hint)
    function _LaTeX_concat_handler(io::IO, exc::MethodError, argtypes, _)
        if exc.f == Base.:(*) && any(x -> x <: LaTeX, argtypes)
            print(io,
                  raw"""


                  To prefix LaTeX with strings, precede with lx"", eg

                  lx"" * "we know that " * lx"\cos(\phi)"m

                  """)
        end
    end

    function __init__()
        Base.Experimental.register_error_hint(_LaTeX_concat_handler, MethodError)
    end
end

end # module
