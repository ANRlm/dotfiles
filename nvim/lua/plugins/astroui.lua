-- AstroUI provides the basis for configuring the AstroNvim User Interface
-- Configuration documentation can be found with `:h astroui`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    -- change colorscheme
    colorscheme = "nord",
    -- AstroUI allows you to easily modify highlight groups easily for any and all colorschemes
    highlights = {
      init = { -- this table overrides highlights in all themes
        -- Normal = { bg = "#000000" },
      },
      nord = {
        TabLine = { fg = "#d8dee9", bg = "#2e3440" },
        TabLineFill = { fg = "#2e3440", bg = "#2e3440" },
        TabLineSel = { fg = "#eceff4", bg = "#3b4252", bold = true },
        WinBar = { fg = "#d8dee9", bg = "#2e3440" },
        WinBarNC = { fg = "#4c566a", bg = "#2e3440" },
        NeoTreeTabActive = { fg = "#eceff4", bg = "#2e3440", bold = true },
        NeoTreeTabInactive = { fg = "#81a1c1", bg = "#2e3440" },
        NeoTreeTabSeparatorActive = { fg = "#4c566a", bg = "#2e3440" },
        NeoTreeTabSeparatorInactive = { fg = "#4c566a", bg = "#2e3440" },
      },
      astrodark = { -- a table of overrides/changes when applying the astrotheme theme
        -- Normal = { bg = "#000000" },
      },
    },
    -- Icons can be configured throughout the interface
    icons = {
      -- configure the loading of the lsp in the status line
      LSPLoading1 = "⠋",
      LSPLoading2 = "⠙",
      LSPLoading3 = "⠹",
      LSPLoading4 = "⠸",
      LSPLoading5 = "⠼",
      LSPLoading6 = "⠴",
      LSPLoading7 = "⠦",
      LSPLoading8 = "⠧",
      LSPLoading9 = "⠇",
      LSPLoading10 = "⠏",
    },
  },
}
