{pkgs, ...}: {
  imports = [
    ../_shared/darwin.nix
  ];

  programs.zsh.enable = true;
  programs.fish.enable = true;

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.etravers = {
    home = "/Users/etravers";
    shell = pkgs.fish;
  };
}
