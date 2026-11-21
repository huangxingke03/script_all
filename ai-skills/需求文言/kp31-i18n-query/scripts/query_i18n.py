#!/usr/bin/env python3
"""Query KP31 Chinese/English glossary from Feishu Base 词条总数据."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from typing import Any

BASE_TOKEN = "AxEZbBhDvazp8Uss5uAcwt4bnBh"
TABLE_ID = "tblNCvEsMzcQyCR8"
TABLE_NAME = "词条总数据"
BASE_URL = (
    "https://t83dfrspj4.feishu.cn/base/"
    "AxEZbBhDvazp8Uss5uAcwt4bnBh?table=tblNCvEsMzcQyCR8"
)
ZH_FIELD = "中文"
EN_FIELD = "英文（澳式）-更新版"
MODULE_FIELD = "模块"
ID_FIELD = "ID"
SELECT_FIELDS = (ID_FIELD, MODULE_FIELD, ZH_FIELD, EN_FIELD)
SEARCH_FIELDS = (ZH_FIELD, EN_FIELD)
ID_PREFIX_RE = re.compile(r"^id\s*0*(\d+)$", re.IGNORECASE)
ID_DIGITS_RE = re.compile(r"^0*(\d{4,})$")
WS_RE = re.compile(r"\s+")
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
    text = text.replace("…", "...").replace("\u3000", " ")
    return WS_RE.sub(" ", text).strip()


def fold(value: Any) -> str:
    return normalize(value).casefold()


def cell(row: dict[str, Any], field: str) -> str:
    return normalize(row.get(field))


def parse_id_query(query: str) -> str | None:
    raw = query.strip()
    match = ID_PREFIX_RE.fullmatch(raw) or ID_DIGITS_RE.fullmatch(raw)
    if not match:
        return None
    return f"ID{int(match.group(1)):04d}"


def parse_mode_and_query(raw: str, mode_arg: str | None) -> tuple[str, str]:
    text = raw
    has_fuzzy = bool(FUZZY_MODE_RE.search(text))
    text = FUZZY_MODE_RE.sub(" ", text)
    text = EXACT_MODE_RE.sub(" ", text)
    query = normalize(text)
    if mode_arg:
        mode = mode_arg
    elif has_fuzzy:
        mode = "fuzzy"
    else:
        mode = "exact"
    return mode, query


def find_lark_cli() -> str:
    path = shutil.which("lark-cli")
    if not path:
        die("找不到 lark-cli，先按 lark-shared 完成安装和登录")
    return path


def run_lark(args: list[str]) -> dict[str, Any]:
    proc = subprocess.run(
        args,
        check=False,
        capture_output=True,
        text=True,
    )
    stdout = proc.stdout.strip()
    stderr = proc.stderr.strip()
    if not stdout:
        detail = stderr or f"lark-cli 退出码 {proc.returncode}"
        die(detail)
    try:
        payload = json.loads(stdout)
    except json.JSONDecodeError:
        detail = stdout if stdout else stderr
        die(f"lark-cli 返回非 JSON：{detail}")
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


def rows_from_matrix(data: dict[str, Any]) -> list[dict[str, Any]]:
    fields = data.get("fields") or []
    matrix = data.get("data") or []
    record_ids = data.get("record_id_list") or []
    rows: list[dict[str, Any]] = []
    for index, raw in enumerate(matrix):
        item = {field: raw[i] if i < len(raw) else None for i, field in enumerate(fields)}
        if index < len(record_ids):
            item["_record_id"] = record_ids[index]
        rows.append(item)
    return rows


def add_select_fields(args: list[str]) -> None:
    for field in SELECT_FIELDS:
        args.extend(["--field-id", field])


def search_records(keyword: str, search_fields: tuple[str, ...], limit: int) -> list[dict[str, Any]]:
    cli = find_lark_cli()
    args = [
        cli,
        "base",
        "+record-search",
        "--base-token",
        BASE_TOKEN,
        "--table-id",
        TABLE_ID,
        "--as",
        "user",
        "--keyword",
        keyword,
        "--limit",
        str(limit),
        "--format",
        "json",
    ]
    for field in search_fields:
        args.extend(["--search-field", field])
    add_select_fields(args)
    return rows_from_matrix(run_lark(args))


def list_records(filter_obj: dict[str, Any], limit: int) -> list[dict[str, Any]]:
    cli = find_lark_cli()
    args = [
        cli,
        "base",
        "+record-list",
        "--base-token",
        BASE_TOKEN,
        "--table-id",
        TABLE_ID,
        "--as",
        "user",
        "--filter-json",
        json.dumps(filter_obj, ensure_ascii=False),
        "--limit",
        str(limit),
        "--format",
        "json",
    ]
    add_select_fields(args)
    return rows_from_matrix(run_lark(args))


def is_exact_row(row: dict[str, Any], query: str) -> bool:
    q = fold(query)
    return q == fold(row.get(ZH_FIELD)) or q == fold(row.get(EN_FIELD)) or q == fold(row.get(ID_FIELD))


def exact_records(query: str, limit: int) -> list[dict[str, Any]]:
    rows = list_records(
        {
            "logic": "or",
            "conditions": [
                [ZH_FIELD, "==", query],
                [EN_FIELD, "==", query],
            ],
        },
        limit,
    )
    if rows:
        return rows
    searched = search_records(query, SEARCH_FIELDS, limit)
    return [row for row in searched if is_exact_row(row, query)]


def score_row(row: dict[str, Any], query: str) -> tuple[int, int, str]:
    q = fold(query)
    zh = fold(row.get(ZH_FIELD))
    en = fold(row.get(EN_FIELD))
    entry_id = fold(row.get(ID_FIELD))
    if q == zh or q == en or q == entry_id:
        rank = 100
    elif zh.startswith(q) or en.startswith(q):
        rank = 80
    elif q in zh or q in en:
        rank = 60
    else:
        rank = 1
    return (-rank, len(zh), cell(row, ID_FIELD))


def to_item(row: dict[str, Any]) -> dict[str, str]:
    return {
        "id": cell(row, ID_FIELD),
        "module": cell(row, MODULE_FIELD),
        "zh": cell(row, ZH_FIELD),
        "en": cell(row, EN_FIELD),
    }


def dedupe(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    seen: set[str] = set()
    result: list[dict[str, Any]] = []
    for row in rows:
        key = cell(row, ID_FIELD) or cell(row, "_record_id") or json.dumps(row, ensure_ascii=False)
        if key in seen:
            continue
        seen.add(key)
        result.append(row)
    return result


def query_rows(query: str, mode: str, fetch_limit: int) -> tuple[str, list[dict[str, Any]]]:
    entry_id = parse_id_query(query)
    if entry_id:
        return entry_id, search_records(entry_id, (ID_FIELD,), 20)
    if mode == "exact":
        return query, exact_records(query, fetch_limit)
    return query, search_records(query, SEARCH_FIELDS, fetch_limit)


def format_item(item: dict[str, str]) -> list[str]:
    return [
        f"- ID：{item['id']}",
        f"- 模块：{item['module']}",
        f"- 中文：{item['zh']}",
        f"- 英文：{item['en']}",
    ]


def format_human(query: str, mode: str, items: list[dict[str, str]], total: int, shown: int) -> str:
    lines = [f"检索：{query}", f"模式：{MODE_LABEL.get(mode, mode)}", ""]
    if not items:
        lines.append("词条表未写或未检索到")
        if mode == "exact":
            lines.append("精确未命中，可改用模糊搜索。")
        return "\n".join(lines) + "\n"
    numbered = len(items) > 1
    for index, item in enumerate(items, 1):
        if numbered:
            lines.append(f"**{index}.**")
        lines.extend(format_item(item))
        lines.append("")
    if total > shown:
        lines.append(f"共 {total} 条，已展示最相关 {shown} 条。可缩小检索词继续查。")
    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="按中文或英文文言查询 KP31 词条")
    parser.add_argument("--query", required=True, help="中文或英文文言，可带准确搜索/模糊搜索")
    parser.add_argument(
        "--mode",
        choices=("exact", "fuzzy"),
        help="exact=精确搜索，fuzzy=模糊搜索；默认精确，查询词含模糊搜索时用模糊",
    )
    parser.add_argument("--limit", type=int, default=10, help="最多展示条数，默认 10")
    parser.add_argument("--json", action="store_true", help="输出 JSON")
    args = parser.parse_args()
    mode, query = parse_mode_and_query(args.query, args.mode)
    if not query:
        die("检索词为空")
    if args.limit < 1:
        die("--limit 必须大于 0")

    raw_query, rows = query_rows(query, mode, max(args.limit, 50))
    rows = dedupe(rows)
    rows.sort(key=lambda row: score_row(row, raw_query))
    total = len(rows)
    shown_rows = rows[: args.limit]
    items = [to_item(row) for row in shown_rows]

    if args.json:
        payload = {
            "ok": True,
            "query": raw_query,
            "mode": mode,
            "mode_label": MODE_LABEL[mode],
            "table": TABLE_NAME,
            "url": BASE_URL,
            "total": total,
            "shown": len(items),
            "items": items,
        }
        json.dump(payload, sys.stdout, ensure_ascii=False, indent=2)
        sys.stdout.write("\n")
        return
    sys.stdout.write(format_human(raw_query, mode, items, total, len(items)))


if __name__ == "__main__":
    main()
