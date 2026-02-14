function u --description "Update everything"

    # ── Homebrew ────────────────────────────────────────────────────────────
    brew update
    and brew upgrade
    and brew upgrade --cask --greedy
    brew autoremove
    and brew cleanup --prune=all
    brew bundle dump --force --file ~/dotfiles/Brewfile

    # ── Neovim ──────────────────────────────────────────────────────────────
    nvim --headless "+AstroUpdate"      +qa
    nvim --headless "+Lazy! sync"       +qa
    nvim --headless "+MasonToolsUpdate" +qa
    nvim --headless "+TSUpdateSync"     +qa

    # ── Conda ───────────────────────────────────────────────────────────────
    conda update conda -y
    and conda update --all -y
    and conda clean --all -y

    # ── Rust ────────────────────────────────────────────────────────────────
    rustup update
    and cargo install-update -a

    # ── Node ────────────────────────────────────────────────────────────────
    npm update -g
    and npm cache clean --force
    pnpm update -g
    and pnpm store prune

    # ── Python ──────────────────────────────────────────────────────────────
    uv tool upgrade --all

    # ── Shell & Terminal ────────────────────────────────────────────────────
    fisher update
    ~/.config/tmux/plugins/tpm/bin/update_plugins all

    # ── CLI Tools ───────────────────────────────────────────────────────────
    ya pkg upgrade
    bat cache --build

    # ── macOS ───────────────────────────────────────────────────────────────
    mas update
    mo clean
    and mo purge

    # ── Rime / 万象 ─────────────────────────────────────────────────────────
    printf '\n' | bash ~/dotfiles/scripts/rime-wanxiang-update-macos.sh \
        --schema base --fuzhu base --dict --gram

end
