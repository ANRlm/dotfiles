-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here
vim.opt.scrolloff = 999
vim.opt.sidescrolloff = 999

if vim.g.neovide then
  vim.opt.guifont = "JetBrainsMono Nerd Font:h14"
  -- vim.opt.guifont = "FiraCode Nerd Font Mono:h14"
  -- vim.opt.guifont = "MesloLGS Nerd Font Mono:h14"

  vim.g.neovide_opacity = 1
  vim.g.neovide_window_blurred = true
  vim.g.neovide_floating_blur_amount_x = 4.0
  vim.g.neovide_floating_blur_amount_y = 4.0

  vim.g.neovide_padding_top = 24
  vim.g.neovide_padding_bottom = 4
  vim.g.neovide_padding_left = 12
  vim.g.neovide_padding_right = 12

  vim.g.neovide_cursor_animate_in_insert_mode = true
  vim.g.neovide_cursor_animate_command_line = true

  vim.g.neovide_progress_bar_enabled = true
  vim.g.neovide_progress_bar_height = 5.0
  vim.g.neovide_progress_bar_animation_speed = 200.0
  vim.g.neovide_progress_bar_hide_delay = 0.2

  vim.g.neovide_hide_mouse_when_typing = true

  vim.g.neovide_theme = "auto"

  vim.g.neovide_refresh_rate = 120
  vim.g.neovide_refresh_rate_idle = 5

  vim.g.neovide_no_idle = true
  vim.g.neovide_confirm_quit = true
  vim.g.neovide_cursor_hack = true
  vim.g.neovide_input_macos_option_key_is_meta = "both"

  vim.g.neovide_touch_deadzone = 6.0
  vim.g.neovide_touch_drag_timeout = 0.17

  vim.g.neovide_cursor_antialiasing = true

  vim.g.neovide_cursor_vfx_mode = "pixiedust"

  vim.keymap.set("i", "<D-v>", "<C-r>+", {
    noremap = true,
    silent = true,
    desc = "Paste in insert mode",
  })

  vim.cmd.cd(vim.fn.expand "~/dotfiles")

  vim.g.neovide_theme = "dark"
  vim.opt.background = "dark"
  vim.cmd "colorscheme rose-pine"
end
