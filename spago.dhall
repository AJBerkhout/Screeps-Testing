{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name =
    "my-project"
, dependencies =
    [ "effect"
    , "console"
    , "psci-support"
    , "maybe"
    , "either"
    , "argonaut"
    , "ordered-collections"
    , "generics-rep"
    , "foreign-object"
    , "functions"
    , "partial"
    , "exceptions"
    ]
, packages =
    ./packages.dhall
, sources =
    [ "src/**/*.purs", "test/**/*.purs" ]
}