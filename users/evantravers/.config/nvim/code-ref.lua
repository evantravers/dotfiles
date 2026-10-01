-- Copy a code reference to the clipboard for pasting into an LLM chat.
-- Normal mode: `@path/from/cwd.lua lines:42`
-- Visual mode: also includes the selection as a fenced code block below.
local function copy_code_ref()
  local bufnr = 0
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == '' then
    vim.notify('Buffer has no file name', vim.log.levels.WARN)
    return
  end

  -- @mention convention: relative to cwd, ~/... fallback outside it
  file = '@' .. vim.fn.fnamemodify(file, ':~:.')

  local mode = vim.fn.mode()
  local text, summary
  if mode:match('^[vV\022]') then
    local s = vim.fn.getpos('v')
    local e = vim.fn.getpos('.')
    if s[2] > e[2] or (s[2] == e[2] and s[3] > e[3]) then
      s, e = e, s
    end
    local lines = vim.fn.getregion(s, e, { type = mode })
    local header = s[2] == e[2]
      and string.format('%s lines:%d', file, s[2])
      or string.format('%s lines:%d-%d', file, s[2], e[2])
    text = string.format('%s\n\n```%s\n%s\n```', header, vim.bo[bufnr].filetype, table.concat(lines, '\n'))
    summary = header
    -- leave visual mode
    local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
    vim.api.nvim_feedkeys(esc, 'n', false)
  else
    text = string.format('%s lines:%d', file, vim.fn.line('.'))
    summary = text
  end

  vim.fn.setreg('+', text)
  vim.notify('Copied: ' .. summary)
end

vim.keymap.set({ 'n', 'v' }, '<leader>y', copy_code_ref, { desc = 'Copy code reference (path:line + selection)' })
