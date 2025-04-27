-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '<leader>e', ':Neotree reveal toggle<CR>', desc = 'Toggle Neotree', silent = true },
  },
  opts = {
    sources = { 'filesystem', 'buffers', 'git_status', 'document_symbols' },
    source_selector = {
      winbar = true,
      sources = {
        { source = 'filesystem', display_name = ' Files' },
        { source = 'buffers', display_name = ' Bufs' },
        { source = 'git_status', display_name = ' Git' },
        { source = 'document_symbols', display_name = ' Symbols' },
      },
    },
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
}
