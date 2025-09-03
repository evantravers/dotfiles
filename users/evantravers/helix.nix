{
  pkgs,
  # helix-master,
  ...
}:

{
  programs.helix = {
    enable = true;
    # defaultEditor = true;
    # package = helix-master.packages.${pkgs.system}.default;
    languages = {
      language = [
        {
          name = "nix";
          language-servers = [ "nixd" ];
        }
        {
          name = "markdown";
          language-servers = [
            "markdown-oxide"
          ];
          comment-tokens = [
            "-"
            "+"
            "*"
            "1."
            ">"
            "- [ ]"
          ];
        }
        {
          name = "devicetree";
          file-types = [
            "keymap"
          ];
        }
      ];
      language-server = {
        nixd.command = "${pkgs.nixd}/bin/nixd";
        markdown-oxide.command = "${pkgs.markdown-oxide}/bin/markdown-oxide";
      };
    };
    settings = {
      theme = "earl_grey";
      editor = {
        color-modes = true;
        cursorline = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        end-of-line-diagnostics = "hint";
        inline-diagnostics = {
          cursor-line = "error";
        };
        file-picker = {
          hidden = false;
        };
        line-number = "relative";
        lsp = {
          display-inlay-hints = true;
        };
        rulers = [ 80 ];
        soft-wrap = {
          enable = false;
          wrap-at-text-width = true;
        };
        true-color = true;
        whitespace.render = "all";
      };
      keys = {
        normal = {
          space = {
            m = ":toggle-option soft-wrap.enable";
            q = ":reflow";
            f = "file_picker_in_current_directory";
            F = "file_picker";
          };
        };
        select = {
          space = {
            q = ":reflow";
          };
        };
        insert = {
          C-c = "normal_mode";
          "C-[" = "normal_mode";
        };
      };
    };
  };
}
