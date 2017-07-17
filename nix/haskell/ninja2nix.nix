{ mkDerivation, aeson, aeson-pretty, base, bytestring
, concurrent-supply, containers, flow, hashable, language-ninja
, lens, makefile, mtl, prettyprinter, prettyprinter-ansi-terminal
, stdenv, text, transformers, unordered-containers
}:
mkDerivation {
  pname = "ninja2nix";
  version = "0.1.0";
  src = ../..;
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    aeson aeson-pretty base bytestring concurrent-supply containers
    flow hashable language-ninja lens makefile mtl prettyprinter
    prettyprinter-ansi-terminal text transformers unordered-containers
  ];
  executableHaskellDepends = [ base ];
  testHaskellDepends = [ base ];
  homepage = "https://github.com/awakesecurity/ninja2nix";
  description = "Convert a Ninja build file into a Nix derivation";
  license = stdenv.lib.licenses.asl20;
}
