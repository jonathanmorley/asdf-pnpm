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
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
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
            ./flake.nix
            ./LICENSE
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

        # Git repo containing just the plugin for `asdf plugin-test`
        pluginRepo =
          pkgs.runCommandLocal "asdf-pnpm-plugin-repo" {
            nativeBuildInputs = [pkgs.git];
          } ''
            ls -la /usr/bin

            mkdir -p $out
            cp -r ${testSrc}/bin ${testSrc}/LICENSE $out/
            chmod -R +x $out/bin/*
            git -C $out init
            git -C $out config user.name "Test Runner"
            git -C $out config user.email "test@example.com"
            git -C $out add .
            git -C $out commit -m "Test snapshot" >/dev/null
          '';

        # Fixed-output derivation that runs bats tests with network access
        mkCheck = name: nodejs:
          pkgs.stdenvNoCC.mkDerivation {
            name = "asdf-pnpm-check-${name}";

            outputHashAlgo = "sha256";
            outputHashMode = "recursive";
            outputHash = testSrcHash;

            nativeBuildInputs = [
              pkgs.asdf-vm
              pkgs.bats
              pkgs.cacert
              pkgs.curl
              pkgs.git
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

              cp -r "${pluginRepo}" plugin-repo
              export ASDF_PNPM_PLUGIN_REPO="$PWD/plugin-repo"
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
