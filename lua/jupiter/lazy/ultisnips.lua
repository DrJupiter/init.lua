return {
  "sirver/ultisnips",
  lazy = false,     -- we don't want to lazy load VimTeX
  -- tag = "v2.15", -- uncomment to pin to a specific release
  init = function()
    -- VimTeX configuration goes here, e.g.
    vim.g.UltiSnipsExpandTrigger = "<tab>"
    vim.g.UltiSnipsJumpForwardTrigger = "<tab>"
    vim.g.UltiSnipsJumpBackwardTrigger = "<s-tab>"
    vim.g.UltiSnipsEditSplit = 'vertical'
    vim.g.UltiSnipsSnippetDirectories = { os.getenv("HOME") .. '/.config/nvim/ultisnip' }
  end
}
