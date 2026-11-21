#!/usr/bin/env python3
"""Fill the Feishu daily report from Meegle issue links."""

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from xml.etree import ElementTree as ET
from zoneinfo import ZoneInfo

DOC_URL = "https://t83dfrspj4.feishu.cn/wiki/HMLbwl1I6i2istkvgH9cYAOknjh"
TZ = ZoneInfo("Asia/Shanghai")
COLON = "\uff1a"
DATE_RE = re.compile(r"^(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])$")
LABEL_RE = re.compile(r"^(\d{4})年(\d{1,2})月(\d{1,2})日$")
ITEM_RE = re.compile(r"^(\d+)\s*[\uff1a:]\s*(.*)$", re.S)
ISSUE_RE = re.compile(r"/issue/detail/(\d+)")
SECTIONS = ("D01", "KP31")


@dataclass
class Block:
    id: str
    tag: str
    text: str
    issue_ids: set = field(default_factory=set)
    preview_ids: set = field(default_factory=set)
    bold: bool = False


@dataclass
class Entry:
    section: str
    issue_id: str
    url: str
    title: str
    raw_url: str


@dataclass
class Op:
    kind: str
    block_id: str
    content: str
    note: str


def run_json(cmd, timeout=90):
    proc = subprocess.run(cmd, text=True, capture_output=True, timeout=timeout)
    raw = (proc.stdout or "").strip()
    data = None
    if raw:
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            data = None
    if proc.returncode != 0:
        detail = raw or (proc.stderr or "").strip()
        raise RuntimeError(detail or f"command failed: {' '.join(cmd)}")
    if isinstance(data, dict) and data.get("ok") is False:
        raise RuntimeError(json.dumps(data, ensure_ascii=False))
    if data is None:
        raise RuntimeError(raw or (proc.stderr or "").strip() or f"empty output: {' '.join(cmd)}")
    return data


def format_date(value):
    return f"{value.year}年{value.month}月{value.day}日"


def parse_date_text(text, now=None):
    text = (text or "").strip()
    now = now or datetime.now(TZ)
    labeled = LABEL_RE.fullmatch(text)
    if labeled:
        year, month, day = (int(labeled.group(i)) for i in range(1, 4))
        return datetime(year, month, day, tzinfo=TZ)
    if not DATE_RE.fullmatch(text):
        return None
    month, day = int(text[:2]), int(text[2:])
    year = now.year
    if month <= 3 and now.month >= 10:
        year += 1
    elif month >= 10 and now.month <= 3:
        year -= 1
    return datetime(year, month, day, tzinfo=TZ)


def canonical_date(value, now=None):
    if isinstance(value, datetime):
        parsed = value
    else:
        parsed = parse_date_text(value, now=now)
    if parsed is None:
        raise ValueError(f"无法识别日期: {value}")
    return format_date(parsed)


def normalize_date(value):
    now = datetime.now(TZ)
    if not value:
        return format_date(now)
    text = value.strip()
    lowered = text.lower()
    if lowered in ("today", "今天"):
        return format_date(now)
    if lowered in ("yesterday", "昨天"):
        return format_date(now - timedelta(days=1))
    labeled = re.fullmatch(r"(\d{4})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*日?", text)
    if labeled:
        return canonical_date(datetime(
            int(labeled.group(1)), int(labeled.group(2)), int(labeled.group(3)), tzinfo=TZ
        ))
    for fmt in ("%Y-%m-%d", "%Y/%m/%d", "%m-%d", "%m/%d"):
        try:
            parsed = datetime.strptime(text, fmt)
        except ValueError:
            continue
        if fmt in ("%m-%d", "%m/%d"):
            parsed = parsed.replace(year=now.year)
        return format_date(parsed.replace(tzinfo=TZ))
    match = re.fullmatch(r"(\d{1,2})\s*月\s*(\d{1,2})\s*日?", text)
    if match:
        return format_date(datetime(now.year, int(match.group(1)), int(match.group(2)), tzinfo=TZ))
    if DATE_RE.fullmatch(text):
        return canonical_date(text, now=now)
    raise ValueError(f"无法识别日期: {value}")


def normalize_section(value):
    if value is None:
        return "auto"
    text = value.strip().lower().replace(" ", "")
    if text in ("auto", ""):
        return "auto"
    if text in ("d01", "do1", "d01p"):
        return "D01"
    if text in ("kp31", "k31"):
        return "KP31"
    raise ValueError(f"栏目只能是 D01 或 KP31: {value}")


