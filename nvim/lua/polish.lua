-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Polish: 最终高亮调整 (在主题加载后执行)

-- 主题调色板
local palettes = {
  nord = {
    bg0 = "#2E3440",
    bg1 = "#3B4252",
    bg2 = "#434C5E",
    bg3 = "#4C566A",
    comment = "#616E88",
    fg = "#D8DEE9",
    cyan = "#8FBCBB",
    blue = "#88C0D0",
    blue2 = "#81A1C1",
    red = "#BF616A",
    orange = "#D08770",
    yellow = "#EBCB8B",
    green = "#A3BE8C",
    purple = "#B48EAD",
  },
  ["rose-pine"] = {
    bg0 = "#191724",
    bg1 = "#1f1d2e",
    bg2 = "#26233a",
    bg3 = "#6e6a86",
    comment = "#6e6a86",
    fg = "#e0def4",
    cyan = "#9ccfd8",
    blue = "#31748f",
    blue2 = "#c4a7e7",
    red = "#eb6f92",
    orange = "#ebbcba",
    yellow = "#f6c177",
    green = "#9ccfd8",
    purple = "#c4a7e7",
  },
}

-- 获取当前主题
local function get_current_theme()
  local colorscheme = vim.g.colors_name or ""
  if colorscheme:match("rose%-pine") then
    return "rose-pine"
  elseif colorscheme:match("nord") then
    return "nord"
  end
  return nil
end

-- 应用主题增强高亮
local function apply_theme_highlights()
  local theme = get_current_theme()
  if not theme or not palettes[theme] then return end

  local colors = palettes[theme]

  -- 语法高亮增强
  vim.api.nvim_set_hl(0, "Comment", { fg = colors.comment, italic = true })
  vim.api.nvim_set_hl(0, "Keyword", { fg = colors.blue2, bold = true })
  vim.api.nvim_set_hl(0, "Function", { fg = colors.blue })
  vim.api.nvim_set_hl(0, "Type", { fg = colors.cyan })
  vim.api.nvim_set_hl(0, "Constant", { fg = colors.orange })
  vim.api.nvim_set_hl(0, "String", { fg = colors.green })
  vim.api.nvim_set_hl(0, "Number", { fg = colors.purple })

  -- 状态栏透明（适配透明终端）
  vim.api.nvim_set_hl(0, "StatusLine", { fg = colors.fg, bg = colors.bg1 })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = colors.bg3, bg = "none" })

  -- Neo-tree Git 状态着色
  vim.api.nvim_set_hl(0, "NeoTreeGitModified", { fg = colors.yellow })
  vim.api.nvim_set_hl(0, "NeoTreeGitAdded", { fg = colors.green })
  vim.api.nvim_set_hl(0, "NeoTreeGitDeleted", { fg = colors.red })
  vim.api.nvim_set_hl(0, "NeoTreeGitUntracked", { fg = colors.orange, italic = true })
  vim.api.nvim_set_hl(0, "NeoTreeGitIgnored", { fg = colors.bg3 })
  vim.api.nvim_set_hl(0, "NeoTreeGitConflict", { fg = colors.red, bold = true })

  -- 诊断图标颜色
  vim.api.nvim_set_hl(0, "DiagnosticError", { fg = colors.red })
  vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = colors.yellow })
  vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = colors.blue2 })
  vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = colors.cyan })
end

-- 透明背景支持（通用）
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })

-- WinBar 透明
vim.api.nvim_set_hl(0, "WinBar", { bg = "none" })
vim.api.nvim_set_hl(0, "WinBarNC", { bg = "none" })

-- 初始应用
apply_theme_highlights()

-- 主题切换时自动重新应用
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- 延迟执行确保主题完全加载
    vim.defer_fn(function()
      -- 重新应用透明背景
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
      vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
      vim.api.nvim_set_hl(0, "WinBar", { bg = "none" })
      vim.api.nvim_set_hl(0, "WinBarNC", { bg = "none" })
      -- 应用主题高亮
      apply_theme_highlights()
    end, 10)
  end,
})

-- AstroNvim buffer 快捷键配置（Shift+h/l）
-- 上一个 / 下一个 buffer
vim.keymap.set("n", "H", "<cmd>bprev<CR>", { desc = "切换到上一个 buffer" })  -- Shift+h
vim.keymap.set("n", "L", "<cmd>bnext<CR>", { desc = "切换到下一个 buffer" })  -- Shift+l

-- Telescope 切换 buffer（可视化列表）
vim.keymap.set("n", "<Leader>bb", "<cmd>Telescope buffers<CR>", { desc = "Telescope: 切换 buffer" })

