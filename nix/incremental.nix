# This needs cleanup.
# See https://gist.github.com/taktoa/894ff2ba18bdde7142177f2c3ddcbaea
# for the proof-of-concept example this code is based on.

with builtins;

rec {
  pkgs = import <nixpkgs> {};

  testGHC = pkgs.haskellPackages.ghcWithPackages (p: with p; [
    base base-orphans bifunctors comonad contravariant distributive
    tagged transformers
  ]);

  testInputs = [ testGHC pkgs.findutils pkgs.parallel ];

  extractSrc = drv: { patches ? [] }: pkgs.stdenv.mkDerivation {
    name = "${drv.name}-src";
    src = drv.src;
    phases = [ "unpackPhase" "patchPhase" "installPhase" ];
    inherit patches;
    installPhase = ''
      mkdir -p $out/
      cp -Rv ./* $out/
    '';
  };

  testCBs = inputs: {
    build = self: { command, dependencies }: (
      pkgs.stdenv.mkDerivation {
        name = "intermediate-build";

        src = pkgs.buildEnv {
          name = "intermediate-build-env";
          paths = dependencies;
        };

        inherit command;

        buildInputs = inputs;

        phases = ["unpackPhase" "buildPhase" "installPhase"];

        unpackPhase = ''
          cp -Lsrv "$src" .
          cd "$(basename "$src")"
          chmod -Rv u+w .
        '';

        buildPhase = ''
          eval "$command"
        '';

        installPhase = ''
          mkdir -p "$out"
          function helper () {
              FILE="$1"
              if test -e "$FILE"; then
                  echo "helper: processing $FILE"
                  if test -d "$FILE"; then
                      echo "helper: $FILE is a directory, so we should make it"
                      mkdir -pv "$out/$FILE"
                  elif test -h "$FILE"; then
                      echo "helper: $FILE is symlink, so we should symlink the original"
                      cp -sv "$(readlink -f "$FILE")" "$out/$(dirname "$FILE")"
                  else
                      echo "helper: $FILE is a regular file, so we should copy it"
                      cp -v "$FILE" "$out/$(dirname "$FILE")"
                  fi
              else
                  echo "helper: error: $FILE does not exist"
              fi
          }
          export -f helper
          find . | parallel "helper {}"
        '';
      });

    phony = self: dependencies: pkgs.buildEnv {
      name = "intermediate-phony";
      paths = dependencies;
    };

    leaf = self: path: (
      with rec {
        file = readFile (toPath "${self.src}/${path}");
        drv = toFile "interned-leaf" file;
      };

      pkgs.runCommand "intermediate-leaf" {} ''
        mkdir -p "$out/$(dirname ${path})"
        cp -v "${drv}" "$out/$(dirname ${path})/$(basename ${path})"
      '');
  };

  exampleSrc = extractSrc pkgs.haskellPackages.profunctors {
    patches = [];
    #patches = [ ./example.patch ];
  };

  dynamize = data: { build, phony, leaf }: self: (
    with rec {
      convertBuild = node: build self { inherit (node) command dependencies; };
      convertPhony = node: phony self node.dependencies;
      convertLeaf  = node: leaf self node.path;
      convertNode  = node: (
        if      node.type == "build" then convertBuild node
        else if node.type == "phony" then convertPhony node
        else if node.type == "leaf"  then convertLeaf  node
        else abort ("invalid node type in build graph: " + node.type));
    };

    {
      inherit (data) src defaults;
      graph = pkgs.lib.attrsets.mapAttrs (key: val: convertNode val) data.graph;
    });

  resolver = cb: { build, phony, leaf }: (
    cb {
      build = self: { command, dependencies }: (build self {
        inherit command;
        dependencies = map (x: self.graph.${x}) dependencies;
      });

      phony = self: dependencies: (
        phony self (map (x: self.graph.${x}) dependencies));

      inherit leaf;
    });

  ninjaJSON = fromJSON (readFile ./ninja.json);

  exampleNinjaData = ninjaJSON // { src = toPath "${exampleSrc}/src"; };

  exampleNinja = dynamize exampleNinjaData;

  combineDefault = ({ defaults, graph, ... }:
    pkgs.buildEnv {
      name = "default";
      paths = (map (x: graph.${x}) defaults);
    });

  buildNinja = ninja: cbs: combineDefault (pkgs.lib.fix (resolver ninja cbs));

  test = buildNinja exampleNinja (testCBs testInputs);
}
