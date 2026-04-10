return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    mappings = {
      n = {
        H = {
          function() require("astrocore.buffer").nav(-1) end,
          desc = "Previous buffer",
        },
        L = {
          function() require("astrocore.buffer").nav(1) end,
          desc = "Next buffer",
        },
      },
    },
  },
}
