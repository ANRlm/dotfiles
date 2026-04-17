# dotfiles

> 个人 macOS 开发环境配置，基于 AstroNvim 的 Neovim 配置 + 全套终端工具链。

## 目录

- [概览](#概览)
- [快速开始](#快速开始)
- [配置清单](#配置清单)
- [目录结构](#目录结构)
- [主题与配色](#主题与配色)
- [快捷键参考](#快捷键参考)
- [脚本说明](#脚本说明)
- [维护与更新](#维护与更新)

---

## 概览

本仓库包含完整的 macOS 开发环境配置，涵盖：

| 类别 | 工具 |
|------|------|
| **窗口管理** | AeroSpace（平铺窗口管理器） |
| **终端** | Ghostty（带自定义 Shader 效果） |
| **Shell** | Fish + Starship 提示符 + zoxide |
| **编辑器** | Neovim（基于 AstroNvim v6）+ IdeaVim |
| **复用器** | Tmux（Catppuccin 主题 + TPM 插件） |
| **文件管理** | Yazi（终端文件管理器） |
| **版本控制** | Git + Lazygit + Delta（diff 查看器） |
| **系统监控** | btop |
| **键盘映射** | Karabiner-Elements + Goku (EDN) |
| **启动器** | Raycast |
| **包管理** | Homebrew（Brewfile 一键安装） |

---

## 快速开始

### 新机器初始化

```bash
bash scripts/setup.sh
```

该脚本会依次执行：

1. 检查并配置 GitHub SSH 密钥
2. 安装 Homebrew（如未安装）
3. 安装 Git
4. 克隆本仓库至 `~/dotfiles`
5. 执行 `restore.sh` 完成配置

### 已有仓库恢复配置

```bash
bash scripts/restore.sh
```

该脚本会：

1. 将所有配置目录软链接到 `~/.config`
2. 处理 Karabiner 配置链接
3. 执行 `brew bundle` 安装所有软件
4. 安装 TPM 及 Tmux 插件
5. 将默认 Shell 切换为 Fish

---

## 配置清单

### Shell (Fish)

- **主题**: Rosé Pine
- **插件**: `fzf.fish`（模糊搜索集成）
- **环境变量**: `EDITOR=nvim`, Conda 根目录, Starship 配置路径
- **Homebrew**: 禁用自动更新与分析，并行任务数按 CPU 核心数设定
- **Conda**: 延迟加载机制，仅在首次调用 `conda` 命令时初始化
- **集成**: zoxide（智能 cd）、Starship 提示符、OrbStack

#### 常用缩写

| 缩写 | 命令 | 说明 |
|------|------|------|
| `v` | `nvim` | 打开编辑器 |
| `lg` | `lazygit` | Git TUI |
| `ip` | `ipconfig getifaddr en0` | 获取本机 IP |
| `ports` | `lsof -i -P \| grep -i "listen"` | 查看监听端口 |
| `bi` | `brew install` | 安装软件 |
| `bu` | `brew update && brew upgrade` | 更新所有软件 |
| `bc` | `brew autoremove && brew cleanup` | 清理缓存 |
| `ts` | `tmux source-file ...` | 重载 Tmux 配置 |
| `tn` | `tmux new -s` | 新建 Tmux 会话 |
| `ca` | `conda activate` | 激活 Conda 环境 |
| `el` | `eza --long --header --icons --git --all` | 详细文件列表 |
| `et` | `eza --tree --level=2 ...` | 树形文件列表 |

#### FZF 配置

- 高度 75%，反向布局，带边框
- `Ctrl+T`: 目录跳转
- `Ctrl+R`: 历史命令搜索
- `Ctrl+G`: Ripgrep 全文搜索
- 文件预览: `bat`（代码）/ `eza`（目录）
- Diff 高亮: `delta`（mellow-barbet 主题）

### Neovim

- **基础框架**: AstroNvim
- **插件管理**: lazy.nvim
- **语言**: Lua

#### 核心插件

| 插件 | 用途 |
|------|------|
| `blink.cmp` | 自动补全 |
| `nvim-lspconfig` | LSP 配置 |
| `nvim-treesitter` | 语法高亮与解析 |
| `gitsigns.nvim` | Git 行内标注 |
| `neo-tree.nvim` | 文件树 |
| `aerial.nvim` | 代码大纲 |
| `nvim-dap` / `nvim-dap-ui` | 调试器 |
| `mason.nvim` | LSP/Formatter/Linter 管理 |
| `snacks.nvim` | 工具集（缩进线、作用域、模糊查找等） |
| `which-key.nvim` | 按键提示 |
| `todo-comments.nvim` | TODO 注释高亮 |

### Tmux

- **前缀键**: `Ctrl-a`
- **主题**: Catppuccin Mocha
- **状态栏**: 顶部显示，包含会话名、当前命令、路径、电池、网络、时钟
- **插件**:
  - `tmux-sensible`（合理默认值）
  - `tmux-yank`（系统剪贴板）
  - `vim-tmux-navigator`（与 Vim 无缝导航）
  - `tmux-online-status`（网络状态）
  - `tmux-battery`（电池状态）

#### 常用快捷键

| 快捷键 | 功能 |
|--------|------|
| `Prefix + R` | 重载配置 |
| `Prefix + =` | 水平分割 |
| `Prefix + -` | 垂直分割 |
| `Prefix + c` | 新建窗口 |
| `Prefix + r` | 进入调整面板模式（h/j/k/l） |
| `Prefix + v` | 可视模式（复制） |
| `Prefix + C-v` | 矩形选择 |

### Ghostty

- **字体**: MesloLGS Nerd Font Mono / Sarasa Mono SC（等更纱黑体）
- **字号**: 14，启用字体加粗
- **主题**: Mellow
- **背景模糊**: 85
- **窗口**: 隐藏标题栏与窗口按钮，padding 5px
- **Shader**: `cursor_warp.glsl` + `ripple_cursor.glsl`（光标特效）
- **剪贴板**: 允许读写，启用粘贴保护

### Yazi

- **主题**: Catppuccin Mocha
- **布局**: 三栏比例 2:2:3
- **排序**: 字母序，目录优先，显示隐藏文件
- **插件**:
  - `smart-enter`（智能进入/打开）
  - `full-border`（完整边框）
  - `git`（Git 状态显示）
  - `piper`（管道预览）
  - `starship`（Starship 集成）
  - `no-status`（隐藏状态栏）
- **预览**: 压缩包、CSV、SQLite schema 等

### Git

- **用户**: cnhyk / nai.ying.cnhyk@gmail.com
- **Diff 查看器**: Delta（mellow-barbet 主题，并排显示，带行号）
- **Merge**: zdiff3 冲突样式
- **LFS**: 启用 Git LFS

### Lazygit

- **Diff 查看器**: Delta（mellow-barbet + Catppuccin Mocha 语法主题）
- **主题色**: Rose Pine 配色方案

### Starship

- 完整配置 50+ 语言/工具提示符
- 自定义字符：成功 `>`，错误 `x`，Vim 模式 `<`
- 支持 AWS、Azure、Conda、Docker、Kubernetes 等云/容器环境显示

### btop

- **主题**: greyscale
- **图形**: braille 高分辨率
- **显示**: 仅进程面板（proc），树形视图，按内存排序
- **Vim 键**: 启用
- **更新间隔**: 2000ms
- **温度/功耗**: 启用 CPU 温度与功耗显示

### bat

- **主题**: Catppuccin Mocha

### Conda

- **渠道**: conda-forge > defaults
- **自动激活**: 关闭
- **显示渠道 URL**: 开启

### npm

- **缓存路径**: `~/.cache/npm`

### Karabiner

- 使用 Goku EDN 配置生成复杂键盘映射

### AeroSpace

- **布局**: 平铺为主，支持手风琴模式
- **间距**: 内边距 8px，外边距 6-8px
- **快捷键**: `Ctrl+Alt+Shift+数字` 切换工作区，`Cmd+hjkl` 聚焦窗口
- **浮动窗口**: Surge、QQ、微信、Keka、Easydict、Finder 自动浮动

### IdeaVim

- **Leader**: 空格
- **扩展**: EasyMotion、Highlightedyank、Commentary、Surround、NERDTree
- **Which-Key**: 完整按键映射提示
- **常用映射**:
  - `<leader>ff`: 查找文件
  - `<leader>ft`: 全文搜索
  - `<leader>fm`: 格式化代码
  - `<leader>gr`: 回退代码块
  - `<leader>lr`: 重命名
  - `<leader>ss`: 文件结构
  - `<leader>rr`: 重新运行
  - `<leader>e`: 切换项目面板

---

## 目录结构

```
.
├── aerospace/          # AeroSpace 平铺窗口管理器
│   └── aerospace.toml
├── bat/                # bat 代码查看器
│   └── config
├── btop/               # btop 系统监控
│   ├── btop.conf
│   └── themes/
├── conda/              # Conda 配置
│   └── condarc
├── fish/               # Fish Shell 配置
│   ├── config.fish
│   ├── fish_plugins
│   ├── fish_variables
│   ├── completions/
│   ├── conf.d/
│   ├── functions/
│   └── themes/
├── ghostty/            # Ghostty 终端
│   ├── config
│   └── shaders/
├── git/                # Git 配置
│   ├── config
│   └── themes.gitconfig
├── ideavim/            # JetBrains IdeaVim 配置
│   └── ideavimrc
├── karabiner/          # Karabiner-Elements 键盘映射
│   ├── config/
│   └── edn/
├── lazygit/            # Lazygit Git TUI
│   └── config.yml
├── mole/               # Mole 清理工具
├── npm/                # npm 配置
│   └── npmrc
├── nvim/               # Neovim 配置 (AstroNvim)
│   ├── init.lua
│   ├── lazy-lock.json
│   ├── lua/
│   │   ├── community.lua
│   │   ├── lazy_setup.lua
│   │   ├── polish.lua
│   │   └── plugins/
│   └── ...
├── raycast/            # Raycast 启动器配置
│   └── Raycast *.rayconfig
├── scripts/            # 自动化脚本
│   ├── setup.sh
│   ├── restore.sh
│   ├── license.sh
│   └── privacy-*.sh
├── starship/           # Starship 提示符
│   └── starship.toml
├── tmux/               # Tmux 终端复用器
│   ├── tmux.conf
│   └── plugins/
├── yazi/               # Yazi 终端文件管理器
│   ├── yazi.toml
│   ├── keymap.toml
│   ├── theme.toml
│   ├── package.toml
│   ├── init.lua
│   ├── flavors/
│   └── plugins/
├── bin/                # 自定义二进制/脚本
│   └── macmon
└── Brewfile            # Homebrew 软件清单
```

---

## 主题与配色

全局统一使用 **Catppuccin Mocha** 与 **Rosé Pine** 色系：

| 工具 | 主题 |
|------|------|
| Neovim | Rose Pine |
| Tmux | Catppuccin Mocha |
| Starship | 默认（与终端主题配合） |
| bat | Catppuccin Mocha |
| Delta | mellow-barbet + Catppuccin Mocha |
| Lazygit | Rose Pine 配色 |
| Yazi | Catppuccin Mocha |
| Ghostty | Mellow |
| btop | greyscale |
| Fish | Rosé Pine |

### 字体

- **终端/编辑器**: MesloLGS Nerd Font Mono
- **中文**: Sarasa Mono SC（等更纱黑体）
- **Tmux**: MesloLGS Nerd Font
- **其他**: Fira Code Nerd Font, JetBrains Mono Nerd Font, LXGW WenKai

---

## 快捷键参考

### AeroSpace

| 快捷键 | 功能 |
|--------|------|
| `Cmd + h/j/k/l` | 聚焦左/下/上/右窗口 |
| `Ctrl+Alt+Shift + 1-9` | 切换工作区 |
| `Cmd+Ctrl+Alt+Shift + 1-9` | 移动窗口到工作区并跟随 |
| `Ctrl+Alt+Shift + ←/→` | 上一个/下一个工作区 |
| `Ctrl+Alt+Shift + Tab` | 工作区来回切换 |
| `Ctrl+Alt+Shift + -/=` | 缩小/放大窗口 |
| `Ctrl+Alt+Shift + /` | 切换平铺布局 |
| `Ctrl+Alt+Shift + ,` | 切换手风琴布局 |
| `Cmd+Ctrl+Alt+Shift + ;` | 进入服务模式 |

### Fish

见 [Shell 配置](#shell-fish) 中的缩写表格。

### Tmux

见 [Tmux](#tmux) 中的快捷键表格。

### IdeaVim

见 [IdeaVim](#ideavim) 中的映射说明。

---

## 脚本说明

| 脚本 | 用途 |
|------|------|
| `setup.sh` | 新机器一键初始化（SSH + Homebrew + Git + 克隆 + 恢复） |
| `restore.sh` | 恢复配置（软链接 + brew bundle + 插件安装 + Shell 切换） |
| `privacy-cleanup.sh` | 清理系统日志、缓存、浏览记录、iOS 备份等隐私数据 |
| `privacy-configure-os.sh` | 禁用 Siri、远程管理、个性化广告、iCloud 自动存储等 |
| `privacy-security-improvements.sh` | 系统安全加固 |
| `license.sh` | 软件许可证记录 |

---

## 维护与更新

### 一键更新所有工具

```bash
u
```

执行 `u` 函数会依次更新：Homebrew、Rust、Go、Conda、Node、Python(uv)、Fisher、TPM、Neovim 插件、Mason 包、Yazi 插件、Mac App Store、Mole，并清理 CleanShot 缓存。

### 手动更新各组件

```bash
# 更新 Homebrew 及所有 Cask
brew update && brew upgrade

# 更新 Neovim 插件
:Lazy sync

# 更新 Mason 包（LSP/Formatter/Linter）
:MasonUpdate

# 更新 Treesitter 解析器
:TSUpdate

# 更新 Tmux 插件
Prefix + I
```

### 添加新软件

编辑 `Brewfile` 后执行：

```bash
brew bundle --file=./Brewfile
```

### 配置变更生效

```bash
# 重新运行恢复脚本（会重新创建软链接）
bash scripts/restore.sh
```

### 备份现有配置

恢复脚本会替换目标路径中的现有内容，重要配置请先备份：

```bash
cp -r ~/.config/nvim ~/.config/nvim.bak
```
