-- Load .vimrc
vim.cmd([[runtime .vimrc]])

-- Neovim specific settings
vim.o.icm = 'split'
vim.opt.foldtext = "v:lua.vim.treesitter.foldtext()"

vim.o.showmode = false

-- Use rg
vim.o.grepprg = [[rg --glob "!.git" --no-heading --vimgrep --follow $*]]
vim.opt.grepformat = vim.opt.grepformat ^ { "%f:%l:%c:%m" }

vim.fn.sign_define("DiagnosticSignError", {text = "", hl = "DiagnosticSignError", texthl = "DiagnosticSignError", culhl = "DiagnosticSignErrorLine"})
vim.fn.sign_define("DiagnosticSignWarn", {text = "", hl = "DiagnosticSignWarn", texthl = "DiagnosticSignWarn", culhl = "DiagnosticSignWarnLine"})
vim.fn.sign_define("DiagnosticSignInfo", {text = "", hl = "DiagnosticSignInfo", texthl = "DiagnosticSignInfo", culhl = "DiagnosticSignInfoLine"})
vim.fn.sign_define("DiagnosticSignHint", {text = "", hl = "DiagnosticSignHint", texthl = "DiagnosticSignHint", culhl = "DiagnosticSignHintLine"})

-- PROSE MODE
-- I write prose in markdown, all the following is to help with that.
function _G.toggleProse()
  require("zen-mode").toggle({
    window = {
      backdrop = 1,
      width = 80
    },
    plugins = {
      gitsigns = { enabled = true },
      tmux = { enabled = true },
      kitty = {
        enabled = true,
      },
    },
    on_open = function()
      if (vim.bo.filetype == "markdown" or vim.bo.filetype == "telekasten") then
        vim.cmd 'set so=999'
        vim.cmd 'set nornu nonu'
        vim.cmd 'set wrap'
        vim.cmd 'set linebreak'
        vim.cmd 'set colorcolumn=0'

        vim.keymap.set('n', 'j', 'gj', {noremap = true})
        vim.keymap.set('n', 'k', 'gk', {noremap = true})
      end
    end,
    on_close = function()
      vim.cmd 'set so=3'
      vim.cmd 'set rnu'
      if (vim.bo.filetype == "markdown" or vim.bo.filetype == "telekasten") then
        vim.cmd 'set nowrap'
        vim.cmd 'set nolinebreak'
        vim.cmd 'set colorcolumn=80'
      end

      vim.keymap.set('n', 'j', 'j', {noremap = true})
      vim.keymap.set('n', 'k', 'k', {noremap = true})
    end
  })
end

vim.keymap.set(
  'n',
  '<localleader>m',
  ':lua _G.toggleProse()<cr>',
  {noremap = true, silent = true, desc = "Toggle Writing Mode"}
)

vim.keymap.set({ 'i', 's' }, '<Tab>', function()
   if vim.snippet.active({ direction = 1 }) then
     return '<cmd>lua vim.snippet.jump(1)<cr>'
   else
     return '<Tab>'
   end
 end, { expr = true })

-- Covenience macros
-- fix ellipsis: "..." -> "…"
vim.keymap.set('n',
  '<leader>fe',
  "mc:%s,\\.\\.\\.,…,g<CR>:nohlsearch<CR>`c",
  {noremap = true, silent = true, desc = "... -> …"})
-- fix spelling: just an easier finger roll on 40% keyboard
vim.keymap.set('n',
  '<leader>fs',
  '1z=',
  {noremap = true, silent = true, desc = "Fix spelling under cursor"})
