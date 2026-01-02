require("full-border"):setup {
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
}

-- ~/.config/yazi/init.lua
th.git = th.git or {}
th.git.modified_sign = "M"
th.git.deleted_sign = "D"
require("git"):setup()
