# .latexmkrc — copied into every course repo scaffolded by the cours-latex
# skill (skills/cours-latex/SKILL.md). LuaLaTeX + shell-escape (minted) +
# the glossaries package's own documented latexmk recipe (see the
# "glossaries" package manual, section "Using the glossaries Package with
# latexmk") for running makeglossaries automatically between passes.
$pdf_mode = 4; # lualatex
$lualatex = 'lualatex -shell-escape -interaction=nonstopmode -synctex=1 %O %S';

add_cus_dep('glo', 'gls', 0, 'run_makeglossaries');
add_cus_dep('acn', 'acr', 0, 'run_makeglossaries');

sub run_makeglossaries {
    if ($silent) {
        system "makeglossaries -q '$_[0]'";
    }
    else {
        system "makeglossaries '$_[0]'";
    }
}

push @generated_exts, 'glo', 'gls', 'glg';
push @generated_exts, 'acn', 'acr', 'alg';
$clean_ext .= ' %R.ist %R.xdy';
