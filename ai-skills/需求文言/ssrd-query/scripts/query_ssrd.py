#!/usr/bin/env python3
"""Query Polarion SSRD software requirements via REST + personal access token."""

from __future__ import annotations

import argparse
import html
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

DEFAULT_HOST = "http://10.68.13.121/polarion"
TOKEN_PATH = os.path.expanduser("~/.polarion/token")

PROJECT_CATALOG = (
    {
        "id": "D01P_Overseas",
        "name": "D01P国际",
        "folded": ("d01p国际", "d01p", "d01p海外", "d01poverseas"),
    },
    {
        "id": "KP31",
        "name": "KP31",
        "folded": ("kp31",),
    },
    {
        "id": "D01",
        "name": "D01",
        "folded": ("d01",),
    },
)
PROJECT_BY_ID = {item["id"]: item for item in PROJECT_CATALOG}


def fold_project_key(value: str) -> str:
    text = value.strip().lower().replace("do1", "d01")
    return re.sub(r"[\s_\-]+", "", text)


def resolve_project(raw: str) -> str:
    folded = fold_project_key(raw)
    if not folded:
        die("项目名为空")
    if folded in PROJECT_BY_ID:
        return folded
    for item in PROJECT_CATALOG:
        if folded == fold_project_key(item["name"]) or folded in item["folded"]:
            return item["id"]
        if item["id"] == "D01P_Overseas" and folded.startswith("d01p"):
            return item["id"]
    supported = "、".join(f'{item["name"]}({item["id"]})' for item in PROJECT_CATALOG)
    die(f"不支持的项目：{raw}，只用 {supported}")


def project_label(project_id: str) -> str:
    item = PROJECT_BY_ID.get(project_id)
    if not item:
        return project_id
    if item["name"] == project_id:
        return project_id
    return f'{item["name"]}'
LUCENE_SPECIAL = re.compile(r'([+\-!(){}\[\]^"~*?:\\/]|&&|\|\|)')
HTML_BR = re.compile(r"(?i)<br\s*/?>")
HTML_BLOCK = re.compile(r"(?i)</(p|div|li|tr|h[1-6])>")
HTML_TAG = re.compile(r"<[^>]+>")
WS = re.compile(r"[ \t]+\n")


def die(msg: str, code: int = 1) -> None:
    print(msg, file=sys.stderr)
    raise SystemExit(code)


def read_token(path: str) -> str:
    try:
        token = open(path, encoding="utf-8").read().strip()
    except FileNotFoundError:
        die(f"缺少 Polarion Token：{path}\n在 Polarion 右上角创建个人访问令牌，写入该文件，chmod 600。")
    if not token:
        die(f"Polarion Token 为空：{path}")
    return token


def html_to_text(value: str | None) -> str:
    if not value:
        return ""
    text = HTML_BR.sub("\n", value)
    text = HTML_BLOCK.sub("\n", text)
    text = HTML_TAG.sub("", text)
    text = html.unescape(text)
    text = WS.sub("\n", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def quote_lucene(term: str) -> str:
    term = term.strip()
    if not term:
        return term
    escaped = term.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def rest_get(host: str, token: str, path: str, params: dict[str, str] | None = None) -> dict[str, Any]:
    url = host.rstrip("/") + "/rest/v1"
    for seg in path.strip("/").split("/"):
        url += "/" + urllib.parse.quote(seg, safe="")
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": "Bearer " + token,
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=40) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", "replace")
        if exc.code == 401:
            die("Polarion Token 无效或过期，请重新创建个人访问令牌并写入 ~/.polarion/token")
        die(f"Polarion HTTP {exc.code}: {body[:500]}")
    except urllib.error.URLError as exc:
        die(f"无法连接 Polarion：{exc}")


