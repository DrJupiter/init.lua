return {
  "sirver/ultisnips",
  lazy = false,
  -- tag = "v2.15", -- uncomment to pin to a specific release
  init = function()
    vim.g.UltiSnipsExpandTrigger = "<tab>"
    vim.g.UltiSnipsJumpForwardTrigger = "<tab>"
    vim.g.UltiSnipsJumpBackwardTrigger = "<s-tab>"
    vim.g.UltiSnipsEditSplit = 'vertical'
    vim.g.UltiSnipsSnippetDirectories = { os.getenv("HOME") .. '/.config/nvim/ultisnip' }
  end
}
