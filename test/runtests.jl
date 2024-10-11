using LaTeXEscapes
using LaTeXStrings
using Test

@testset "macros, escaping and concatenation" begin
    s = lx"\textbf{A}" * lx"\cos(\varphi)"m * L"1+\sin(\alpha)" * raw"#$%&~_^{}<>|"
    @test parent(s) == (raw"\textbf{A}$\cos(\varphi)$$1+\sin(\alpha)$\#\$\%\&" *
                        raw"\textasciitilde{}\_\textasciicircum{}\{\}" *
                        raw"\textless{}\textgreater{}\textbar{}")
    @test_throws MethodError "aa" * lx"αa"
end

"check whether our tests flag LaTeX code with errors"
is_ok(l::LaTeX) = LaTeXEscapes.check_latex_msg(parent(l)) ≡ nothing

@testset "LaTeX validation" begin
    @test is_ok(lx"\cos(\varphi)")
    @test is_ok(lx"\cos(\varphi)"m)
    @test !is_ok(lx"\frac{")
    @test !is_ok(lx"\frac{}}")
    @test !is_ok(lx"$\cos")
end

using JET
@testset "static analysis with JET.jl" begin
    @test isempty(JET.get_reports(report_package(LaTeXEscapes, target_modules=(LaTeXEscapes,))))
end

@testset "QA with Aqua" begin
    import Aqua
    Aqua.test_all(LaTeXEscapes; ambiguities = false)
    # testing separately, cf https://github.com/JuliaTesting/Aqua.jl/issues/77
    Aqua.test_ambiguities(LaTeXEscapes)
end