def is_ssrd_doc(doc_id: str, doc: dict[str, Any]) -> bool:
    folder = doc.get("moduleFolder") or ""
    name = doc.get("moduleName") or ""
    title = doc.get("title") or ""
    did = doc_id or ""
    path = f"{did}/{folder}/{name}"
    if re.search(r"(?i)已ssrd为准", f"{title} {path}") and not re.search(r"(?i)(^|[/])ssrd([_/]|\s)", path):
        return False
    if re.search(r"(?i)(^|[/_\-\s])ssrd([/_\-\s]|$)", path):
        return True
    if re.search(r"(?i)(^|[/_\-\s])ssrd([/_\-\s]|$)", title):
        return True
    if re.search(r"(?i)ssrd文档", f"{title} {name}"):
        return True
    return False


LEADING_VERBS = ("打开", "关闭", "开启", "关掉", "切换", "设置", "查询", "查看", "启动", "停止")


def keywords(term: str) -> list[str]:
    raw = term.strip()
    keys: list[str] = []

    def add(value: str) -> None:
        value = value.strip()
        if value and value not in keys and value not in LEADING_VERBS:
            keys.append(value)

    add(raw)
    rest = raw
    changed = True
    while changed:
        changed = False
        for verb in LEADING_VERBS:
            if rest.startswith(verb) and len(rest) > len(verb):
                rest = rest[len(verb):]
                add(rest)
                changed = True
                break
    if re.search(r"[\u4e00-\u9fff]", rest) and len(rest) >= 4:
        add(rest[-2:])
        add(rest[-3:])
    return keys


def meaningful_keys(term: str) -> list[str]:
    return [k for k in keywords(term) if len(k) >= 2]


def matches_term(item: dict[str, Any], term: str) -> bool:
    blob = f"{item.get('title') or ''}\n{item.get('description') or ''}".lower()
    return any(k.lower() in blob for k in meaningful_keys(term))


def score_item(term: str, title: str, description: str) -> tuple:
    title_l = title.lower()
    desc_l = description.lower()
    keys = [k.lower() for k in keywords(term)]
    rank = 0
    matched = ""
    for key in keys:
        if title_l == key:
            rank = max(rank, 100)
            matched = key
        elif key in title_l:
            bonus = 10 if len(title) <= 40 else 0
            rank = max(rank, 80 + min(len(key), 10) + bonus)
            if len(key) >= len(matched):
                matched = key
        elif key in desc_l:
            rank = max(rank, 40 + min(len(key), 10))
            if not matched:
                matched = key
    return (-rank, -len(matched), title_l)


def extract_items(payload: dict[str, Any]) -> list[dict[str, Any]]:
    docs = {
        item["id"]: item.get("attributes") or {}
        for item in payload.get("included") or []
        if item.get("type") == "documents" and item.get("id")
    }
    rows: list[dict[str, Any]] = []
    for item in payload.get("data") or []:
        attrs = item.get("attributes") or {}
        module = ((item.get("relationships") or {}).get("module") or {}).get("data") or {}
        doc_id = module.get("id") or ""
        doc = docs.get(doc_id, {})
        description = attrs.get("description") or {}
        desc_text = html_to_text(description.get("value") if isinstance(description, dict) else None)
        rows.append(
            {
                "id": attrs.get("id") or "",
                "type": attrs.get("type") or "",
                "title": attrs.get("title") or "",
                "status": attrs.get("status") or "",
                "outline": attrs.get("outlineNumber") or "",
                "description": desc_text,
                "document_id": doc_id,
                "document_title": doc.get("title") or "",
                "document_type": doc.get("type") or "",
                "space": doc.get("moduleFolder") or "",
                "portal": ((item.get("links") or {}).get("portal") or ""),
                "ssrd": is_ssrd_doc(doc_id, doc),
            }
        )
    return rows


