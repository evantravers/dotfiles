{ ... }:
{
  programs.starship = {
    enable = true;

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

      # jj-starship module
      # https://github.com/dmmulroy/jj-starship
      custom.jj = {
        when = "jj-starship detect";
        shell = [ "jj-starship" ];
        format = "$output ";
      };

      # disable git modules when using jj-starship (handles both JJ and Git)
      git_branch.disabled = true;

      elixir.symbol = " ";
      lua.symbol = "󰢱 ";
      nix_shell.symbol = " ";
      ruby.symbol = " ";

      character = {
        success_symbol = "[❯](dimmed green)";
        error_symbol = "[❯](dimmed red)";
      };

      jobs.disabled = true;
    };
  };
}
