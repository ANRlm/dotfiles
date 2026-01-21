return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    mappings = {
      n = {
        H = {
          function() require("astrocore.buffer").nav(-1) end,
          desc = "next buffer",
        },
        L = {
          function() require("astrocore.buffer").nav(1) end,
          desc = "prev buffer",
        },
      },
    },
  },
}