def search_once(host: str, token: str, project: str, query: str) -> tuple[list[dict[str, Any]], int | None]:
    payload = rest_get(
        host,
        token,
        f"/projects/{project}/workitems",
        {
            "query": query,
            "fields[workitems]": "id,title,type,status,description,outlineNumber,module",
            "fields[documents]": "id,title,type,moduleFolder,moduleName,status",
            "include": "module",
        },
    )
    items = extract_items(payload)
    ssrd_items = [x for x in items if x["ssrd"] and x["type"] in {"softwareProductReq", "workpackage"}]
    if not ssrd_items:
        ssrd_items = [x for x in items if x["ssrd"]]
    return ssrd_items, (payload.get("meta") or {}).get("totalCount")


def query_project(host: str, token: str, project: str, term: str) -> dict[str, Any]:
    raw = term.strip()
    title_queries: list[str] = []
    text_queries: list[str] = []
    if re.fullmatch(r"[A-Za-z0-9]+-\d+", raw):
        title_queries.append(f"id:{raw}")
    for key in keywords(raw):
        quoted = quote_lucene(key)
        title_queries.append(f"type:softwareProductReq AND title:{quoted}")
        text_queries.append(f"type:softwareProductReq AND {quoted}")
    chosen_q = ""
    rows: list[dict[str, Any]] = []
    total = None
    seen: set[str] = set()
    for query in title_queries + text_queries:
        if not query or query in seen:
            continue
        seen.add(query)
        items, total_count = search_once(host, token, project, query)
        filtered = [x for x in items if matches_term(x, raw)] if not query.startswith("id:") else items
        if not chosen_q:
            chosen_q = query
        if filtered:
            chosen_q = query
            rows = filtered
            total = total_count
            break
    rows.sort(key=lambda x: score_item(term, x["title"], x["description"]))
    return {
        "project": project,
        "term": term,
        "query": chosen_q,
        "total": total,
        "returned": len(rows),
        "capped": (total or 0) > 100 or len(rows) >= 100,
        "items": rows,
    }


def render_markdown(result: dict[str, Any], limit: int) -> str:
    items = result["items"][:limit]
    lines = [
        f"项目：{project_label(result['project'])}",
        f"检索：{result['term']}",
        f"命中：展示 {len(items)} / 本次 {result['returned']}"
        + (f"，服务端约 {result['total']}（REST 最多 100 条）" if result.get("total") else "（REST 最多 100 条）"),
        "",
    ]
    if not items:
        lines.append("SSRD 未写或未检索到。")
        return "\n".join(lines)
    for item in items:
        lines.append(f"**{item['id']}** {item['title']}")
        if item.get("document_title"):
            lines.append(f"文档：{item['document_title']}")
        if item.get("outline"):
            lines.append(f"大纲：{item['outline']}")
        if item.get("description"):
            desc = item["description"]
            if len(desc) > 800:
                desc = desc[:800].rstrip() + "…"
            lines.append("描述：")
            lines.append(desc)
        if item.get("portal"):
            lines.append(f"链接：{item['portal']}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Query Polarion SSRD work items")
    parser.add_argument("--project", action="append", dest="projects", help="KP31 / D01 / D01P国际, repeatable, ignore case")
    parser.add_argument("--query", required=True, help="search term or work item id")
    parser.add_argument("--host", default=os.environ.get("POLARION_HOST", DEFAULT_HOST))
    parser.add_argument("--token-file", default=TOKEN_PATH)
    parser.add_argument("--limit", type=int, default=10)
    parser.add_argument("--json", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    term = args.query.strip()
    if not term:
        die("检索词为空")
    projects = [p.strip() for p in (args.projects or ["KP31"]) if p and p.strip()]
    normalized = []
    for project in projects:
        key = resolve_project(project)
        if key not in normalized:
            normalized.append(key)
    token = read_token(args.token_file)
    results = [query_project(args.host, token, project, term) for project in normalized]
    if args.json:
        json.dump(results if len(results) > 1 else results[0], sys.stdout, ensure_ascii=False, indent=2)
        sys.stdout.write("\n")
        return
    chunks = [render_markdown(result, args.limit) for result in results]
    sys.stdout.write("\n".join(chunks).rstrip() + "\n")


if __name__ == "__main__":
    main()
