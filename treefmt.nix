{inputs, ...}: {
  imports = [inputs.treefmt-nix.flakeModule];
  perSystem = {
    pkgs,
    lib,
    ...
  }: {
    treefmt = {
      programs.actionlint.enable = true; # github action linter
      programs.alejandra.enable = true; # nix
      programs.mdformat.enable = true; # markdown
      programs.jsonfmt.enable = true; # json
      programs.shellcheck = {
        enable = true;
        includes = ["bin/*"];
      };
      programs.shfmt = {
        enable = true;
        includes = ["bin/*"];
      };
    };
  };
}
