return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {
    autoload = true,
  },
  keys = {
    { "<leader>qd", function() require("persistence").stop() end, desc = "Don't save current session" },
  },
}
