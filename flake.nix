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
        mkCheck = name: nodejs:
          pkgs.stdenvNoCC.mkDerivation {
            name = "bats-${name}-${system}";

            __impure = true;
            __noChroot = true;

            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions [
                ./bin
                ./tests
                ./LICENSE
              ];
            };

            nativeBuildInputs = [pkgs.git];
            nativeCheckInputs = [
              pkgs.asdf-vm
              pkgs.bats
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
            dontInstall = true;

            buildPhase = ''
              mkdir -p $out

              cp -r $src/bin $src/LICENSE $out/
              chmod -R +x $out/bin/*
              git -C $out init
              git -C $out config user.name "Test Runner"
              git -C $out config user.email "test@example.com"

              # Patch shebangs (so asdf plugin test gets them when cloning)
              patchShebangs $out/bin/*

              git -C $out add .
              git -C $out commit -m "Test snapshot" >/dev/null
            '';

            SSL_CERT_FILE =
              if builtins.getEnv "SSL_CERT_FILE" != ""
              then builtins.getEnv "SSL_CERT_FILE"
              else "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

            # Export node path for shebang patching in tests
            NIX_NODE_PATH = "${nodejs}/bin/node";

            checkPhase = ''
              export ASDF_PNPM_PLUGIN_REPO="$out"
              export HOME=$(mktemp -d)

              bats $src/tests/*.bats
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
