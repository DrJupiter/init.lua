local function path_exists(path)
  return vim.loop.fs_stat(path) ~= nil
end

local function get_python_adapter_path()
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return nil
  end

  if not registry.is_installed("debugpy") then
    vim.notify("debugpy is not installed yet. Install it with :MasonInstall debugpy to enable Python debugging.", vim.log.levels.WARN)
    return nil
  end

  local InstallLocation = require("mason-core.installer.InstallLocation")
  local install_path = InstallLocation.global():package("debugpy")
  local os_name = vim.loop.os_uname().sysname
  if os_name == "Windows_NT" then
    local win_path = install_path .. "\\venv\\Scripts\\python.exe"
    if path_exists(win_path) then
      return win_path
    end
  else
    local unix_path = install_path .. "/venv/bin/python"
    if path_exists(unix_path) then
      return unix_path
    end
  end

  return nil
end

local function configure_codelldb(dap)
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return
  end

  if not registry.is_installed("codelldb") then
    vim.notify("codelldb is not installed yet. Install it with :MasonInstall codelldb to enable C/C++/Rust debugging.", vim.log.levels.WARN)
    return
  end

  local InstallLocation = require("mason-core.installer.InstallLocation")
  local install_path = InstallLocation.global():package("codelldb")
  local extension_path = install_path .. "/extension/"
  local codelldb_path = extension_path .. "adapter/codelldb"
  local os_name = vim.loop.os_uname().sysname

  if os_name == "Darwin" then
    codelldb_path = extension_path .. "adapter/codelldb"
  elseif os_name == "Windows_NT" then
    codelldb_path = extension_path .. "adapter\\codelldb.exe"
  end

  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
      command = codelldb_path,
      args = { "--port", "${port}" },
    },
  }

  dap.configurations.cpp = {
    {
      name = "Launch file",
      type = "codelldb",
      request = "launch",
      program = function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
    },
    {
      name = "Attach to process",
      type = "codelldb",
      request = "attach",
      pid = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
    },
  }

  dap.configurations.c = dap.configurations.cpp
  dap.configurations.rust = dap.configurations.cpp
end

return {
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "debugpy", "codelldb" },
      automatic_installation = true,
    },
    config = function(_, opts)
      require("mason-nvim-dap").setup(opts)
    end,
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "mfussenegger/nvim-dap-python",
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      require("nvim-dap-virtual-text").setup({
        commented = true,
      })

      dapui.setup({
        controls = {
          element = "repl",
          enabled = true,
        },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.6 },
              { id = "stacks", size = 0.2 },
              { id = "watches", size = 0.2 },
            },
            position = "right",
            size = 40,
          },
          {
            elements = {
              "repl",
              "console",
            },
            position = "bottom",
            size = 10,
          },
        },
      })

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      configure_codelldb(dap)

      local python_path = get_python_adapter_path()
      local dap_python = require("dap-python")
      dap_python.setup(python_path or "python3")
      dap_python.test_runner = "pytest"

      local ok_registry, registry = pcall(require, "mason-registry")
      if ok_registry then
        local ok_codelldb, codelldb_pkg = pcall(registry.get_package, "codelldb")
        if ok_codelldb and not codelldb_pkg:is_installed() then
          codelldb_pkg:once("install:success", function()
            configure_codelldb(dap)
            vim.notify("codelldb installed. C/C++/Rust debugging ready.", vim.log.levels.INFO)
          end)
        end

        local ok_debugpy, debugpy_pkg = pcall(registry.get_package, "debugpy")
        if ok_debugpy and not debugpy_pkg:is_installed() then
          debugpy_pkg:once("install:success", function()
            local new_python_path = get_python_adapter_path()
            dap_python.setup(new_python_path or "python3")
            vim.notify("debugpy installed. Python debugging ready.", vim.log.levels.INFO)
          end)
        end
      end

      local keymap = vim.keymap.set
      keymap("n", "<F5>", dap.continue, { desc = "DAP continue / start" })
      keymap("n", "<F6>", dap.pause, { desc = "DAP pause" })
      keymap("n", "<F10>", dap.step_over, { desc = "DAP step over" })
      keymap("n", "<F11>", dap.step_into, { desc = "DAP step into" })
      keymap("n", "<F12>", dap.step_out, { desc = "DAP step out" })
      keymap("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
      keymap("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "DAP set conditional breakpoint" })
      keymap("n", "<leader>dl", dap.run_last, { desc = "DAP run last" })
      keymap("n", "<leader>dr", dap.repl.toggle, { desc = "DAP toggle REPL" })
      keymap({ "n", "v" }, "<leader>de", function()
        dapui.eval(nil, { enter = true })
      end, { desc = "DAP evaluate expression" })
      keymap("n", "<leader>du", dapui.toggle, { desc = "DAP toggle UI" })
      keymap("n", "<leader>dc", function()
        dapui.float_element("console", { enter = true })
      end, { desc = "DAP open console" })
    end,
  },
}
