return {
  "catppuccin/nvim",
  name="catppuccin-latte",
  lazy = false,
  priority = 1000,
  config = function()
      vim.cmd([[colorscheme catppuccin-latte]])
  end
}
