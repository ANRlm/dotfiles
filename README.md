# dotfiles

个人 macOS dotfiles，包含终端、编辑器、Shell 与开发工具配置。

## 包含内容

- Shell：`fish`、`starship`
- 编辑器：`nvim`、`ideavim`
- 终端与复用器：`ghostty`、`tmux`
- Git 工具：`git`、`lazygit`、`delta`
- 文件工具：`yazi`、`bat`、`btop`
- 自动化脚本：`scripts/setup.sh`、`scripts/restore.sh`
- 软件安装清单：`Brewfile`（Homebrew、Casks、MAS、VS Code 扩展、Cargo）

## 仓库结构

大部分顶层目录会通过恢复脚本创建软链接到 `~/.config/<name>`。

```text
.
|- aerospace/
|- bat/
|- btop/
|- fish/
|- ghostty/
|- git/
|- karabiner/
|- nvim/
|- starship/
|- tmux/
|- yazi/
`- scripts/
```

## 快速开始

### 1) 新机器初始化

如果 GitHub SSH 或 Homebrew 还未完成配置，可执行：

```bash
bash scripts/setup.sh
```

该脚本会：

1. 检查并配置 GitHub SSH
2. 安装 Homebrew（如未安装）
3. 确保 Git 可用
4. 将仓库克隆到 `~/dotfiles`（如不存在）
5. 执行恢复流程

### 2) 已有仓库直接恢复

如果你已经克隆了本仓库，可执行：

```bash
bash scripts/restore.sh
```

该脚本会：

1. 将配置目录软链接到 `~/.config`
2. 处理 Karabiner 链接
3. 执行 `brew bundle --file=./Brewfile`
4. 安装 TPM 与 tmux 插件
5. 在可用时将默认 shell 设置为 fish

## 注意事项

- `restore.sh` 在创建链接前会替换目标路径中的现有内容，重要配置请先备份。
- `Brewfile` 包含较多桌面应用与工具，如需精简请先编辑后再执行恢复。
- Fish 配置包含常用缩写与启动集成（zoxide、starship、OrbStack）。

## 维护

- 通过编辑 `Brewfile` 维护软件清单。
- 配置变更后可重新执行：

```bash
bash scripts/restore.sh
```
