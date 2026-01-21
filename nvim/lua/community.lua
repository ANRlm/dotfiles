-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity/colorscheme/rose-pine" },
  -- import/override with your plugins folder

  -- {
  --   "rose-pine/neovim",
  --   name = "rose-pine",
  --   opts = {
  --     disable_background = true,
  --     disable_float_background = true,
  --   },
  -- },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    opts = function()
      if vim.g.neovide then
        return {
          disable_background = false,
          disable_float_background = false,
        }
      else
        return {
          disable_background = true,
          disable_float_background = true,
        }
      end
    end,
  },
}
