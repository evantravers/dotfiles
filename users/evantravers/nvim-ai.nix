{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.unstable.vimPlugins; [
      # CodeCompanion as the core AI source
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          pname = "codecompanion-nvim";
          version = "HEAD";
          src = pkgs.fetchFromGitHub {
            owner = "olimorris";
            repo = "codecompanion.nvim";
            rev = "0297731c8c0468f7172744d172e70766bfc2802c";
            sha256 = "sha256-RVGc/xnNG12ziNSngz7MAHDvypGGXOS1fL+QQ4OujHw=";
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
            strategies = {
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
                claude_code = function()
                  return require("codecompanion.adapters").extend("claude_code", {
                    env = {
                      ANTHROPIC_API_KEY = vim.env.ANTHROPIC_API_KEY
                    },
                  })
                end,
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
                openrouter_claude = function()
                  return require("codecompanion.adapters").extend("openai_compatible", {
                    env = {
                      url = "https://openrouter.ai/api",
                      -- api_key = "OPENROUTER_API_KEY",
                      api_key = "cmd:op read op://Private/OpenRouterAPI/credential --no-newline",
                      chat_url = "/v1/chat/completions",
                    },
                    schema = {
                      model = {
                        default = "anthropic/claude-3.7-sonnet:online",
                      },
                    },
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
              history = { enabled = true };
            }
          })

          vim.keymap.set({ "n", "v" }, "<LocalLeader>A", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true, desc = "✨ Actions" })
          vim.keymap.set({ "n", "v" }, "<LocalLeader>a", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true, desc = "✨ Toggle Chat" })
          vim.keymap.set("v", "<LocalLeader>c", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true, desc = "✨ Add to Chat" })

          -- Expand 'cc' into 'CodeCompanion' in the command line
          vim.cmd([[cab cc CodeCompanion]])
        '';
      }

      # mini.diff for changes
      # mini.notify to show LLM API call status
      {
        plugin = mini-nvim;
        type = "lua";
        config = ''
          local diff = require('mini.diff') -- hunk management and highlight
          diff.setup({source = diff.gen_source.none()})

          local MiniNotify = require('mini.notify') -- notifications
          local ids = {} -- CodeCompanion request ID --> MiniNotify notification ID
          local group = vim.api.nvim_create_augroup("CodeCompanionMiniNotifyHooks", {})

          local function format_status(ev)
            local name = ev.data.adapter.formatted_name or ev.data.adapter.name
            local msg = name .. " " .. ev.data.strategy .. " request..."
            local level, hl_group = "INFO", "DiagnosticInfo"
            if ev.data.status then
              msg = msg .. ev.data.status
              if ev.data.status ~= "success" then
                level, hl_group = "ERROR", "DiagnosticError"
              end
            end
            return msg, level, hl_group
          end

          vim.api.nvim_create_autocmd({ "User" }, {
            pattern = "CodeCompanionRequestStarted",
            group = group,
            callback = function(ev)
              local msg, level, hl_group = format_status(ev)
              ids[ev.data.id] = MiniNotify.add(msg, level, hl_group)
            end,
          })

          vim.api.nvim_create_autocmd({ "User" }, {
            pattern = "CodeCompanionRequestFinished",
            group = group,
            callback = function(ev)
              local msg, level, hl_group = format_status(ev)
              local mini_id = ids[ev.data.id]
              if mini_id then
                ids[ev.data.id] = nil
                MiniNotify.update(mini_id, { msg = msg, level = level, hl_group = hl_group })
              else
                mini_id = MiniNotify.add(msg, level, hl_group)
              end
              vim.defer_fn(function() MiniNotify.remove(mini_id) end, 5000)
            end,
          })
        '';
      }

      # Cache and restore previous chats
      codecompanion-history-nvim

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
