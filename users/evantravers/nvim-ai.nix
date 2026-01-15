{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.unstable.vimPlugins; [
      plenary-nvim
      # CodeCompanion as the core AI source
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          pname = "codecompanion-nvim";
          version = "HEAD";
          src = pkgs.fetchFromGitHub {
            owner = "olimorris";
            repo = "codecompanion.nvim";
            rev = "181e93c3f6a65ead4106f1b5a71194103accb3d3";
            sha256 = "sha256-DHU/eaZmNQ+rr05+OiZR6s5aEHXjyEd6SJzUYybnVr4=";
          };
          doCheck = false;
          checkPhase = ":";
        };
        type = "lua";
        config = ''
          -- required for githubmodels token via gh
          vim.env["CODECOMPANION_TOKEN_PATH"] = vim.fn.expand("~/.config")
          local ai_strategy = os.getenv("AI_STRATEGY") or "anthropic"

          require("codecompanion").setup({
            interactions = {
              chat = {
                adapter = ai_strategy,
                keymaps = {
                  close = {modes = { n = "<C-q>", i = "<C-q>" }, opts = {}},
                  options = {modes = { n = "<leader>h" }, opts = {}},
                },
              },
              inline = { adapter = ai_strategy }
            },
            adapters = {
              acp = {
                devclarity_claude_code = function()
                  return require("codecompanion.adapters").extend("claude_code", {
                    env = {
                      ANTHROPIC_API_KEY = "cmd:op read op://Private/yy6goxmme5pm5jkhsmspolopme/credential --no-newline"
                    },
                    commands = {
                      default = {
                        "claude-code-acp"
                      }
                    }
                  })
                end,
                opencode = function()
                  return require('codecompanion.adapters').extend('claude_code', {
                    name = 'opencode',
                    formatted_name = 'OpenCode',
                    commands = {
                      default = { 'opencode', 'acp' },
                    },
                  })
                end
              },
              http = {
                -- hide adapters that I haven't explicitly configured
                opts = { show_defaults = false, },
                anthropic = function()
                  return require("codecompanion.adapters").extend("anthropic", {
                    env = {
                      api_key = "cmd:op read op://Private/Claude/credential --no-newline"
                    }
                  })
                end,
                githubmodels = function()
                  return require("codecompanion.adapters").extend("githubmodels", {
                    schema = {
                      model = {
                        default = "gpt-4.1",
                      },
                    },
                  })
                end
              }
            },
            extensions = {
            }
          })

          vim.keymap.set({ "n", "v" }, "<LocalLeader>A", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true, desc = "✨ Actions" })
          vim.keymap.set({ "n", "v" }, "<LocalLeader>a", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true, desc = "✨ Toggle Chat" })
          vim.keymap.set("v", "<LocalLeader>c", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true, desc = "✨ Add to Chat" })

          -- Expand 'cc' into 'CodeCompanion' in the command line
          vim.cmd([[cab cc CodeCompanion]])
        '';
      }

      # Markview for making codecompanion prettier
      {
        plugin = markview-nvim;
        type = "lua";
        config = ''
          require("markview").setup({
            preview = {
              filetypes = { "codecompanion" },
              ignore_buftypes = {},
            }
          });
        '';
      }
    ];
  };
}
