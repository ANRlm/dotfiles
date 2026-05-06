---@type LazySpec
return {
  {
    "neanias/everforest-nvim",
    lazy = false,
    priority = 1000,
    opts = {
      background = "hard",
      transparent_background_level = 0,
      italics = true,
      disable_italic_comments = false,
      ui_contrast = "high",
      dim_inactive_windows = false,
      diagnostic_text_highlight = false,
      diagnostic_line_highlight = false,
      diagnostic_virtual_text = "colored",
    },
    config = function(_, opts)
      require("everforest").setup(opts)
    end,
  },
}
