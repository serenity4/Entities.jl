using Entities
using Documenter

DocMeta.setdocmeta!(Entities, :DocTestSetup, :(using Entities); recursive=true)

makedocs(;
    modules=[Entities],
    authors="Cédric BELMANT",
    repo="https://github.com/serenity4/Entities.jl/blob/{commit}{path}#{line}",
    sitename="Entities.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://serenity4.github.io/Entities.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/serenity4/Entities.jl",
    devbranch="main",
)
