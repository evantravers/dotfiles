-- Load .vimrc
vim.cmd([[runtime .vimrc]])

-- Neovim specific settings
vim.o.icm = 'split'
-- vim.o.cia = 'kind,abbr,menu' wait for nightly to drop
vim.o.foldtext = "v:lua.vim.treesitter.foldtext()"

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

vim.o.showmode = false

-- Use rg
vim.o.grepprg = [[rg --glob "!.git" --no-heading --vimgrep --follow $*]]
vim.opt.grepformat = vim.opt.grepformat ^ { "%f:%l:%c:%m" }

vim.fn.sign_define("DiagnosticSignError", {text = "", hl = "DiagnosticSignError", texthl = "DiagnosticSignError", culhl = "DiagnosticSignErrorLine"})
vim.fn.sign_define("DiagnosticSignWarn", {text = "", hl = "DiagnosticSignWarn", texthl = "DiagnosticSignWarn", culhl = "DiagnosticSignWarnLine"})
vim.fn.sign_define("DiagnosticSignInfo", {text = "", hl = "DiagnosticSignInfo", texthl = "DiagnosticSignInfo", culhl = "DiagnosticSignInfoLine"})
vim.fn.sign_define("DiagnosticSignHint", {text = "", hl = "DiagnosticSignHint", texthl = "DiagnosticSignHint", culhl = "DiagnosticSignHintLine"})

-- Make <Tab> work for snippets
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
