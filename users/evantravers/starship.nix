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

      # custom module for jj status
      # https://github.com/jj-vcs/jj/wiki/Starship
      custom.jj = {
        ignore_timeout = true;
        description = "The current jj status";
        detect_folders = [ ".jj" ];
        symbol = "󱗆 ";
        command = ''
          jj log --revisions @ --no-graph --ignore-working-copy --color always --limit 1 --template '
            separate(" ",
              change_id.shortest(4),
              bookmarks,
              "|",
              concat(
                if(conflict, "💥"),
                if(divergent, "🚧"),
                if(hidden, "👻"),
                if(immutable, "🔒"),
              ),
              raw_escape_sequence("\x1b[1;32m") ++ if(empty, "(empty)"),
              raw_escape_sequence("\x1b[1;32m") ++ coalesce(
                truncate_end(29, description.first_line(), "…"),
                "(no description set)",
              ) ++ raw_escape_sequence("\x1b[0m"),
            )
          '
        '';
      };

      # optionally disable git modules
      git_state.disabled = true;

      git_commit.disabled = true;

      git_metrics.disabled = true;

      git_branch.disabled = true;

      # re-enable git_branch as long as we're not in a jj repo
      custom.git_branch = {
        when = true;
        command = "jj root >/dev/null 2>&1 || starship module git_branch";
        description = "Only show git_branch if we're not in a jj repo";
      };

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
