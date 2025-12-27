return {
  -- Rose Pine 主题（当前激活）
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        variant = "auto", -- auto, main, moon, 或 dawn
        dark_variant = "main", -- main, moon, 或 dawn
        dim_inactive_windows = false,
        extend_background_behind_borders = true,

        enable = {
          terminal = true,
          legacy_highlights = true, -- 改善插件兼容性
          migrations = true,
        },

        styles = {
          bold = true,
          italic = true,
          transparency = true, -- 启用透明背景
        },

        groups = {
          border = "muted",
          link = "iris",
          panel = "surface",

          error = "love",
          hint = "iris",
          info = "foam",
          note = "pine",
          todo = "rose",
          warn = "gold",

          git_add = "foam",
          git_change = "rose",
          git_delete = "love",
          git_dirty = "rose",
          git_ignore = "muted",
          git_merge = "iris",
          git_rename = "pine",
          git_stage = "iris",
          git_text = "rose",
          git_untracked = "subtle",

          h1 = "iris",
          h2 = "foam",
          h3 = "rose",
          h4 = "gold",
          h5 = "pine",
          h6 = "foam",
        },

        highlight_groups = {
          -- 浮动窗口美化
          NormalFloat = { bg = "surface" },
          FloatBorder = { fg = "iris", bg = "surface" },
          FloatTitle = { fg = "iris", bg = "surface", bold = true },

          -- 弹出菜单美化
          Pmenu = { fg = "text", bg = "surface" },
          PmenuSel = { fg = "base", bg = "iris" },

          -- Telescope 美化
          TelescopeBorder = { fg = "iris", bg = "base" },
          TelescopePromptBorder = { fg = "iris", bg = "surface" },
          TelescopePromptNormal = { fg = "text", bg = "surface" },
          TelescopePromptPrefix = { fg = "iris", bg = "surface" },
          TelescopePromptTitle = { fg = "base", bg = "iris", bold = true },
          TelescopePreviewTitle = { fg = "base", bg = "foam", bold = true },
          TelescopeResultsTitle = { fg = "base", bg = "rose", bold = true },
          TelescopeSelection = { fg = "iris", bg = "overlay" },
          TelescopeMatching = { fg = "gold", bold = true },

          -- Which-key 美化
          WhichKey = { fg = "iris" },
          WhichKeyGroup = { fg = "rose" },
          WhichKeyDesc = { fg = "text" },
          WhichKeySeparator = { fg = "muted" },
          WhichKeyFloat = { bg = "surface" },

          -- 光标行
          CursorLine = { bg = "surface" },
          CursorLineNr = { fg = "iris", bold = true },
        },
      })

      -- 加载主题
      vim.cmd("colorscheme rose-pine")
    end,
  },

  -- Nord 主题（备用）
  {
    "shaunsingh/nord.nvim",
    lazy = true, -- 改为 lazy 加载，需要时才加载
    priority = 1000,
    config = function()
      -- Nord 主题配置

      -- 启用侧边栏和弹出菜单的对比色背景（如 nvim-tree, telescope）
      vim.g.nord_contrast = true

      -- 显示垂直分割窗口之间的边框
      vim.g.nord_borders = true

      -- 禁用背景色，使用终端背景（透明效果）
      vim.g.nord_disable_background = true

      -- 光标行透明/可见
      vim.g.nord_cursorline_transparent = false

      -- 重新启用侧边栏背景
      vim.g.nord_enable_sidebar_background = true

      -- 启用斜体（注释、关键字等）
      vim.g.nord_italic = true

      -- 启用粗体
      vim.g.nord_bold = true

      -- diff 模式使用统一背景色
      vim.g.nord_uniform_diff_background = true

      -- 加载主题
      require("nord").set()

      -- 自定义高亮增强

      -- Nord 调色板
      local colors = {
        -- 极夜 (Polar Night)
        nord0 = "#2E3440", -- 背景
        nord1 = "#3B4252", -- 较亮背景
        nord2 = "#434C5E", -- 选中/高亮
        nord3 = "#4C566A", -- 注释/不活跃
        -- 雪暴 (Snow Storm)
        nord4 = "#D8DEE9", -- 主文本
        nord5 = "#E5E9F0", -- 较亮文本
        nord6 = "#ECEFF4", -- 最亮文本
        -- 冰霜 (Frost)
        nord7 = "#8FBCBB",  -- 青绿色
        nord8 = "#88C0D0",  -- 冰蓝色
        nord9 = "#81A1C1",  -- 蓝色
        nord10 = "#5E81AC", -- 深蓝色
        -- 极光 (Aurora)
        nord11 = "#BF616A", -- 红色
        nord12 = "#D08770", -- 橙色
        nord13 = "#EBCB8B", -- 黄色
        nord14 = "#A3BE8C", -- 绿色
        nord15 = "#B48EAD", -- 紫色
      }

      -- 增强高亮组
      vim.api.nvim_set_hl(0, "CursorLine", { bg = colors.nord1 })
      vim.api.nvim_set_hl(0, "CursorLineNr", { fg = colors.nord8, bold = true })
      vim.api.nvim_set_hl(0, "LineNr", { fg = colors.nord3 })
      vim.api.nvim_set_hl(0, "Visual", { bg = colors.nord2 })
      vim.api.nvim_set_hl(0, "Search", { fg = colors.nord0, bg = colors.nord13 })
      vim.api.nvim_set_hl(0, "IncSearch", { fg = colors.nord0, bg = colors.nord12 })

      -- 浮动窗口美化
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = colors.nord1 })
      vim.api.nvim_set_hl(0, "FloatBorder", { fg = colors.nord8, bg = colors.nord1 })
      vim.api.nvim_set_hl(0, "FloatTitle", { fg = colors.nord8, bg = colors.nord1, bold = true })

      -- 弹出菜单美化
      vim.api.nvim_set_hl(0, "Pmenu", { fg = colors.nord4, bg = colors.nord1 })
      vim.api.nvim_set_hl(0, "PmenuSel", { fg = colors.nord0, bg = colors.nord8 })
      vim.api.nvim_set_hl(0, "PmenuSbar", { bg = colors.nord2 })
      vim.api.nvim_set_hl(0, "PmenuThumb", { bg = colors.nord8 })

      -- 诊断信息美化
      vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = colors.nord11, italic = true })
      vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = colors.nord13, italic = true })
      vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = colors.nord8, italic = true })
      vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = colors.nord14, italic = true })

      -- Git 标记美化
      vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = colors.nord14 })
      vim.api.nvim_set_hl(0, "GitSignsChange", { fg = colors.nord13 })
      vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = colors.nord11 })

      -- Telescope 美化
      vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = colors.nord8, bg = colors.nord0 })
      vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = colors.nord8, bg = colors.nord1 })
      vim.api.nvim_set_hl(0, "TelescopePromptNormal", { fg = colors.nord4, bg = colors.nord1 })
      vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { fg = colors.nord8, bg = colors.nord1 })
      vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = colors.nord0, bg = colors.nord8, bold = true })
      vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = colors.nord0, bg = colors.nord14, bold = true })
      vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = colors.nord0, bg = colors.nord15, bold = true })
      vim.api.nvim_set_hl(0, "TelescopeSelection", { fg = colors.nord8, bg = colors.nord2 })
      vim.api.nvim_set_hl(0, "TelescopeMatching", { fg = colors.nord13, bold = true })

      -- Which-key 美化
      vim.api.nvim_set_hl(0, "WhichKey", { fg = colors.nord8 })
      vim.api.nvim_set_hl(0, "WhichKeyGroup", { fg = colors.nord15 })
      vim.api.nvim_set_hl(0, "WhichKeyDesc", { fg = colors.nord4 })
      vim.api.nvim_set_hl(0, "WhichKeySeparator", { fg = colors.nord3 })
      vim.api.nvim_set_hl(0, "WhichKeyFloat", { bg = colors.nord1 })

      -- Indent-blankline 美化
      vim.api.nvim_set_hl(0, "IblIndent", { fg = colors.nord2 })
      vim.api.nvim_set_hl(0, "IblScope", { fg = colors.nord8 })

      -- Nvim-tree / Neo-tree 美化
      vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", { fg = colors.nord9 })
      vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = colors.nord9 })
      vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", { fg = colors.nord8, bold = true })
      vim.api.nvim_set_hl(0, "NvimTreeRootFolder", { fg = colors.nord15, bold = true })
      vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", { fg = colors.nord9 })
      vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = colors.nord9 })
      vim.api.nvim_set_hl(0, "NeoTreeRootName", { fg = colors.nord15, bold = true })

      -- Dashboard / Alpha 美化
      vim.api.nvim_set_hl(0, "DashboardHeader", { fg = colors.nord8 })
      vim.api.nvim_set_hl(0, "DashboardCenter", { fg = colors.nord9 })
      vim.api.nvim_set_hl(0, "DashboardShortCut", { fg = colors.nord15 })
      vim.api.nvim_set_hl(0, "DashboardFooter", { fg = colors.nord3, italic = true })

      -- 匹配括号美化
      vim.api.nvim_set_hl(0, "MatchParen", { fg = colors.nord13, bg = colors.nord2, bold = true })

      -- TODO/FIXME 高亮
      vim.api.nvim_set_hl(0, "Todo", { fg = colors.nord0, bg = colors.nord13, bold = true })

      -- 窗口分隔线
      vim.api.nvim_set_hl(0, "WinSeparator", { fg = colors.nord3 })
      vim.api.nvim_set_hl(0, "VertSplit", { fg = colors.nord3 })
    end,
  },
}

-- 主题切换命令
-- 使用 :colorscheme rose-pine 切换到 Rose Pine
-- 使用 :colorscheme nord 切换到 Nord

