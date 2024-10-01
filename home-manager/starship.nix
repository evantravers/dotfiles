{...}:
{
  programs.starship = {
    enable = true;

    settings = {
      command_timeout = 100;
      format = "[$all](dimmed white)";

      directory.style = "italic white";

      git_branch.ignore_branches = [ "master" "main" ];

      git_status = {
        style = "bold yellow";
        format = "([$all_status$ahead_behind]($style) )";
      };

      elixir.symbol    = " ";
      lua.symbol       = "󰢱 ";
      nix_shell.symbol = " ";
      ruby.symbol      = " ";

      character = {
        success_symbol = "[❯](dimmed green)";
        error_symbol = "[❯](dimmed red)";
      };

      jobs.disabled = true;
    };
  };
}
