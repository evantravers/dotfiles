{...}:
{
  programs.starship = {
    enable = true;

    settings = {
      command_timeout = 100;
      format = "[$all](dimmed white)";

      directory = {
        style = "bold fg";
      };

      nix_shell = {
        symbol = " ";
        style = "italic fg";
      };

      character = {
        success_symbol = "[❯](dimmed green)";
        error_symbol = "[❯](dimmed red)";
      };

      git_branch = {
        ignore_branches = [ "master" "main" ];
      };

      git_status = {
        style = "bold yellow";
        format = "([$all_status$ahead_behind]($style) )";
      };

      jobs.disabled = true;
    };
  };
}
