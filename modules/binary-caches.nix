# Extra binary caches, shared by every system.
{ config, lib, ... }:
let
  substituters = [ "https://cache.numtide.com" ]; # llm-agents.nix
  keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
in
lib.mkMerge [
  (lib.mkIf config.nix.enable {
    nix.settings = {
      extra-substituters = substituters;
      extra-trusted-public-keys = keys;
    };
  })

  # Determinate Nix (nix.enable = false) owns nix.conf and includes this file.
  (lib.mkIf (!config.nix.enable) {
    environment.etc."nix/nix.custom.conf" = {
      # The installer's default file, so it may be replaced.
      knownSha256Hashes = [ "3bd68ef979a42070a44f8d82c205cfd8e8cca425d91253ec2c10a88179bb34aa" ];
      text = ''
        extra-substituters = ${toString substituters}
        extra-trusted-public-keys = ${toString keys}
      '';
    };
  })
]
