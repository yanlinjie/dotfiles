# Neovim 与 tmux 配置

个人 Ubuntu / WSL 开发环境配置，包含工程目录树、文件与全文搜索、Python 补全、Markdown 编辑，以及 Neovim 和 tmux 之间的分屏导航。

仓库地址：<https://github.com/yanlinjie/dotfiles>

## 文件结构

```text
dotfiles/
├── README.md
├── nvim/
│   ├── init.vim                      # 配置入口、基础编辑设置
│   ├── completion-colors.vim         # 补全窗口配色
│   ├── lua/
│   │   ├── auto_reload.lua           # 外部修改自动刷新
│   │   ├── project_browser.lua       # 目录树、搜索、分屏导航
│   │   ├── python_completion.lua     # Python 补全与语言服务器
│   │   ├── markdown_tools.lua        # Markdown 渲染与表格
│   │   └── markdown_jump.lua         # 同文件标题链接跳转
│   └── after/ftplugin/markdown.lua   # Markdown 专用设置与按键
├── tmux.conf
├── plugins.lock                      # 插件目录、Git 地址、提交版本（Tab 分隔）
└── python-tools.txt                  # Python 工具依赖及版本
```

插件通过 Neovim 原生 `pack/*/opt` 目录安装，配置使用 `packadd` 加载。仓库保存插件版本清单，安装时从上游下载源码。

## 环境要求

- Ubuntu 或 WSL 中的 Ubuntu；以下命令使用 Bash，在 Ubuntu 终端执行。
- 建议使用 Neovim **0.12.6**，与原环境一致；工程模块本身要求至少 0.11.7，其他版本需要自行验证插件兼容性。
- tmux：原环境验证版本为 **3.2a**。
- Python **3.10+**、`venv`、Git、curl、ripgrep。
- 需要访问 GitHub 和 Python 包下载源；私有仓库需要先配置 GitHub 认证。

以下步骤使用默认路径 `~/.config`、`~/.local/share`，以及默认的 `NVIM_APPNAME`。如果自定义了 XDG 路径或应用名称，需要同时调整配置中的相关路径。配置不要求安装 gem5；打开 gem5 项目时会自动补充其 Python 搜索路径。

## 在新电脑安装

按顺序执行。每个步骤成功后再继续；已经安装的程序可以先检查版本，再跳过对应安装步骤。

### 1. 安装基础依赖

```bash
sudo apt update
sudo apt install -y git curl tmux ripgrep python3 python3-venv \
    ca-certificates xclip wl-clipboard
```

`xclip` 和 `wl-clipboard` 分别用于 X11 和 Wayland 剪贴板。WSL 的剪贴板还取决于 WSLg 和终端环境，可在 Neovim 中执行 `:checkhealth vim.provider` 检查。

### 2. 安装 Neovim 0.12.6

使用官方 Linux 预编译包，自动区分 x86_64 与 ARM64。下载或安装失败时，此代码块会停止。

```bash
bash <<'BASH'
set -euo pipefail

case "$(uname -m)" in
    x86_64) nvim_arch=x86_64 ;;
    aarch64|arm64) nvim_arch=arm64 ;;
    *) printf '不支持的架构：%s\n' "$(uname -m)" >&2; exit 1 ;;
esac

nvim_download="$(mktemp -d)"
trap 'rm -rf -- "$nvim_download"' EXIT
mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"

curl -fL \
    "https://github.com/neovim/neovim/releases/download/v0.12.6/nvim-linux-${nvim_arch}.tar.gz" \
    -o "$nvim_download/nvim.tar.gz"
tar -xzf "$nvim_download/nvim.tar.gz" -C "$HOME/.local/opt"
ln -sfn "$HOME/.local/opt/nvim-linux-${nvim_arch}/bin/nvim" \
    "$HOME/.local/bin/nvim"
BASH
```

让当前终端和以后打开的 Bash 优先使用该版本：

```bash
export PATH="$HOME/.local/bin:$PATH"
rg -q '^export PATH="\$HOME/\.local/bin:\$PATH"$' ~/.bashrc \
    || printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> ~/.bashrc
hash -r
command -v nvim
nvim --version
```

