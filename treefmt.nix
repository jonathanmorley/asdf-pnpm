{inputs, ...}: {
  imports = [inputs.treefmt-nix.flakeModule];
  perSystem = {
    pkgs,
    lib,
    ...
  }: {
    treefmt = {
      settings.on-unmatched = "fatal"; # Ensure 100% coverage
      programs.actionlint.enable = true; # github action linter
      programs.alejandra.enable = true; # nix
      programs.mdformat.enable = true; # markdown
      programs.jsonfmt.enable = true; # json
      programs.shellcheck = {
        enable = true;
        includes = ["bin/*" "*.bats" "*.bash"];
      };
      programs.shfmt = {
        enable = true;
        includes = ["bin/*" "*.bats" "*.bash"];
      };
    };
  };
}
