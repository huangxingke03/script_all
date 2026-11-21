#!/usr/bin/env python3
"""Query D01 international translation sheet, dropping strikethrough text."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from typing import Any

SHEET_URL = "https://t83dfrspj4.feishu.cn/sheets/KSmTsrBwOhraKktYRi6c5QM8n7e?sheet=oj5HfG"
SHEET_ID = "oj5HfG"
SHEET_NAME = "翻译内容正文"
HEADER_ROW = 2
LAST_COL = "V"
SEARCH_START = 6  # G 中文
SEARCH_END = 19  # T 波斯语
MAX_SEARCH_MATCHES = 300
ROW_BATCH = 6

# A-V, index 0 = A
FIELDS = (
    "id",
    "module",
    "level1",
    "level2",
    "type",
    "key",
    "zh",
    "en",
    "ar",
    "es",
    "ru",
    "kk",
    "uz",
    "pt",
    "fr",
    "uk",
    "in",
    "ms",
    "th",
    "fa",
    "note",
    "project",
)
LANG_FIELDS = (
    ("en", "英语（美式）"),
    ("ar", "阿拉伯语"),
    ("es", "西班牙语"),
    ("ru", "俄罗斯语"),
    ("kk", "哈萨克斯坦语"),
    ("uz", "乌兹别克斯坦语"),
    ("pt", "葡萄牙语"),
    ("fr", "法语"),
    ("uk", "乌克兰语"),
    ("in", "印尼语"),
    ("ms", "马来语"),
    ("th", "泰语"),
    ("fa", "波斯语"),
)
# Longer aliases first so 阿拉伯语 wins over 阿语.
LANG_ALIASES: tuple[tuple[str, str], ...] = (
    ("英语（美式）", "en"),
    ("美式英语", "en"),
    ("阿拉伯语", "ar"),
    ("西班牙语", "es"),
    ("俄罗斯语", "ru"),
    ("哈萨克斯坦语", "kk"),
    ("乌兹别克斯坦语", "uz"),
    ("葡萄牙语", "pt"),
    ("巴西葡语", "pt"),
    ("乌克兰语", "uk"),
    ("印尼语", "in"),
    ("马来语", "ms"),
    ("波斯语", "fa"),
    ("英语", "en"),
    ("英文", "en"),
    ("美式", "en"),
    ("阿语", "ar"),
    ("阿文", "ar"),
    ("西语", "es"),
    ("俄语", "ru"),
    ("哈萨语", "kk"),
    ("哈语", "kk"),
    ("乌兹语", "uz"),
    ("葡语", "pt"),
    ("法语", "fr"),
    ("泰语", "th"),
    ("波斯", "fa"),
    ("en", "en"),
    ("ar", "ar"),
    ("es", "es"),
    ("ru", "ru"),
    ("kk", "kk"),
    ("uz", "uz"),
    ("pt", "pt"),
    ("fr", "fr"),
    ("uk", "uk"),
    ("ms", "ms"),
    ("th", "th"),
    ("fa", "fa"),
)
ID_PREFIX_RE = re.compile(r"^id\s*0*(\d+)$", re.IGNORECASE)
ID_DIGITS_RE = re.compile(r"^0*(\d{4,})$")
ADDR_RE = re.compile(r"^([A-Z]+)(\d+)$")
RANGE_RE = re.compile(r"^([A-Z]+)(\d+):([A-Z]+)(\d+)$")
# Group labels are merged downward; the value lives on the top-left cell.
MERGE_FIELDS = {"B": "module", "C": "level1", "D": "level2"}
WS_RE = re.compile(r"[ \t\u3000]+")
FUZZY_MODE_RE = re.compile(r"模糊搜索|模糊查询|模糊匹配")
EXACT_MODE_RE = re.compile(r"准确搜索|精确搜索|准确查询|精确查询|准确匹配|精确匹配")
MODE_LABEL = {"exact": "精确搜索", "fuzzy": "模糊搜索"}


def die(msg: str, code: int = 1) -> None:
    print(msg, file=sys.stderr)
    raise SystemExit(code)


def normalize(value: Any) -> str:
    if value is None:
        return ""
    text = str(value).replace("\u2028", "\n").replace("\u2029", "\n")
    text = text.replace("…", "...").replace("\u00a0", " ")
    lines = []
    for line in text.split("\n"):
        line = WS_RE.sub(" ", line).strip()
        if line:
            lines.append(line)
    return "\n".join(lines)


def fold(value: Any) -> str:
    return normalize(value).casefold()


def find_lark_cli() -> str:
    path = shutil.which("lark-cli")
    if not path:
        die("找不到 lark-cli，先按 lark-shared 完成安装和登录")
    return path


def run_lark(args: list[str]) -> dict[str, Any]:
    proc = subprocess.run(args, check=False, capture_output=True, text=True)
    stdout = proc.stdout.strip()
    stderr = proc.stderr.strip()
    if not stdout:
        die(stderr or f"lark-cli 退出码 {proc.returncode}")
    try:
        payload = json.loads(stdout)
    except json.JSONDecodeError:
        die(f"lark-cli 返回非 JSON：{stdout or stderr}")
    if not payload.get("ok", False):
        error = payload.get("error") or payload
        if isinstance(error, dict):
            message = error.get("message") or error.get("hint") or json.dumps(error, ensure_ascii=False)
            hint = error.get("hint")
            if hint and hint not in str(message):
                message = f"{message}（{hint}）"
            die(str(message))
        die(json.dumps(error, ensure_ascii=False))
    data = payload.get("data")
    if not isinstance(data, dict):
        die("lark-cli 返回缺少 data")
    return data


def is_struck(style: dict[str, Any] | None) -> bool:
    if not style:
        return False
    return style.get("font_line") in {"line-through", "strike"}


def cleaned_cell(cell: Any) -> str:
    if not isinstance(cell, dict):
        return normalize(cell)
    if is_struck(cell.get("cell_styles")):
        return ""
    rich = cell.get("rich_text")
    if isinstance(rich, list) and rich:
        parts: list[str] = []
        for seg in rich:
            if not isinstance(seg, dict):
                continue
            if is_struck(seg.get("style")):
                continue
            parts.append(str(seg.get("text") or ""))
        return normalize("".join(parts))
    return normalize(cell.get("value"))


def raw_cell(cell: Any) -> str:
    if not isinstance(cell, dict):
        return normalize(cell)
    return normalize(cell.get("value"))


def lines_of(text: str) -> list[str]:
    return [line for line in text.split("\n") if line.strip()]


def text_hit(text: str, query: str, mode: str) -> bool:
    if not text or not query:
        return False
    q = fold(query)
    folded_lines = [fold(line) for line in lines_of(text)]
    if mode == "exact":
        return q in folded_lines or q == fold(text)
    return q in fold(text)


def lang_code(alias: str) -> str:
    folded = alias.casefold()
    return next(code for name, code in LANG_ALIASES if name.casefold() == folded)


def extract_langs_and_query(raw: str) -> tuple[str, list[str]]:
    text = normalize(raw).replace("\n", " ")
    found: list[str] = []
    aliases = sorted((alias for alias, _ in LANG_ALIASES), key=len, reverse=True)
    # Two-letter codes stay token-only, so an English word ending in "th" is not treated as Thai.
    name_aliases = [alias for alias in aliases if not re.fullmatch(r"[A-Za-z]{2}", alias)]
    seps = " \t:：,，、的"

    def take(alias: str) -> None:
        code = lang_code(alias)
        if code not in found:
            found.append(code)

    def peel_prefix(value: str) -> tuple[str, str] | None:
        folded = value.casefold()
        for alias in name_aliases:
            if not folded.startswith(alias.casefold()):
                continue
            rest = value[len(alias) :].lstrip(seps)
            # 阿拉伯语 alone must stay searchable; do not fall through to the shorter 阿语.
            if not rest:
                return None
            return alias, rest
        return None

    def peel_suffix(value: str) -> tuple[str, str] | None:
        folded = value.casefold()
        for alias in name_aliases:
            for sep in ("的", " ", "：", ":", "，", ","):
                token = sep + alias
                if folded.endswith(token.casefold()) and len(value) > len(token):
                    rest = value[: -len(token)].strip(seps)
                    if rest:
                        return alias, rest
        return None

    while True:
        peeled = peel_prefix(text) or peel_suffix(text)
        if not peeled:
            break
        alias, text = peeled
        take(alias)

    alias_re = re.compile(
        r"(?:(?<=^)|(?<=[\s,，;；、:：]))(" + "|".join(re.escape(a) for a in aliases) + r")(?=$|[\s,，;；、:：])",
        re.IGNORECASE,
    )
    while True:
        match = alias_re.search(text)
        if not match:
            break
        take(match.group(1))
        text = (text[: match.start()] + " " + text[match.end() :]).strip()
    query = normalize(text)
    if not query:
        return normalize(raw), []
    return query, found


def parse_mode_and_query(raw: str, mode_arg: str | None) -> tuple[str, str, list[str]]:
    text = raw
    has_fuzzy = bool(FUZZY_MODE_RE.search(text))
    text = FUZZY_MODE_RE.sub(" ", text)
    text = EXACT_MODE_RE.sub(" ", text)
    query, langs = extract_langs_and_query(text)
    if mode_arg:
        mode = mode_arg
    elif has_fuzzy:
        mode = "fuzzy"
    else:
        mode = "exact"
    return mode, query, langs


def parse_id_query(query: str) -> str | None:
    raw = query.strip()
    match = ID_PREFIX_RE.fullmatch(raw) or ID_DIGITS_RE.fullmatch(raw)
    if not match:
        return None
    return f"ID{int(match.group(1)):04d}"


def search_cells(keyword: str) -> list[dict[str, Any]]:
    cli = find_lark_cli()
    matches: list[dict[str, Any]] = []
    offset = 0
    while len(matches) < MAX_SEARCH_MATCHES:
        args = [
            cli,
            "sheets",
            "+cells-search",
            "--url",
            SHEET_URL,
            "--sheet-id",
            SHEET_ID,
            "--as",
            "user",
            "--find",
            keyword,
            "--offset",
            str(offset),
            "--format",
            "json",
        ]
        data = run_lark(args)
        batch = data.get("matches") or []
        if not isinstance(batch, list):
            break
        matches.extend(item for item in batch if isinstance(item, dict))
        if not data.get("has_more"):
            break
        next_offset = data.get("next_offset")
        if not isinstance(next_offset, int) or next_offset <= offset:
            break
        offset = next_offset
    return matches[:MAX_SEARCH_MATCHES]


def row_of(address: str) -> int | None:
    match = ADDR_RE.fullmatch(address or "")
    if not match:
        return None
    row = int(match.group(2))
    if row <= HEADER_ROW:
        return None
    return row


def fetch_rows(rows: list[int]) -> dict[int, list[Any]]:
    if not rows:
        return {}
    cli = find_lark_cli()
    found: dict[int, list[Any]] = {}
    for start in range(0, len(rows), ROW_BATCH):
        chunk = rows[start : start + ROW_BATCH]
        range_arg = ",".join(f"A{row}:{LAST_COL}{row}" for row in chunk)
        data = run_lark(
            [
                cli,
                "sheets",
                "+cells-get",
                "--url",
                SHEET_URL,
                "--sheet-id",
                SHEET_ID,
                "--as",
                "user",
                "--range",
                range_arg,
                "--include",
                "style",
                "--format",
                "json",
            ]
        )
        for block in data.get("ranges") or []:
            if not isinstance(block, dict):
                continue
            indices = block.get("row_indices") or []
            cells = block.get("cells") or []
            for index, row_cells in zip(indices, cells):
                if isinstance(index, int) and isinstance(row_cells, list):
                    found[index] = row_cells
    return found


def load_merges() -> list[tuple[str, int, int]]:
    data = run_lark(
        [
            find_lark_cli(),
            "sheets",
            "+sheet-info",
            "--url",
            SHEET_URL,
            "--sheet-id",
            SHEET_ID,
            "--as",
            "user",
            "--include",
            "merges",
            "--range",
            "B3:D4861",
            "--format",
            "json",
        ]
    )
    spans: list[tuple[str, int, int]] = []
    for item in data.get("merged_cells") or []:
        if not isinstance(item, dict):
            continue
        match = RANGE_RE.fullmatch(str(item.get("range") or ""))
        if not match:
            continue
        col, start, end_col, end = match.group(1), int(match.group(2)), match.group(3), int(match.group(4))
        if col != end_col or col not in MERGE_FIELDS or end < start:
            continue
        spans.append((col, start, end))
    return spans


def merge_top(spans: list[tuple[str, int, int]], col: str, row: int) -> int | None:
    for span_col, start, end in spans:
        if span_col == col and start <= row <= end:
            return start
    return None


def fill_merged_labels(rows: dict[int, list[Any]], spans: list[tuple[str, int, int]]) -> None:
    needed: set[str] = set()
    owners: list[tuple[int, str, str]] = []
    for row, cells in rows.items():
        for index, name in enumerate(FIELDS):
            col = chr(ord("A") + index)
            if col not in MERGE_FIELDS:
                continue
            cell = cells[index] if index < len(cells) else None
            if cleaned_cell(cell) or raw_cell(cell):
                continue
            top = merge_top(spans, col, row)
            if top is None or top == row:
                continue
            needed.add(f"{col}{top}")
            owners.append((row, col, f"{col}{top}"))
    if not needed:
        return
    fetched = fetch_value_cells(sorted(needed))
    for row, col, address in owners:
        value = fetched.get(address, "")
        if not value:
            continue
        index = ord(col) - ord("A")
        cells = rows[row]
        while len(cells) <= index:
            cells.append(None)
        cells[index] = {"value": value}


def fetch_value_cells(addresses: list[str]) -> dict[str, str]:
    found: dict[str, str] = {}
    cli = find_lark_cli()
    for start in range(0, len(addresses), 40):
        chunk = addresses[start : start + 40]
        data = run_lark(
            [
                cli,
                "sheets",
                "+cells-get",
                "--url",
                SHEET_URL,
                "--sheet-id",
                SHEET_ID,
                "--as",
                "user",
                "--range",
                ",".join(f"{addr}:{addr}" for addr in chunk),
                "--include",
                "value",
                "--format",
                "json",
            ]
        )
        for block in data.get("ranges") or []:
            if not isinstance(block, dict):
                continue
            cells = block.get("cells") or []
            indices = block.get("row_indices") or []
            cols = block.get("col_indices") or []
            if not cells or not indices or not cols:
                continue
            cell = cells[0][0] if cells[0] else None
            found[f"{cols[0]}{indices[0]}"] = cleaned_cell(cell) or raw_cell(cell)
    return found


def field_map(row_cells: list[Any]) -> dict[str, Any]:
    mapped: dict[str, Any] = {}
    for index, name in enumerate(FIELDS):
        mapped[name] = row_cells[index] if index < len(row_cells) else None
    return mapped


def display_text(text: str) -> str:
    return " / ".join(lines_of(text))


def to_item(row_cells: list[Any], langs: list[str]) -> dict[str, str]:
    mapped = field_map(row_cells)
    item = {
        "id": cleaned_cell(mapped["id"]) or raw_cell(mapped["id"]),
        "module": cleaned_cell(mapped["module"]) or raw_cell(mapped["module"]),
        "level1": cleaned_cell(mapped["level1"]) or raw_cell(mapped["level1"]),
        "level2": cleaned_cell(mapped["level2"]) or raw_cell(mapped["level2"]),
        "key": cleaned_cell(mapped["key"]) or raw_cell(mapped["key"]),
        "zh": display_text(cleaned_cell(mapped["zh"])),
        "project": cleaned_cell(mapped["project"]) or raw_cell(mapped["project"]),
    }
    selected = langs or [code for code, _label in LANG_FIELDS]
    labels = dict(LANG_FIELDS)
    for code in selected:
        item[code] = display_text(cleaned_cell(mapped[code]))
        item[f"{code}_label"] = labels[code]
    item["_langs"] = ",".join(selected)
    return item


def row_status(row_cells: list[Any], query: str, mode: str, entry_id: str | None) -> str:
    """Return keep, struck, or miss."""
    mapped = field_map(row_cells)
    if entry_id:
        current = fold(cleaned_cell(mapped["id"]) or raw_cell(mapped["id"]))
        return "keep" if current == fold(entry_id) else "miss"
    keep = False
    struck = False
    for name in FIELDS[SEARCH_START : SEARCH_END + 1]:
        raw = raw_cell(mapped[name])
        cleaned = cleaned_cell(mapped[name])
        if text_hit(cleaned, query, mode):
            keep = True
        elif text_hit(raw, query, mode):
            struck = True
    if keep:
        return "keep"
    if struck:
        return "struck"
    return "miss"


def score_item(item: dict[str, str], query: str) -> tuple[int, int, str]:
    q = fold(query)
    zh_lines = [fold(line) for line in item.get("zh", "").split(" / ")]
    if q in zh_lines:
        rank = 100
    elif any(line.startswith(q) for line in zh_lines if line):
        rank = 80
    elif q and q in fold(item.get("zh")):
        rank = 60
    else:
        rank = 40
    return (-rank, len(item.get("zh", "")), item.get("id", ""))


def format_item(item: dict[str, str]) -> list[str]:
    lines = [f"- ID：{item.get('id', '')}"]
    if item.get("module"):
        lines.append(f"- 模块：{item['module']}")
    if item.get("level1"):
        lines.append(f"- 一级：{item['level1']}")
    if item.get("level2"):
        lines.append(f"- 二级：{item['level2']}")
    if item.get("key"):
        lines.append(f"- KEY：{item['key']}")
    lines.append(f"- 中文：{item.get('zh', '')}")
    for code in (item.get("_langs") or "").split(","):
        if not code:
            continue
        text = item.get(code, "")
        if not text:
            continue
        lines.append(f"- {item.get(code + '_label', code)}：{text}")
    if item.get("project"):
        lines.append(f"- 所属项目：{item['project']}")
    return lines


def format_human(
    query: str,
    mode: str,
    langs: list[str],
    items: list[dict[str, str]],
    total: int,
    shown: int,
    struck_rows: int,
) -> str:
    lines = [f"检索：{query}", f"模式：{MODE_LABEL.get(mode, mode)}"]
    if langs:
        labels = dict(LANG_FIELDS)
        lines.append("语言：" + "、".join(labels[code] for code in langs))
    lines.append("")
    if not items:
        if struck_rows:
            lines.append("只命中已划线废弃文言，已过滤。")
        else:
            lines.append("翻译表未写或未检索到")
            if mode == "exact":
                lines.append("精确未命中，可改用模糊搜索。")
        return "\n".join(lines) + "\n"
    numbered = len(items) > 1
    for index, item in enumerate(items, 1):
        if numbered:
            lines.append(f"**{index}.**")
        lines.extend(format_item(item))
        lines.append("")
    if struck_rows:
        lines.append(f"另有 {struck_rows} 条仅命中划线废弃文言，已过滤。")
    if total > shown:
        lines.append(f"共 {total} 条未划线命中，已展示最相关 {shown} 条。可缩小检索词继续查。")
    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="查询 D01 国际翻译资源，过滤划线文言")
    parser.add_argument("--query", required=True, help="中文或译文，可带语言名、精确搜索/模糊搜索")
    parser.add_argument("--mode", choices=("exact", "fuzzy"), help="默认精确；查询词含模糊搜索时用模糊")
    parser.add_argument("--limit", type=int, default=10, help="最多展示条数，默认 10")
    parser.add_argument("--json", action="store_true", help="输出 JSON")
    args = parser.parse_args()
    mode, query, langs = parse_mode_and_query(args.query, args.mode)
    if not query:
        die("检索词为空")
    if args.limit < 1:
        die("--limit 必须大于 0")

    entry_id = parse_id_query(query)
    keyword = entry_id or query
    matches = search_cells(keyword)
    rows = sorted({row for item in matches if (row := row_of(str(item.get("address") or "")))})
    fetched = fetch_rows(rows)

    kept_rows: list[int] = []
    struck_rows = 0
    for row in rows:
        cells = fetched.get(row)
        if not cells:
            continue
        status = row_status(cells, query, mode, entry_id)
        if status == "keep":
            kept_rows.append(row)
        elif status == "struck":
            struck_rows += 1

    if kept_rows:
        fill_merged_labels({row: fetched[row] for row in kept_rows}, load_merges())
    items = [to_item(fetched[row], langs) for row in kept_rows]
    items.sort(key=lambda item: score_item(item, query))
    # Same ID can repeat when several rows share it; keep each sheet row.
    total = len(items)
    shown = items[: args.limit]

    if args.json:
        payload = {
            "ok": True,
            "query": query,
            "mode": mode,
            "mode_label": MODE_LABEL[mode],
            "langs": langs,
            "sheet": SHEET_NAME,
            "url": SHEET_URL,
            "total": total,
            "shown": len(shown),
            "struck_filtered": struck_rows,
            "items": shown,
        }
        json.dump(payload, sys.stdout, ensure_ascii=False, indent=2)
        sys.stdout.write("\n")
        return
    sys.stdout.write(format_human(query, mode, langs, shown, total, len(shown), struck_rows))


if __name__ == "__main__":
    main()
