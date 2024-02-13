# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{... }:

{
  imports = [
    # include NixOS-WSL modules
  ];

  wsl = {
    enable = true;
    defaultUser = "evan";
    nativeSystemd = true;
    interop.includePath = false;
  };

  environment = {
    systemPackages = with pkgs; [
      wslu
    ];
  };
}