应使用 `~/.local/bin/nvim`，版本显示 `NVIM v0.12.6`。安装方法参考 [Neovim 官方文档](https://neovim.io/doc/install/) 和 [0.12.6 发布页](https://github.com/neovim/neovim/releases/tag/v0.12.6)。

### 3. 克隆仓库

```bash
git clone https://github.com/yanlinjie/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

如果仓库已经存在，进入该目录执行 `git pull --ff-only`，无需再次克隆。私有仓库可以使用已配置的 SSH 地址 `git@github.com:yanlinjie/dotfiles.git`。

### 4. 恢复插件与 Python 工具

在仓库目录中执行。已安装且版本匹配的插件会复用；如发现已有目录或版本冲突，脚本会停止，保留现场供检查。

```bash
cd ~/dotfiles

bash <<'BASH'
set -euo pipefail

while IFS=$'\t' read -r relative url revision; do
    destination="$HOME/.local/share/nvim/$relative"
    if [[ -d "$destination/.git" ]]; then
        installed="$(git -C "$destination" rev-parse HEAD)"
        if [[ "$installed" != "$revision" ]]; then
            printf '已有插件版本不匹配，请先检查：%s\n' "$destination" >&2
            exit 1
        fi
    elif [[ -e "$destination" || -L "$destination" ]]; then
        printf '目标路径已存在且不是插件仓库：%s\n' "$destination" >&2
        exit 1
    else
        mkdir -p "$(dirname "$destination")"
        git clone --no-checkout "$url" "$destination"
        git -C "$destination" checkout --detach "$revision"
    fi
done < plugins.lock

python3 -m venv "$HOME/.local/share/nvim-python-tools"
"$HOME/.local/share/nvim-python-tools/bin/python" -m pip install \
    -r python-tools.txt
"$HOME/.local/share/nvim-python-tools/bin/python" -m pip check
BASH
```

此工具虚拟环境运行 basedpyright，不是项目的 Python 环境。项目依赖仍需安装到项目环境；配置优先选择项目根目录的 `.venv/bin/python`、`venv/bin/python`，否则使用 PATH 中的 `python3`。

### 5. 备份旧配置并创建软链接

这一步也适用于将原电脑的独立配置副本改为仓库软链接。执行后，编辑配置文件会直接修改仓库内容；备份保留在终端输出的目录中。

```bash
bash <<'BASH'
set -euo pipefail
test -f "$HOME/dotfiles/nvim/init.vim"
test -f "$HOME/dotfiles/tmux.conf"

backup="$(mktemp -d "$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S).XXXXXX")"
mkdir -p "$HOME/.config"

if [[ -e "$HOME/.config/nvim" || -L "$HOME/.config/nvim" ]]; then
    mv "$HOME/.config/nvim" "$backup/nvim"
fi
if [[ -e "$HOME/.tmux.conf" || -L "$HOME/.tmux.conf" ]]; then
    mv "$HOME/.tmux.conf" "$backup/tmux.conf"
fi

ln -s "$HOME/dotfiles/nvim" "$HOME/.config/nvim"
ln -s "$HOME/dotfiles/tmux.conf" "$HOME/.tmux.conf"
printf '原配置备份：%s\n' "$backup"
BASH
```

### 6. 启动和验证

```bash
tmux new -s work
nvim ~/dotfiles/README.md
```

如果 tmux 已经运行，可以在已有会话的终端里执行：

```bash
tmux source-file ~/.tmux.conf
```

检查目录树、文件搜索和 Markdown 渲染是否正常。打开项目中的 `.py` 文件后执行 `:PythonInfo`，稍等语言服务器连接，应显示 basedpyright 和项目解释器。需要排查环境问题时执行 `:checkhealth`。

## 常用快捷键

### Neovim

`Leader` 为 **空格**，下表中的组合键依次按下。Python 专用按键在 basedpyright 连接后启用。

| 按键 | 功能 |
| --- | --- |
| `空格 w` | 保存文件 |
| `空格 h` | 清除搜索高亮 |
| `空格 t` | 开关工程目录树 |
| `空格 E` | 在目录树定位当前文件 |
| `空格 ff` / `空格 fg` / `空格 fb` | 搜文件名 / 搜文本 / 切换缓冲区 |
| `Ctrl+h/j/k/l` | 在 Neovim 分屏与 tmux 窗格之间切换 |
| `Ctrl+\` | 返回上一个分屏或窗格 |
| Python 中 `Tab` / `Shift+Tab` | 确认补全 / 上一个候选，兼顾片段跳转 |
| Python 中 `gd` / `gr` / `K` | 定义 / 引用 / 文档 |
| Python 中 `空格 rn` / `空格 ca` / `空格 e` | 重命名 / 代码操作 / 诊断详情 |
| Markdown 中 `空格 mp` / `空格 mt` | 开关渲染 / 表格模式 |
| Markdown 中回车 | 跟随同文件 `#标题` 链接 |
| `Ctrl+o` | 返回之前的跳转位置 |

