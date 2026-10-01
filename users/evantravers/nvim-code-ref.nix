{ config, lib, ... }:
{
  config = lib.mkIf config.programs.neovim.enable {
    programs.neovim.initLua =
      lib.mkAfter (lib.fileContents .config/nvim/code-ref.lua);
  };
}
