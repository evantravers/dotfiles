local terminal = "com.superlogical.terminal"

-- sesh picker in a split beside the focused pane, placed the way
-- pane.split.auto would: side by side when the pane is wider than it
-- is tall, stacked otherwise. (Floating layers would be closer to the
-- tmux C-p popup, but rex draws them with no background.) rsesh
-- (rex.nix) does the picking and switches this client's session; the
-- split closes itself when rsesh exits.
rex.action{
  name  = "sesh",
  title = "Pick a Sesh…",
  keywords = "session repository project zoxide",
  run   = function(ctx, args)
    local direction = "vertical"
    local size = ctx.block_id and rex.block.call(terminal, "size", { block_id = ctx.block_id })
    if size and size.columns * size.cell_width_px > size.rows * size.cell_height_px then
      direction = "horizontal"
    end

    local _, err = rex.session.new_split{
      anchor_id = ctx.block_id,
      direction = direction,
      side      = "after",
      focus     = true,
      layout    = rex.layout.block{
        flavor  = terminal .. ".shell",
        options = { command = { "rsesh", ctx.client_id } },
      },
    }
    if err ~= nil then error(err, 0) end
  end,
}

rex.bind("cmd+p", "sesh")
