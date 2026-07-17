function __u_section
    set_color --bold cyan
    echo ""
    echo "══ $argv ══"
    set_color normal
end

function __u_ok
    set_color green
    echo "  ✓ $argv"
    set_color normal
end

function __u_fail
    set_color red
    echo "  ✗ $argv"
    set_color normal
end

function __u_run --no-scope-shadowing --argument-names label
    set -e argv[1]
    $argv
    set -l status_code $status
    if test $status_code -eq 0
        __u_ok "$label"
    else
        __u_fail "$label (exit $status_code)"
        set __u_failures (math $__u_failures + 1)
    end
    return $status_code
end

function u --description "Update everything"
    set -f __u_failures 0

    # ── Homebrew
    __u_section Homebrew
    __u_run "Homebrew done" bash -lc "brew update && brew upgrade && brew autoremove && brew cleanup --prune=all && brew bundle dump --force --file ~/dotfiles/Brewfile --no-vscode"

    # ── Conda
    __u_section Conda
    __u_run "Conda updated" fish -c "conda update conda -y; and conda update --all -y; and conda clean --all -y"

    # ── Node
    __u_section Node
    __u_run "npm updated" env PUPPETEER_SKIP_DOWNLOAD=true npm update -g
    __u_run "pnpm updated" bash -lc "pnpm update -g && pnpm store prune"

    # ── Python (uv)
    __u_section "Python / uv"
    __u_run "uv tools upgraded" uv tool upgrade --all

    # ── Fish / Fisher
    __u_section "Fish / Fisher"
    __u_run "Fisher plugins updated" fisher update

    # ── Tmux / TPM
    __u_section "Tmux / TPM"
    __u_run "TPM plugins updated" ~/.config/tmux/plugins/tpm/bin/update_plugins all

    # ── Neovim / AstroNvim
    __u_section "Neovim / AstroNvim"
    __u_run "Plugins synced" nvim --headless -c 'lua local ok, err = pcall(function() require("lazy").sync({ wait = true }) end); if not ok then vim.api.nvim_err_writeln(tostring(err)); vim.cmd("cquit") end' -c qa
    __u_run "Treesitter parsers updated" nvim --headless -c 'lua local ok, err = pcall(function() require("nvim-treesitter").update():wait() end); if not ok then vim.api.nvim_err_writeln(tostring(err)); vim.cmd("cquit") end' -c qa
    __u_run "Mason tools updated" nvim --headless -c 'lua local ok, err = pcall(function() local plugin = require("lazy.core.config").plugins["mason-tool-installer.nvim"]; local tools = plugin and type(plugin.opts) == "table" and plugin.opts.ensure_installed or {}; if type(tools) == "table" and next(tools) then vim.cmd.MasonToolsUpdateSync() end end); if not ok then vim.api.nvim_err_writeln(tostring(err)); vim.cmd("cquit") end' -c qa

    # ── Yazi
    __u_section Yazi
    __u_run "Yazi plugins updated" ya pkg upgrade

    # ── Mac App Store
    __u_section "Mac App Store"
    __u_run "MAS updated" mas update

    # ── Mole
    __u_section Mole
    __u_run "Mole cleaned" mo clean </dev/null

    # ── Done
    echo ""
    set -l final_status 0
    if test $__u_failures -eq 0
        set_color --bold green
        echo "✓ All updated"
    else
        set_color --bold red
        echo "✗ Update finished with $__u_failures failure(s)"
        set final_status 1
    end
    set_color normal

    return $final_status
end
