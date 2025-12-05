{
  description = "pnpm plugin for the asdf version manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [./treefmt.nix];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = {
        pkgs,
        lib,
        ...
      }: let
        # Source filtered to only bin/ and tests/ - hash changes only when these change
        testSrc = lib.fileset.toSource {
          root = ./.;
          fileset = lib.fileset.unions [
            ./bin
            ./tests
          ];
        };

        # Compute NAR hash of filtered source (cached)
        testSrcHash = lib.removeSuffix "\n" (
          builtins.readFile (
            pkgs.runCommandLocal "test-src-hash" {} ''
              ${pkgs.nix}/bin/nix --extra-experimental-features nix-command hash path --base64 ${testSrc} > $out
            ''
          )
        );

        # Fixed-output derivation that runs bats tests with network access
        mkCheck = name: nodejs:
          pkgs.stdenvNoCC.mkDerivation {
            name = "asdf-pnpm-check-${name}";

            outputHashAlgo = "sha256";
            outputHashMode = "recursive";
            outputHash = testSrcHash;

            nativeBuildInputs = [
              pkgs.bats
              pkgs.curl
              pkgs.cacert
              pkgs.gnutar
              pkgs.gzip
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.gnused
              nodejs
            ];

            dontUnpack = true;
            dontConfigure = true;
            dontFixup = true;

            buildPhase = ''
              export HOME=$(mktemp -d)
              export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              bats ${testSrc}/tests/*.bats
            '';

            installPhase = ''
              cp -r ${testSrc} $out
            '';
          };
      in {
        checks = {
          node20 = mkCheck "node20" pkgs.nodejs_20;
          node22 = mkCheck "node22" pkgs.nodejs_22;
          node24 = mkCheck "node24" pkgs.nodejs_24;
        };
      };
    };
}
