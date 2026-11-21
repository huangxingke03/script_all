#!/usr/bin/env bash
# 把仓库里的技能副本链接到本机加载目录。已存在的同名技能跳过，不覆盖。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link_into() {
  local src_dir="$1"
  local dest_root="$2"
  local src name dest
  mkdir -p "$dest_root"
  for src in "$src_dir"/*; do
    [ -d "$src" ] || continue
    name="$(basename "$src")"
    dest="$dest_root/$name"
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      printf 'skip %s\n' "$dest"
      continue
    fi
    ln -s "$src" "$dest"
    printf 'link %s\n' "$dest"
  done
}

link_into "$ROOT/工程切换" "$HOME/.agents/skills"
link_into "$ROOT/分支切换" "$HOME/.agents/skills"
link_into "$ROOT/代码推送" "$HOME/.agents/skills"
link_into "$ROOT/提交回退" "$HOME/.agents/skills"
link_into "$ROOT/AndroidStudio" "$HOME/.agents/skills"
link_into "$ROOT/系统配置" "$HOME/.agents/skills"
link_into "$ROOT/讯飞资源" "$HOME/.agents/skills"
link_into "$ROOT/设备同步" "$HOME/.agents/skills"
link_into "$ROOT/需求文言" "$HOME/.agents/skills"
link_into "$ROOT/语音分析" "$HOME/.agents/skills"
link_into "$ROOT/飞书办公" "$HOME/.agents/skills"
link_into "$ROOT/飞书套件" "$HOME/.agents/skills"
link_into "$ROOT/会话控制" "$HOME/.agents/skills"
link_into "$ROOT/Claude" "$HOME/.claude/skills"
