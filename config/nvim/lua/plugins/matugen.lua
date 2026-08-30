return {
  {
    "LazyVim/LazyVim",
    -- Same as the pre-LazyVim config: no colorscheme set at all.
    -- `opts.colorscheme` is LazyVim's supported override point (as a function),
    -- so we skip tokyonight entirely and apply the matugen palette directly.
    opts = function(_, opts)
      opts.colorscheme = function()
        require("config.autocmds").apply()
      end
    end,
  },
}