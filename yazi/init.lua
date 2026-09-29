-- ── Appearance: Borders ──────────────────────────────────────────────

require("full-border"):setup({
	-- Available values: ui.Border.PLAIN, ROUNDED, DOUBLE, THICK, QUADRANT_INSIDE, QUADRANT_OUTSIDE
	type = ui.Border.PLAIN,
})

-- ── Git ──────────────────────────────────────────────────────────────

th.git = th.git or {}
th.git.unstaged_sign = "M"
th.git.deleted_sign = "D"
require("git"):setup()

-- ── Appearance: Prompt ───────────────────────────────────────────────

require("starship"):setup()
