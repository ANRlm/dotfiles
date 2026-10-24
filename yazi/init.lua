-- ── Appearance: Borders ──────────────────────────────────────────────

require("full-border"):setup({
	-- Available values: "plain", "rounded"
	set = "plain",
})

-- ── Git ──────────────────────────────────────────────────────────────

th.git = th.git or {}
th.git.unstaged_sign = "M"
th.git.deleted_sign = "D"
require("git"):setup()

-- ── Appearance: Prompt ───────────────────────────────────────────────

require("starship"):setup()