Markdown 中不带计数的 `j/k` 按屏幕显示行移动。表格模式开启后，输入 `|` 会触发表格对齐。Python 目前配置了补全与诊断，没有配置保存时自动格式化。

### tmux

前缀为 **Ctrl+b**：先按前缀，松开，再按下表中的键。

| 前缀后的按键 | 功能 |
| --- | --- |
| `c` | 新建窗口 |
| `\|` / `%` | 左右分屏 |
| `-` / `"` | 上下分屏 |
| `h/j/k/l` | 切换窗格 |
| `H/J/K/L` | 每次调整窗格大小 5 格 |
| `r` | 重载配置 |
| `Ctrl+l` | 向程序发送清屏快捷键 |
| `d` | 离开会话，程序继续运行 |

新窗口和分屏继承当前窗格目录。使用 `tmux attach -t work` 返回之前创建的会话。

## 日常同步

安装软链接后，在任一电脑修改配置，再提交到仓库：

```bash
cd ~/dotfiles
git diff
git add README.md nvim tmux.conf plugins.lock python-tools.txt
git commit -m "Update editor configuration"
git push
```

其他电脑获取更新：

```bash
cd ~/dotfiles
git pull --ff-only
```

重新打开 Neovim；已有 tmux 会话执行 `tmux source-file ~/.tmux.conf`。如果 `git pull` 因本地改动或分支分歧停止，先处理自己的改动，再继续同步。

`git pull` 只更新仓库文件。如果更改了 `plugins.lock`，还需要更新本机插件：在对应插件目录执行 `git fetch origin`，再 `git checkout --detach <清单中的提交版本>`，保留或处理本地插件修改后再切换。如果更改了 `python-tools.txt`，重新执行第 4 步中的 pip 安装和检查命令。

## 记录新的依赖版本

仅在当前环境已验证可用后更新版本清单。在仓库目录中使用下面的 Python 脚本生成插件清单，避免终端集成控制字符混入文件：

```bash
cd ~/dotfiles
python3 - <<'PY'
from pathlib import Path
import subprocess

data = Path.home() / ".local/share/nvim"
rows = []
for plugin in sorted(data.glob("site/pack/*/opt/*")):
    if not (plugin / ".git").exists():
        continue
    def git(*args):
        return subprocess.check_output(
            ["git", "-C", str(plugin), *args], text=True
        ).strip()
    rows.append("\t".join((str(plugin.relative_to(data)),
                           git("remote", "get-url", "origin"),
                           git("rev-parse", "HEAD"))))
Path("plugins.lock").write_text("\n".join(rows) + "\n", encoding="utf-8")
PY

~/.local/share/nvim-python-tools/bin/python -m pip freeze > python-tools.txt
git diff -- plugins.lock python-tools.txt
```

插件的本地未提交修改不会被提交版本号保存。使用上游可获取的提交，并确认 diff 后再提交清单。仓库无需包含插件源码、虚拟环境、日志、交换文件或历史备份，也不要加入 `.codex/auth.json`、SSH 私钥等凭据。

## 常见问题

| 现象 | 检查方法 |
| --- | --- |
| Neovim 版本过旧 | 执行 `command -v nvim` 和 `nvim --version`，确认 PATH 优先使用 `~/.local/bin` |
| `packadd` 找不到插件 | 确认第 4 步完成，插件位于 `~/.local/share/nvim/site/pack/*/opt/` |
| Python 没有补全 | 打开 `.py` 文件，执行 `:PythonInfo`，确认语言服务器存在、连接成功，以及项目解释器正确 |
| Python 导入报错 | 在项目解释器中安装项目依赖，而不是只安装到语言服务器工具环境 |
| 搜索文本不可用 | 执行 `rg --version`，确认安装了 ripgrep |
| 复制到系统剪贴板失败 | 执行 `:checkhealth vim.provider`；WSL 下同时检查 WSLg / 终端剪贴板支持 |
| Markdown 标题跳转或渲染失败 | 执行 `:checkhealth vim.treesitter`，检查 Markdown 解析器；优先使用本文指定的官方 Neovim 版本 |
| 配置更新后未生效 | 检查 `ls -ld ~/.config/nvim ~/.tmux.conf` 是否指向此仓库，然后重启 Neovim 或重载 tmux |
| 想恢复安装前的配置 | 先移除指向仓库的两个软链接，再从第 5 步输出的备份目录恢复 `nvim` 和 `tmux.conf` 到原路径 |
