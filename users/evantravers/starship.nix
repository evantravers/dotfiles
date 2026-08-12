{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.programs.starship.enable {
    home.packages = lib.mkIf config.programs.jujutsu.enable [
      pkgs.jj-starship
    ];

    programs.starship = {
      settings = {
        command_timeout = 100;
        format = "[$all](dimmed white)";

        directory.style = "bold italic white";

        git_branch.ignore_branches = [
          "master"
          "main"
        ];

        git_status = {
          style = "italic yellow";
          format = "([$all_status$ahead_behind]($style) )";
        };

        cmd_duration = {
          style = "italic";
          format = "took [$duration]($style) ";
        };

        elixir = {
          symbol = " ";
          format = "via [$symbol](purple)";
        };

        package = {
          symbol = "󰏗 ";
          format = "is [$symbol](208)$version ";
        };

        lua.symbol = "󰢱 ";
        nix_shell.symbol = " ";
        ruby.symbol = " ";

        docker_context = {
          symbol = "󰡨 ";
          format = "via [$symbol](blue)";
        };

        nodejs = {
          symbol = "󰎙 ";
          format = "via [$symbol](green)";
        };

        nix_shell.format = "via [$symbol](cyan)( $name )";

        rust = {
          symbol = "󱘗 ";
          format = "via [$symbol](red)";
        };

        aws = {
          symbol = "󰸏 ";
          format = "on [$symbol](yellow)($profile)";
        };

        character = {
          success_symbol = "[❯](dimmed white)";
          error_symbol = "[❯](bold red)";
          vimcmd_symbol = "[❮](bold white)";
        };

        jobs.disabled = true;
      }
      // lib.optionalAttrs config.programs.jujutsu.enable {
        # jj-starship module
        # https://github.com/dmmulroy/jj-starship
        custom.jj = {
          when = "jj-starship detect";
          shell = [
            "jj-starship"
            "--no-color"
            "--jj-symbol"
            "󱗆 "
          ];
          format = "$output ";
        };

        # disable git modules when using jj-starship (handles both JJ and Git)
        git_branch.disabled = true;
        git_commit.disabled = true;
      };
    };
  };
}
