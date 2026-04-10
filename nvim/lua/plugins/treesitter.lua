-- Customize Treesitter
-- In AstroNvim v6, treesitter is configured through AstroCore

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      ensure_installed = "all",
      ignore_install = { "ipkg" },
    },
  },
}
