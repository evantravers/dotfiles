{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.programs.starship.enable {
    home.packages = lib.mkIf config.programs.jujutsu.enable [
      pkgs.jj-starship
    ];

    programs.starship = {
      settings = {
        command_timeout = 100;
        format = "[$all](dimmed white)";

        directory.style = "italic white";

        git_branch.ignore_branches = [
          "master"
          "main"
        ];

        git_status = {
          style = "bold yellow";
          format = "([$all_status$ahead_behind]($style) )";
        };

        elixir.symbol = " ";
        lua.symbol = "󰢱 ";
        nix_shell.symbol = " ";
        ruby.symbol = " ";

        character = {
          success_symbol = "[❯](dimmed green)";
          error_symbol = "[❯](dimmed red)";
        };

        jobs.disabled = true;
      } // lib.optionalAttrs config.programs.jujutsu.enable {
        # jj-starship module
        # https://github.com/dmmulroy/jj-starship
        custom.jj = {
          when = "jj-starship detect";
          shell = [ "jj-starship" ];
          format = "$output ";
        };

        # disable git modules when using jj-starship (handles both JJ and Git)
        git_branch.disabled = true;
      };
    };
  };
}
