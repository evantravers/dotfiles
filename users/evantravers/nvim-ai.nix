{
  config,
  lib,
  pkgs,
  ...
}:

let
  defaultStrategy = "opencode";

  # Local models are served by llama-cpp.nix, which owns the port.
  llamaCppBaseUrl = "http://localhost:${toString config.programs.llama-cpp.port}";
  localModels = config.programs.llama-cpp.models;

  # HTTP-based adapters for local llama-cpp models
  httpAdapters = lib.concatMapStringsSep "\n" (m: ''
    ${m.name} = function()
      return require("codecompanion.adapters").extend("openai_compatible", {
        name = "${m.name}",
        formatted_name = "${m.label}",
        env = {
          url = "${llamaCppBaseUrl}",
          api_key = "none",
        },
        schema = {
          model = {
            default = "${m.model}",
          },
        },
      })
    end,
  '') localModels + ''

    moonshot = function()
      return require("codecompanion.adapters").extend("openai_compatible", {
        name = "moonshot",
        formatted_name = "Moonshot AI",
        env = {
          url = "https://api.moonshot.ai",
          api_key = "cmd:op read op://Private/Moonshot/credential --no-newline",
        },
        schema = {
          model = {
            default = "kimi-k3",
          },
        },
      })
    end,
  '';

  # ACP-based adapters
  acpAdapters = ''
    opencode = function()
      return require("codecompanion.adapters").extend("claude_code", {
        name = "opencode",
        formatted_name = "OpenCode",
        commands = {
          default = { "opencode", "acp", "-m", "opencode/big-pickle" },
        },
      })
    end,
  '';
in
{
  options.programs.neovim.ai.enable = lib.mkEnableOption "Neovim AI integration";

  config = lib.mkIf (config.programs.neovim.enable && config.programs.neovim.ai.enable) {
    programs.neovim = {
      plugins = with pkgs.vimPlugins; [
        {
          plugin = plenary-nvim;
          optional = true;
        }
        # CodeCompanion as the core AI source
        {
          plugin = codecompanion-nvim;
          optional = true;
          type = "lua";
          config = ''
              local function load_codecompanion()
                vim.cmd.packadd('plenary.nvim')
                vim.cmd.packadd('codecompanion.nvim')
                vim.cmd.packadd('markview.nvim')

                -- required for githubmodels token via gh
                vim.env["CODECOMPANION_TOKEN_PATH"] = vim.fn.expand("~/.config")
                local ai_strategy = os.getenv("AI_STRATEGY") or "${defaultStrategy}"

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
                  display = {
                    chat = {
                      intro_message = "Welcome to CodeCompanion ✨! Press <leader>h for options",
                    },
                  },
                  adapters = {
                    acp = {
                      opts = { show_defaults = false },
            ${acpAdapters}
                    },
                    http = {
                      -- hide adapters that I haven't explicitly configured
                      opts = { show_defaults = false, },
            ${httpAdapters}
                    }
                  },
                  extensions = {
                  }
                })

                require("markview").setup({
                  preview = {
                    filetypes = { "codecompanion" },
                    ignore_buftypes = {},
                  }
                })

                -- set final keymaps
                vim.keymap.set({ "n", "v" }, "<LocalLeader>A", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true, desc = "✨ Actions" })
                vim.keymap.set({ "n", "v" }, "<LocalLeader>a", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true, desc = "✨ Toggle Chat" })
                vim.keymap.set("v", "<LocalLeader>c", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true, desc = "✨ Add to Chat" })
              end

              -- Stub keymaps that load on first use
              vim.keymap.set({ "n", "v" }, "<LocalLeader>A", function()
                load_codecompanion()
                vim.cmd('CodeCompanionActions')
              end, { noremap = true, silent = true, desc = "✨ Actions" })

              vim.keymap.set({ "n", "v" }, "<LocalLeader>a", function()
                load_codecompanion()
                vim.cmd('CodeCompanionChat Toggle')
              end, { noremap = true, silent = true, desc = "✨ Toggle Chat" })

              vim.keymap.set("v", "<LocalLeader>c", function()
                load_codecompanion()
                vim.cmd('CodeCompanionChat Add')
              end, { noremap = true, silent = true, desc = "✨ Add to Chat" })

              -- CmdUndefined for :CodeCompanion commands
              vim.api.nvim_create_autocmd('CmdUndefined', {
                pattern = 'CodeCompanion*',
                once = true,
                callback = function()
                  load_codecompanion()
                  return true
                end
              })

              -- Expand 'cc' into 'CodeCompanion' in the command line
              vim.cmd([[cab cc CodeCompanion]])
          '';
        }

        # Markview for making codecompanion prettier
        {
          plugin = markview-nvim;
          optional = true;
        }
      ];
    };
  };
}