def infer_section(title):
    text = title.upper()
    has_kp = "KP31" in text
    has_d01 = "D01" in text or "DO1" in text
    if has_kp and not has_d01:
        return "KP31"
    if has_d01 and not has_kp:
        return "D01"
    return None


def xml_text(value):
    return (
        value.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def xml_attr(value):
    return xml_text(value).replace('"', "&quot;")


def display_title(type_name, name):
    title = (name or "").replace("\r", " ").replace("\n", " ").strip()
    label = (type_name or "故障").strip() or "故障"
    prefix = f"[{label}]"
    if title.startswith(prefix):
        return title
    return prefix + title


def item_xml(number, entry):
    # Plain titled link. A Project url-preview makes the Feishu client open the project.
    return (
        f'<p>{number}{COLON}'
        f'<a href="{xml_attr(entry.url)}">{xml_text(entry.title)}</a></p>'
    )


def empty_item_xml(number=1):
    return f"<p>{number}{COLON}</p>"


def date_xml(date):
    # Bold, and no text color: Feishu default is black. There is no black font enum.
    return f"<p><b>{xml_text(canonical_date(date))}</b></p>"


def check_meegle_auth():
    try:
        status = run_json(["meegle", "auth", "status", "--format", "json"], timeout=30)
    except Exception as exc:
        return False, str(exc)
    if status.get("authenticated") is True:
        return True, status.get("host") or ""
    return False, "meegle 未登录"


def decode_issue(url):
    decoded = run_json(["meegle", "url", "decode", "--url", url, "--format", "json"])
    if decoded.get("url_kind") != "workitem_detail":
        raise RuntimeError(f"不是工作项详情链接: {url}")
    simple_name = decoded.get("simple_name")
    work_item_id = str(decoded.get("work_item_id") or "")
    host = decoded.get("host") or "project.feishu.cn"
    work_item_type = decoded.get("work_item_type") or "issue"
    if not simple_name or not work_item_id:
        raise RuntimeError(f"链接缺少空间或工作项 ID: {url}")
    # workitem get accepts simpleName. Do not call `meegle project search`:
    # resolving the space brings Feishu Project to the front.
    item = run_json([
        "meegle", "workitem", "get",
        "--work-item-id", work_item_id,
        "--project-key", simple_name,
        "--format", "json",
    ])
    attr = item.get("work_item_attribute") or item
    name = attr.get("work_item_name") or ""
    if not name:
        raise RuntimeError(f"工作项没有标题: {work_item_id}")
    type_info = attr.get("work_item_type") or {}
    type_name = type_info.get("name") if isinstance(type_info, dict) else ""
    canonical = f"https://{host}/{simple_name}/{work_item_type}/detail/{work_item_id}"
    return {
        "issue_id": work_item_id,
        "url": canonical,
        "title": display_title(type_name, name),
        "name": name,
    }


def fetch_document(doc_url):
    data = run_json([
        "lark-cli", "docs", "+fetch",
        "--as", "user",
        "--doc", doc_url,
        "--doc-format", "xml",
        "--scope", "full",
        "--detail", "with-ids",
    ])
    document = (data.get("data") or {}).get("document") or {}
    content = document.get("content") or ""
    revision = document.get("revision_id")
    document_id = document.get("document_id") or ""
    if not content:
        raise RuntimeError("日报文档内容为空")
    return parse_blocks(content), revision, document_id


def anchor_issue_ids(element, preview_only=False):
    found = set()
    for node in element.iter("a"):
        if preview_only and node.get("type") != "url-preview":
            continue
        found.update(ISSUE_RE.findall(node.get("href") or ""))
    return found


def parse_blocks(content):
    root = ET.fromstring(f"<root>{content}</root>")
    blocks = []
    for child in list(root):
        raw = ET.tostring(child, encoding="unicode")
        issue_ids = set(ISSUE_RE.findall(raw))
        issue_ids.update(anchor_issue_ids(child))
        preview_ids = anchor_issue_ids(child, preview_only=True)
        text = "".join(child.itertext()).strip()
        bold = any("".join(node.itertext()).strip() == text and text for node in child.iter("b"))
        blocks.append(Block(child.get("id") or "", child.tag, text, issue_ids, preview_ids, bold))
    return blocks


def is_date_block(block):
    return block.tag == "p" and parse_date_text(block.text) is not None


def is_section_block(block):
    return block.tag == "p" and block.text in SECTIONS


def parse_item(block):
    match = ITEM_RE.fullmatch(block.text or "")
    if not match:
        return None
    number = int(match.group(1))
    rest = (match.group(2) or "").strip()
    empty = not rest and not block.issue_ids
    return number, empty


def day_spans(blocks):
    indexes = [i for i, block in enumerate(blocks) if is_date_block(block)]
    spans = []
    for pos, start in enumerate(indexes):
        end = indexes[pos + 1] if pos + 1 < len(indexes) else len(blocks)
        spans.append((start, end, blocks[start].text))
    return spans


def section_items(blocks, start, end, section):
    header = None
    items = []
    for idx in range(start + 1, end):
        block = blocks[idx]
        if is_section_block(block):
            if block.text == section and header is None:
                header = idx
                continue
            if header is not None:
                break
            continue
        if header is None:
            continue
        parsed = parse_item(block)
        if parsed:
            number, empty = parsed
            items.append((idx, number, empty, block))
    return header, items


def locate_day(blocks, date):
    target = parse_date_text(date)
    for start, end, label in day_spans(blocks):
        if parse_date_text(label) == target:
            return start, end
    return None


def insert_anchor(blocks, date):
    spans = day_spans(blocks)
    if not spans:
        return None, False, False
    target = parse_date_text(date)
    last_label = spans[-1][2]
    if target > parse_date_text(last_label):
        last = blocks[-1]
        return None, bool(last.text.strip()), False
    for start, _end, label in spans:
        if parse_date_text(label) > target:
            anchor = blocks[start - 1]
            return anchor.id, bool(anchor.text.strip()), True
    last = blocks[-1]
    return None, bool(last.text.strip()), False


def day_xml(date, grouped, leading_blank, trailing_blank):
    parts = []
    if leading_blank:
        parts.append("<p></p>")
    parts.append(date_xml(date))
    for section in SECTIONS:
        parts.append(f"<p>{section}</p>")
        entries = grouped.get(section) or []
        if entries:
            parts.extend(item_xml(i, entry) for i, entry in enumerate(entries, 1))
        else:
            parts.append(empty_item_xml(1))
        if section == "D01":
            parts.append("<p></p>")
    if trailing_blank:
        parts.append("<p></p>")
    return "".join(parts)


def already_in_section(items, issue_id):
    for idx, number, empty, block in items:
        if issue_id in block.issue_ids:
            return number, issue_id in block.preview_ids
    return None, False


def plan(blocks, date, entries):
    date = canonical_date(date)
    skipped = []
    grouped = {section: [] for section in SECTIONS}
    seen = set()
    for entry in entries:
        key = (entry.section, entry.issue_id)
        if key in seen:
            skipped.append({
                "section": entry.section,
                "issue_id": entry.issue_id,
                "url": entry.url,
                "title": entry.title,
                "reason": "本次重复",
            })
            continue
        seen.add(key)
        grouped[entry.section].append(entry)

    located = locate_day(blocks, date)
    added = []
    ops = []
    if located is None:
        fresh = {section: [] for section in SECTIONS}
        for section in SECTIONS:
            for entry in grouped[section]:
                fresh[section].append(entry)
                added.append(preview(date, section, len(fresh[section]), entry))
        if not added:
            return ops, added, skipped
        anchor, leading, trailing = insert_anchor(blocks, date)
        content = day_xml(date, fresh, leading, trailing)
        if anchor:
            ops.append(Op("insert_after", anchor, content, f"插入日期 {date}"))
        else:
            ops.append(Op("append", "", content, f"追加日期 {date}"))
        return ops, added, skipped

    start, end = located
    for section in SECTIONS:
        header, items = section_items(blocks, start, end, section)
        pending = []
        for entry in grouped[section]:
            number, has_preview = already_in_section(items, entry.issue_id)
            if number is not None:
                skipped.append({
                    "section": section,
                    "issue_id": entry.issue_id,
                    "url": entry.url,
                    "title": entry.title,
                    "number": number,
                    "needs_preview": not has_preview,
                    "reason": f"已在 {date} {section} 第 {number} 条",
                })
                continue
            pending.append(entry)
        if not pending:
            continue
        if header is None:
            xml_parts = [f"<p>{section}</p>"]
            xml_parts.extend(item_xml(i, entry) for i, entry in enumerate(pending, 1))
            if section == "KP31":
                prev = blocks[end - 1]
                if prev.text.strip():
                    xml_parts.insert(0, "<p></p>")
                anchor_id = prev.id
            else:
                anchor_id = blocks[start].id
                xml_parts.append("<p></p>")
            ops.append(Op("insert_after", anchor_id, "".join(xml_parts), f"新增栏目 {section}"))
            for i, entry in enumerate(pending, 1):
                added.append(preview(date, section, i, entry))
            continue
        filled = [item for item in items if not item[2]]
        next_number = (max(item[1] for item in filled) + 1) if filled else 1
        placeholder = next((item for item in items if item[2] and item[1] == next_number), None)
        if placeholder is not None:
            _idx, _number, _empty, block = placeholder
            ops.append(Op(
                "replace",
                block.id,
                "".join(item_xml(next_number + offset, entry) for offset, entry in enumerate(pending)),
                f"填入 {section} {next_number}",
            ))
        else:
            anchor_id = filled[-1][3].id if filled else blocks[header].id
            ops.append(Op(
                "insert_after",
                anchor_id,
                "".join(item_xml(next_number + offset, entry) for offset, entry in enumerate(pending)),
                f"{section} 追加",
            ))
        for offset, entry in enumerate(pending):
            added.append(preview(date, section, next_number + offset, entry))
    return ops, added, skipped


def preview(date, section, number, entry):
    return {
        "date": date,
        "section": section,
        "number": number,
        "issue_id": entry.issue_id,
        "url": entry.url,
        "title": entry.title,
    }


def simulate(blocks, ops):
    result = list(blocks)
    seq = 0
    for op in ops:
        created = parse_blocks(op.content)
        for block in created:
            if not block.id:
                seq += 1
                block.id = f"sim{seq}"
        if op.kind == "append":
            result.extend(created)
            continue
        idx = next(i for i, block in enumerate(result) if block.id == op.block_id)
        if op.kind == "insert_after":
            result[idx + 1:idx + 1] = created
        elif op.kind == "replace":
            result[idx:idx + 1] = created
        else:
            raise RuntimeError(f"unknown op: {op.kind}")
    return result


def apply_op(doc_url, op):
    cmd = [
        "lark-cli", "docs", "+update",
        "--as", "user",
        "--doc", doc_url,
        "--doc-format", "xml",
        "--command", "append" if op.kind == "append" else (
            "block_replace" if op.kind == "replace" else "block_insert_after"
        ),
        "--content", "-",
    ]
    if op.kind != "append":
        cmd.extend(["--block-id", op.block_id])
    proc = subprocess.run(cmd, input=op.content, text=True, capture_output=True, timeout=120)
    raw = (proc.stdout or "").strip()
    if proc.returncode != 0:
        raise RuntimeError(raw or (proc.stderr or "").strip() or f"{op.note} 写入失败")
    try:
        data = json.loads(raw) if raw else {}
    except json.JSONDecodeError as exc:
        raise RuntimeError(raw or str(exc)) from exc
    if data.get("ok") is False or (data.get("data") or {}).get("result") not in (None, "success"):
        result = (data.get("data") or {}).get("result")
        if result and result != "success":
            raise RuntimeError(json.dumps(data, ensure_ascii=False))
    warnings = ((data.get("data") or {}).get("warnings") or [])
    return warnings


def preview_is_project(elements, issue_id):
    for element in elements or []:
        preview = element.get("link_preview") or {}
        url = preview.get("url") or ""
        if preview.get("url_type") == "Project" and issue_id and issue_id in url:
            return True
    return False


def promote_previews(document_id, blocks, date, added):
    # Project url previews make the Feishu client open the project. Never upgrade.
    return []


def preview_targets(added, skipped):
    targets = list(added)
    seen = {(item["section"], item["issue_id"]) for item in added}
    for item in skipped:
        if not item.get("needs_preview") or "number" not in item:
            continue
        key = (item["section"], item["issue_id"])
        if key in seen:
            continue
        seen.add(key)
        targets.append(item)
    return targets


def verify(blocks, date, added):
    located = locate_day(blocks, date)
    if located is None:
        return [f"写入后没有找到日期 {date}"]
    start, end = located
    problems = []
    for item in added:
        header, items = section_items(blocks, start, end, item["section"])
        found = None
        for _idx, number, empty, block in items:
            if item["issue_id"] in block.issue_ids and not empty:
                found = number
                break
        if found is None:
            problems.append(f"未找到 {item['section']} {item['issue_id']}")
        elif found != item["number"]:
            problems.append(
                f"{item['section']} {item['issue_id']} 编号是 {found}，预期 {item['number']}"
            )
    return problems



def preview_problems(notes):
    return [note for note in notes if note.startswith("预览升级失败") or note.startswith("找不到可升级")]


def collect_entries(args):
    specs = []
    for section, url in args.entry or []:
        specs.append((normalize_section(section), url))
    default_section = normalize_section(args.section)
    for url in args.urls:
        specs.append((default_section, url))
    if not specs:
        raise ValueError("缺少飞书项目链接")
    resolved = []
    ambiguous = []
    for section, url in specs:
        info = decode_issue(url)
        chosen = section
        if chosen == "auto":
            chosen = infer_section(info["name"]) or infer_section(info["title"])
        if chosen not in SECTIONS:
            ambiguous.append({"url": url, "title": info["title"]})
            continue
        resolved.append(Entry(chosen, info["issue_id"], info["url"], info["title"], url))
    if ambiguous:
        raise SystemExit(json.dumps({
            "ok": False,
            "error": "ambiguous_section",
            "message": "这些链接看不出是 D01 还是 KP31，请指定栏目",
            "items": ambiguous,
        }, ensure_ascii=False))
    return resolved


def style_dates(document_id, blocks):
    if not document_id:
        return []
    notes = []
    for block in blocks:
        parsed = parse_date_text(block.text)
        if parsed is None or not block.id:
            continue
        label = format_date(parsed)
        if block.text == label and block.bold:
            continue
        body = {
            "update_text_elements": {
                "elements": [{
                    "text_run": {
                        "content": label,
                        "text_element_style": {
                            "bold": True,
                            "inline_code": False,
                            "italic": False,
                            "strikethrough": False,
                            "underline": False,
                        },
                    }
                }]
            }
        }
        run_json([
            "lark-cli", "api", "PATCH",
            f"/open-apis/docx/v1/documents/{document_id}/blocks/{block.id}",
            "--as", "user",
            "--data", json.dumps(body, ensure_ascii=False),
        ])
        notes.append(f"日期标题已改为 {label}")
    return notes


def execute(args):
    date = normalize_date(args.date)
    ok, detail = check_meegle_auth()
    if not ok:
        print(json.dumps({
            "ok": False,
            "error": "meegle_auth",
            "message": "Meegle 未登录。先按 meegle auth-guard 登录，再重跑本脚本。",
            "detail": detail,
        }, ensure_ascii=False))
        return 3
    entries = collect_entries(args)
    doc_url = args.doc or DOC_URL
    added = []
    skipped = []
    ops = []
    warnings = []

    def plan_sections(blocks):
        planned_ops = []
        planned_added = []
        planned_skipped = []
        current = blocks
        for section in SECTIONS:
            section_entries = [entry for entry in entries if entry.section == section]
            if not section_entries:
                continue
            section_ops, section_added, section_skipped = plan(current, date, section_entries)
            planned_ops.extend(section_ops)
            planned_added.extend(section_added)
            planned_skipped.extend(section_skipped)
            current = simulate(current, section_ops)
        return planned_ops, planned_added, planned_skipped

    blocks, _revision, document_id = fetch_document(doc_url)
    if not args.dry_run:
        warnings.extend(style_dates(document_id, blocks))
        if warnings:
            blocks, _revision, document_id = fetch_document(doc_url)
    if args.dry_run:
        ops, added, skipped = plan_sections(blocks)
        print(json.dumps({
            "ok": True,
            "date": date,
            "doc": doc_url,
            "dry_run": True,
            "added": added,
            "skipped": skipped,
            "ops": [{"kind": op.kind, "block_id": op.block_id, "note": op.note} for op in ops],
        }, ensure_ascii=False, indent=2))
        return 0

    for section in SECTIONS:
        section_entries = [entry for entry in entries if entry.section == section]
        if not section_entries:
            continue
        blocks, _revision, document_id = fetch_document(doc_url)
        section_ops, section_added, section_skipped = plan(blocks, date, section_entries)
        added.extend(section_added)
        skipped.extend(section_skipped)
        ops.extend(section_ops)
        for op in section_ops:
            warnings.extend(apply_op(doc_url, op))

    blocks, _revision, document_id = fetch_document(doc_url)
    preview_notes = promote_previews(document_id, blocks, date, preview_targets(added, skipped))
    warnings.extend(preview_notes)
    blocks, _revision, document_id = fetch_document(doc_url)
    problems = verify(blocks, date, preview_targets(added, skipped))
    problems.extend(preview_problems(preview_notes))
    if problems:
        added = []
        skipped = []
        ops = []
        for section in SECTIONS:
            section_entries = [entry for entry in entries if entry.section == section]
            if not section_entries:
                continue
            blocks, _revision, document_id = fetch_document(doc_url)
            section_ops, section_added, section_skipped = plan(blocks, date, section_entries)
            added.extend(section_added)
            skipped.extend(section_skipped)
            ops.extend(section_ops)
            for op in section_ops:
                warnings.extend(apply_op(doc_url, op))
        blocks, _revision, document_id = fetch_document(doc_url)
        preview_notes = promote_previews(document_id, blocks, date, preview_targets(added, skipped))
        warnings.extend(preview_notes)
        blocks, _revision, document_id = fetch_document(doc_url)
        problems = verify(blocks, date, preview_targets(added, skipped))
        problems.extend(preview_problems(preview_notes))
    print(json.dumps({
        "ok": not problems,
        "date": date,
        "doc": doc_url,
        "dry_run": False,
        "added": added,
        "skipped": skipped,
        "warnings": warnings,
        "verify": problems,
        "ops": [{"kind": op.kind, "block_id": op.block_id, "note": op.note} for op in ops],
    }, ensure_ascii=False, indent=2))
    return 0 if not problems else 1


def sample_blocks():
    xml = """
<title id="title">工作汇总06</title>
<p id="d1027">1027</p>
<p id="d01a">D01</p>
<p id="a1">1：<a href="https://project.feishu.cn/pojw7j/issue/detail/111">[故障]甲</a></p>
<p id="a2">2：<a href="https://project.feishu.cn/pojw7j/issue/detail/222">[故障]乙</a></p>
<p id="a3">3：</p>
<p id="blank1"></p>
<p id="d1030">1030</p>
<p id="d01b">D01</p>
<p id="b1">1：<a href="https://project.feishu.cn/pojw7j/issue/detail/7147253441">[故障]已有</a></p>
<p id="blank2"></p>
<p id="kp">KP31</p>
<p id="k1">1：</p>
""".strip()
    return parse_blocks(xml)


def entry(section, issue_id, title="标题"):
    return Entry(
        section,
        issue_id,
        f"https://project.feishu.cn/pojw7j/issue/detail/{issue_id}",
        f"[故障]{title}",
        f"https://project.feishu.cn/pojw7j/issue/detail/{issue_id}",
    )


def self_test():
    blocks = sample_blocks()
    ops, added, skipped = plan(blocks, "1030", [entry("KP31", "9001", "新缺陷")])
    assert len(ops) == 1 and ops[0].kind == "replace" and ops[0].block_id == "k1", ops
    assert added[0]["number"] == 1, added
    assert "9001" in ops[0].content and ops[0].content.startswith(f"<p>1{COLON}<a "), ops[0].content

    ops, added, skipped = plan(blocks, "1030", [
        entry("KP31", "9001", "一"),
        entry("KP31", "9002", "二"),
    ])
    assert len(ops) == 1 and ops[0].kind == "replace" and ops[0].block_id == "k1", ops
    assert f"1{COLON}" in ops[0].content and f"2{COLON}" in ops[0].content
    assert added[0]["number"] == 1 and added[1]["number"] == 2

    ops, added, skipped = plan(blocks, "1030", [entry("D01", "9003", "第二条")])
    assert len(ops) == 1 and ops[0].kind == "insert_after" and ops[0].block_id == "b1", ops
    assert added[0]["number"] == 2

    ops, added, skipped = plan(blocks, "1030", [entry("D01", "7147253441", "已有")])
    assert ops == [] and skipped and "已在" in skipped[0]["reason"], skipped

    ops, added, skipped = plan(blocks, "1027", [entry("D01", "9004", "第三条")])
    assert ops[0].kind == "replace" and ops[0].block_id == "a3", ops
    assert added[0]["number"] == 3

    ops, added, skipped = plan(blocks, "1031", [entry("D01", "9005", "新的一天")])
    assert ops[0].kind == "append", ops
    next_day = canonical_date("1031")
    assert f"<p><b>{next_day}</b></p><p>D01</p><p>1{COLON}<a " in ops[0].content
    assert f"<p>KP31</p><p>1{COLON}</p>" in ops[0].content
    assert ops[0].content.startswith("<p></p>")

    ops, added, skipped = plan(blocks, "1029", [entry("KP31", "9006", "补昨天")])
    assert ops[0].kind == "insert_after" and ops[0].block_id == "blank1", ops
    assert f"<p><b>{canonical_date('1029')}</b></p>" in ops[0].content and ops[0].content.endswith("<p></p>")

    fresh = simulate(sample_blocks(), plan(sample_blocks(), "1031", [entry("D01", "1", "甲")])[0])
    ops, added, skipped = plan(fresh, "1031", [entry("KP31", "2", "乙")])
    assert ops and ops[0].kind == "replace", ops
    assert added[0]["number"] == 1 and added[0]["section"] == "KP31"

    assert normalize_date("2026-11-01") == "2026年11月1日"
    assert normalize_date("10月31日") == f"{datetime.now(TZ).year}年10月31日"
    assert normalize_date("2026年10月30日") == "2026年10月30日"
    assert parse_date_text("1030") == parse_date_text("2026年10月30日")
    bold_date = parse_blocks('<p id="d"><b>2026年10月30日</b></p>')
    assert bold_date[0].bold and bold_date[0].text == "2026年10月30日"
    assert infer_section("【D01P国际右舵】测试") == "D01"
    assert infer_section("【KP31】测试") == "KP31"
    assert infer_section("【VPA设置】测试") is None
    assert display_title("故障", "【D01】示例") == "[故障]【D01】示例"
    assert display_title("故障", "[故障]已有前缀") == "[故障]已有前缀"
    assert preview_is_project([
        {"link_preview": {"url": "https://project.feishu.cn/pojw7j/issue/detail/1", "url_type": "Message"}}
    ], "1") is False
    assert preview_is_project([
        {"link_preview": {"url": "https://project.feishu.cn/pojw7j/issue/detail/1", "url_type": "Project"}},
    ], "1") is True
    sample = parse_blocks(
        '<p id="p1">1：<a href="https://project.feishu.cn/pojw7j/issue/detail/9" type="url-preview" url-type="1">标题</a></p>'
        '<p id="p2">2：<a href="https://project.feishu.cn/pojw7j/issue/detail/8">纯链接</a></p>'
    )
    assert sample[0].preview_ids == {"9"} and "9" in sample[0].issue_ids
    assert sample[1].preview_ids == set() and "8" in sample[1].issue_ids
    written = item_xml(1, entry("D01", "7147253441", "示例"))
    assert 'type="url-preview"' not in written and 'url-type=' not in written
    assert 'href="https://project.feishu.cn/pojw7j/issue/detail/7147253441"' in written
    print("self-test ok")
    return 0


def main():
    parser = argparse.ArgumentParser(description="填写飞书日报")
    parser.add_argument("urls", nargs="*", help="project.feishu.cn 工作项链接")
    parser.add_argument("--section", default="auto", help="D01、KP31 或 auto")
    parser.add_argument("--entry", action="append", nargs=2, metavar=("SECTION", "URL"))
    parser.add_argument("--date", help="2026年10月30日、MMDD、YYYY-MM-DD、今天、昨天；默认今天")
    parser.add_argument("--doc", default=DOC_URL)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    try:
        if args.self_test:
            return self_test()
        return execute(args)
    except SystemExit as exc:
        if isinstance(exc.code, str):
            print(exc.code)
            return 2
        raise
    except ValueError as exc:
        print(json.dumps({"ok": False, "error": "bad_args", "message": str(exc)}, ensure_ascii=False))
        return 2
    except Exception as exc:
        print(json.dumps({"ok": False, "error": "failed", "message": str(exc)}, ensure_ascii=False))
        return 1


if __name__ == "__main__":
    sys.exit(main())
