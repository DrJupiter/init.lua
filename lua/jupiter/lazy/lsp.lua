local lsp_servers = {
    {
        name = "lua_ls",
        mason = "lua-language-server",
        config = {
            settings = {
                Lua = {
                    workspace = { checkThirdParty = false },
                    telemetry = { enable = false },
                    hint = { enable = true },
                },
            },
        },
    },
    {
        name = "basedpyright",
        mason = "basedpyright",
        config = {
            settings = {
                python = {
                    analysis = {
                        autoImportCompletions = true,
                        diagnosticMode = "workspace",
                        typeCheckingMode = "basic",
                    },
                },
            },
        },
    },
    { name = "ruff", mason = "ruff" },
    { name = "rust_analyzer", mason = "rust-analyzer" },
    { name = "clangd", mason = "clangd" },
    { name = "dockerls", mason = "dockerfile-language-server" },
    { name = "lemminx", mason = "lemminx" },
    { name = "bashls", mason = "bash-language-server" },
    { name = "jsonls", mason = "json-lsp" },
    { name = "yamlls", mason = "yaml-language-server" },
    { name = "html", mason = "html-lsp" },
    { name = "cssls", mason = "css-lsp" },
    { name = "ts_ls", mason = "typescript-language-server" },
    { name = "svelte", mason = "svelte-language-server" },
    { name = "ols", mason = "ols" },
}

local doxygen_inline = { code = "`", tt = "`", em = "*" }
local doxygen_drop = {
    a = true, span = true, pre = true, p = true, br = true,
    table = true, tr = true, td = true, li = true, ul = true, ol = true,
}

local function strip_doxygen(text)
    text = text:gsub("\\?<(/?)(%a[%w]*)([^<>]*)>", function(_, tag)
        tag = tag:lower()
        return doxygen_inline[tag] or (doxygen_drop[tag] and " ") or nil
    end)
    text = text:gsub("`([^`]*)`", function(inner)
        return "`" .. inner:gsub("\\(%p)", "%1") .. "`"
    end)
    return (text:gsub("%%(%a[%w_][%w_]+)", "%1"))
end

local to_markdown_lines = vim.lsp.util.convert_input_to_markdown_lines
vim.lsp.util.convert_input_to_markdown_lines = function(input, contents)
    local lines = to_markdown_lines(input, contents)
    for i, line in ipairs(lines or {}) do
        lines[i] = strip_doxygen(line)
    end
    return lines
end

local c_family = { c = true, cpp = true, cuda = true, objc = true, objcpp = true }

local open_floating_preview = vim.lsp.util.open_floating_preview
vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
    local source = vim.bo.filetype
    local buf, win = open_floating_preview(contents, syntax, opts, ...)

    if buf and syntax == "markdown" and c_family[source] then
        vim.b[buf].cpp_docs = true
        pcall(function()
            vim.treesitter.get_parser(buf):parse(true)
        end)
    end
    return buf, win
end

local mason_packages = {}
local server_settings = {}

for _, server in ipairs(lsp_servers) do
    if server.mason then
        table.insert(mason_packages, server.mason)
    end
    server_settings[server.name] = server.config or {}
end

return {
    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        opts = {
            ensure_installed = mason_packages,
        },
        config = function(_, opts)
            local mason = require("mason")
            mason.setup(opts)

            local registry = require("mason-registry")
            for _, tool in ipairs(opts.ensure_installed or {}) do
                local ok, pkg = pcall(registry.get_package, tool)
                if ok and not pkg:is_installed() then
                    pkg:install()
                end
            end
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-path",
            "williamboman/mason.nvim",
        },
        config = function()
            local cmp = require("cmp")
            local cmp_capabilities = require("cmp_nvim_lsp").default_capabilities()

            local defaults = rawget(vim.lsp.config, "*") or {}
            vim.lsp.config("*", vim.tbl_deep_extend("force", {}, defaults, {
                capabilities = vim.tbl_deep_extend("force", {}, defaults.capabilities or {}, cmp_capabilities),
            }))

            vim.api.nvim_create_autocmd("LspAttach", {
                desc = "LSP keymaps",
                callback = function(event)
                    local lsp_buf = vim.lsp.buf
                    local opts = { buffer = event.buf }

                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    local hover = lsp_buf.hover
                    if client.name == "clangd" then
                        hover = function()
                            require("jupiter.cppdoc").hover(client, event.buf)
                        end
                    end

                    vim.keymap.set("n", "K", hover, opts)
                    vim.keymap.set("n", "gd", lsp_buf.definition, opts)
                    vim.keymap.set("n", "gD", lsp_buf.declaration, opts)
                    vim.keymap.set("n", "gi", lsp_buf.implementation, opts)
                    vim.keymap.set("n", "go", lsp_buf.type_definition, opts)
                    vim.keymap.set("n", "gr", lsp_buf.references, opts)
                    vim.keymap.set("n", "gs", lsp_buf.signature_help, opts)
                    vim.keymap.set("n", "<leader>rn", lsp_buf.rename, { buffer = event.buf, desc = "LSP rename symbol" })
                    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {
                        buffer = event.buf,
                        desc = "Code action",
                    })
                    vim.keymap.set("n", "<leader>cf", function()
                        vim.lsp.buf.code_action({ apply = true, context = { only = { "quickfix", "source.fixAll" } } })
                    end, { desc = "Apply fix" })
                    vim.keymap.set({ "n", "x" }, "<F3>", function()
                        lsp_buf.format({ async = true })
                    end, opts)
                    vim.keymap.set("n", "<F4>", lsp_buf.code_action, opts)
                end,
            })

            for server, cfg in pairs(server_settings) do
                if cfg and next(cfg) ~= nil then
                    local existing = rawget(vim.lsp.config, server) or {}
                    vim.lsp.config(server, vim.tbl_deep_extend("force", {}, existing, cfg))
                end
            end

            vim.lsp.enable(vim.tbl_keys(server_settings))

            cmp.setup({
                sources = {
                    { name = "nvim_lsp" },
                    { name = "path" },
                },
                snippet = {
                    expand = function(args)
                        vim.snippet.expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-CR>"] = cmp.mapping.confirm({ select = true }),
                }),
            })
        end,
    },
}
