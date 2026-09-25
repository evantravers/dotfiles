{ config, lib, pkgs, ... }:
{
  options.programs.neovim.prose.enable = lib.mkEnableOption "Neovim prose mode";

  config = lib.mkIf (config.programs.neovim.enable && config.programs.neovim.prose.enable) {
    programs.neovim = {
      plugins = with pkgs.vimPlugins; [
        {
          plugin = zen-mode-nvim;
          optional = true;
          type = "lua";
          config = ''
            -- set keybind for searching my wiki (no zen-mode dependency)
            vim.keymap.set('n', '<space>m', function()
              vim.cmd.packadd('zen-mode.nvim')

              function _G.toggleProse()
                require("zen-mode").toggle({
                  window = {
                    backdrop = 1,
                    width = 80
                  },
                  plugins = {
                    tmux = { enabled = false }
                  },
                  on_open = function(win)
                    -- make background transparent so it exactly matches the
                    -- terminal background; restored in on_close
                    _G.proseSavedHl = {}
                    for _, group in ipairs({'Normal', 'NormalNC', 'EndOfBuffer', 'SignColumn', 'FoldColumn', 'NormalFloat', 'ZenBg'}) do
                      local hl = vim.api.nvim_get_hl(0, { name = group })
                      hl.link = nil
                      _G.proseSavedHl[group] = hl
                      vim.api.nvim_set_hl(0, group, vim.tbl_extend('force', hl, { bg = 'NONE', ctermbg = 'NONE' }))
                    end

                    vim.o.scrolloff = 999
                    vim.o.relativenumber = false
                    vim.o.number = false
                    vim.o.wrap = true
                    vim.o.linebreak = true
                    vim.o.colorcolumn = "0"

                    vim.wo[win].statuscolumn = ""
                    vim.wo[win].signcolumn = 'no'
                    vim.wo[win].foldcolumn = '0'

                    vim.keymap.set('n', 'j', 'gj', {noremap = true, buffer = true})
                    vim.keymap.set('n', 'k', 'gk', {noremap = true, buffer = true})
                  end,
                  on_close = function()
                    for group, hl in pairs(_G.proseSavedHl or {}) do
                      vim.api.nvim_set_hl(0, group, hl)
                    end
                    _G.proseSavedHl = nil

                    vim.o.scrolloff = 3
                    vim.o.number = true
                    vim.o.relativenumber = true
                    vim.o.wrap = false
                    vim.o.linebreak = false
                    vim.o.colorcolumn = "80"

                    vim.keymap.set('n', 'j', 'j', {noremap = true, buffer = true})
                    vim.keymap.set('n', 'k', 'k', {noremap = true, buffer = true})
                  end
                })
              end

              -- replace keymap with direct call after first load
              vim.keymap.set('n', '<space>m', ':lua _G.toggleProse()<cr>', {noremap = true, silent = true, desc = "Toggle Writing Mode"})
              _G.toggleProse()
            end, {noremap = true, silent = true, desc = "Toggle Writing Mode"})
          '';
        }
      ];
    };
  };
}
