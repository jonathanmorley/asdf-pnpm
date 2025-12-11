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
      ];

      perSystem = {
        pkgs,
        lib,
        system,
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
            mkdir -p $out
            cp -r ${testSrc}/bin ${testSrc}/LICENSE $out/
            chmod -R +x $out/bin/*
            git -C $out init
            git -C $out config user.name "Test Runner"
            git -C $out config user.email "test@example.com"

            # Patch shebangs (so asdf plugin test gets them when cloning)
            patchShebangs $out/bin/*

            git -C $out add .
            git -C $out commit -m "Test snapshot" >/dev/null
          '';

        # Fixed-output derivation that runs bats tests with network access
        mkCheck = name: nodejs:
          pkgs.stdenvNoCC.mkDerivation {
            # Include system in name so each architecture is treated as a separate derivation
            name = "bats-${name}-${system}";

            outputHashAlgo = "sha256";
            outputHashMode = "recursive";
            outputHash = testSrcHash;

            nativeCheckInputs = [
              pkgs.asdf-vm
              pkgs.bats
              pkgs.cacert
              pkgs.curl
              pkgs.git
              pkgs.gnutar
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.gnused
              nodejs
            ];

            dontUnpack = true;
            dontConfigure = true;
            dontFixup = true;
            doCheck = true;

            buildPhase = ''
              cp -r "${pluginRepo}" plugin-repo
              export ASDF_PNPM_PLUGIN_REPO="$PWD/plugin-repo"
            '';

            checkPhase = ''
              export HOME=$(mktemp -d)

              # Set CA cert environment variable
              export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

              # Export node path for shebang patching in tests
              export NIX_NODE_PATH="${nodejs}/bin/node"

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
