return {
    'nvim-telescope/telescope.nvim',
    version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope-live-grep-args.nvim', version = '^1.0.0' },
    },
    config = function()
        local telescope = require('telescope')
        local lga_actions = require('telescope-live-grep-args.actions')
        telescope.setup({
            extensions = {
                live_grep_args = {
                    auto_quoting = true,
                    mappings = {
                        i = {
                            ['<C-k>'] = lga_actions.quote_prompt(),
                            ['<C-i>'] = lga_actions.quote_prompt({ postfix = ' --iglob ' }),
                        },
                    },
                },
            },
        })
        telescope.load_extension('live_grep_args')
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = 'Telescope find files' })
        vim.keymap.set('n', '<leader>pg', function()
            require('telescope').extensions.live_grep_args.live_grep_args({
                additional_args = { '--hidden' },
            })
        end, { desc = 'Telescope live grep' })
    end
}
