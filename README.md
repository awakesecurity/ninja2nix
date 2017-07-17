# `ninja2nix`

[![Hackage][hackage-badge]][hackage-link]
[![Stackage][stackage-badge]][stackage-link]
[![License][license-badge]][license-link]

This is a work-in-progress project to make a tool that, given a Ninja build file
and a Nix-specified build environment and `src`, will produce a Nix derivation
that runs the Ninja build incrementally, by "exploding" the build graph into the
Nix derivation dependency graph. In other words, each node in the Ninja build
graph will become a Nix derivation, and the output of this tool is a derivation
that combines the outputs of all these Nix derivations corresponding to Ninja
build graph nodes.

Ideally, this will allow automatic generation of Nix derivations that allow
reproducible, deterministic, incremental builds of:

- [Haskell Cabal projects][cabal2ninja]
- [CMake projects][cmake]
- [The Linux kernel][kninja]

## Limitations

### `depfile`

If you use the Ninja `depfile` feature in such a way that a `build` declaration
produces a Makefile containing its own dependencies, incrementalism will
definitely be lost at best (at worst, the build may be incorrect). Note that the
example given for `depfile` in the Ninja manual seems to have this problem:

```
rule cc
  depfile = $out.d
  command = gcc -MMD -MF $out.d [other gcc flags here]
```

This is almost certainly an issue for CMake builds, which use `depfile` in this
way. I am not sure if this also affects [`kninja`][kninja], however. I plan on
patching upstream to avoid this issue if necessary.

<!----------------------------------------------------------------------------->

[hackage-badge]:
    https://img.shields.io/hackage/v/ninja2nix.svg?label=Hackage
[hackage-link]:
    https://hackage.haskell.org/package/ninja2nix
[stackage-badge]:
    https://www.stackage.org/package/ninja2nix/badge/lts?label=Stackage
[stackage-link]:
    https://www.stackage.org/package/ninja2nix
[license-badge]:
    https://img.shields.io/badge/License-Apache%202.0-blue.svg
[license-link]:
    https://spdx.org/licenses/Apache-2.0.html
[cabal2ninja]:
    https://github.com/awakesecurity/cabal2ninja
[cmake]:
    https://cmake.org/cmake/help/latest/generator/Ninja.html
[kninja]:
    https://github.com/rabinv/kninja
