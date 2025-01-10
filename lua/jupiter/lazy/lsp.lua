return {
 "neovim/nvim-lspconfig",
 dependencies = {
     "hrsh7th/nvim-cmp",
     "hrsh7th/cmp-nvim-lsp"
 },
 config = function ()
     local lspconfig_defaults = require('lspconfig').util.default_config
     lspconfig_defaults.capabilities = vim.tbl_deep_extend(
     'force',
     lspconfig_defaults.capabilities,
     require('cmp_nvim_lsp').default_capabilities()
     )

     -- This is where you enable features that only work
     -- if there is a language server active in the file
     vim.api.nvim_create_autocmd('LspAttach', {
         desc = 'LSP actions',
         callback = function(event)
             local opts = {buffer = event.buf}
             vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
             vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
             vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
             vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
             vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
             vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
             vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
             vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
             vim.keymap.set({'n', 'x'}, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
             vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
         end,
     })

     -- You'll find a list of language servers here:
     -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
     -- These are example language servers. 
     -- require('lspconfig').gleam.setup({})
     -- require('lspconfig').ocamllsp.setup({})
     require('lspconfig').pyright.setup{}
     require('lspconfig').rust_analyzer.setup{}
     require'lspconfig'.html.setup{}
     require'lspconfig'.cssls.setup{}
     require'lspconfig'.ts_ls.setup{}
     require'lspconfig'.svelte.setup{}
     require'lspconfig'.lua_ls.setup {
         on_init = function(client)
             if client.workspace_folders then
                 local path = client.workspace_folders[1].name
                 if vim.uv.fs_stat(path..'/.luarc.json') or vim.uv.fs_stat(path..'/.luarc.jsonc') then
                     return
                 end
             end

             client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
                 runtime = {
                     -- Tell the language server which version of Lua you're using
                     -- (most likely LuaJIT in the case of Neovim)
                     version = 'LuaJIT'
                 },
                 -- Make the server aware of Neovim runtime files
                 workspace = {
                     checkThirdParty = false,
                     library = {
                         vim.env.VIMRUNTIME
                         -- Depending on the usage, you might want to add additional paths here.
                         -- "${3rd}/luv/library"
                         -- "${3rd}/busted/library",
                     }
                     -- or pull in all of 'runtimepath'. NOTE: this is a lot slower and will cause issues when working on your own configuration (see https://github.com/neovim/nvim-lspconfig/issues/3189)
                     -- library = vim.api.nvim_get_runtime_file("", true)
                 }
             })
         end,
         settings = {
             Lua = {}
         }
     }

     local cmp = require('cmp')

     cmp.setup({
         sources = {
             {name = 'nvim_lsp'},
         },
         snippet = {
             expand = function(args)
                 -- You need Neovim v0.10 to use vim.snippet
                 vim.snippet.expand(args.body)
             end,
         },
         mapping = cmp.mapping.preset.insert({
             ['<C-CR>'] = cmp.mapping.confirm({ select = true }),
         }),
     })
end
}
