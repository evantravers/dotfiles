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
                  on_open = function()
                    vim.o.scrolloff = 999
                    vim.o.relativenumber = false
                    vim.o.number = false
                    vim.o.wrap = true
                    vim.o.linebreak = true
                    vim.o.colorcolumn = "0"

                    -- Blend the statuscolumn into the text background.
                    -- Window-local, so no restore needed: zen-mode discards
                    -- this window on close. NOTE: must append, not replace --
                    -- zen-mode sets its own winhighlight (NormalFloat:Normal)
                    -- to give the floating window the editor background.
                    local statuscolumn_hl = table.concat({
                      'LineNr:Normal',
                      'CursorLineNr:Normal',
                      'SignColumn:Normal',
                      'FoldColumn:Normal',
                      'MiniStatuscolumnSep:Normal',
                      'MiniStatuscolumnSepCursor:Normal',
                    }, ',')
                    local existing = vim.wo.winhighlight
                    if #existing > 0 then
                      vim.wo.winhighlight = existing .. ',' .. statuscolumn_hl
                    else
                      vim.wo.winhighlight = statuscolumn_hl
                    end

                    vim.keymap.set('n', 'j', 'gj', {noremap = true, buffer = true})
                    vim.keymap.set('n', 'k', 'gk', {noremap = true, buffer = true})
                  end,
                  on_close = function()
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
