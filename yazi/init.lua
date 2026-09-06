-- ── Appearance: Borders ──────────────────────────────────────────────

require("full-border"):setup({
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
})

-- ── Git ──────────────────────────────────────────────────────────────

th.git = th.git or {}
th.git.modified = ui.Style():fg("blue")
th.git.deleted = ui.Style():fg("red"):bold()
th.git.modified_sign = "M"
th.git.deleted_sign = "D"
require("git"):setup()

-- ── Appearance: Prompt ───────────────────────────────────────────────

require("starship"):setup()

-- ── Appearance: Status Line ──────────────────────────────────────────

require("no-status"):setup()
