#!/usr/bin/env python3
"""Compare Android Studio font sizes with the recorded baseline and restore if needed."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from typing import Optional

SKILL_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BASELINE_PATH = os.path.join(SKILL_DIR, "assets", "as-font-baseline.json")
STUDIO_HOME = os.environ.get("ANDROID_STUDIO_HOME", "/opt/android-studio")


def load_baseline() -> dict:
    with open(BASELINE_PATH, encoding="utf-8") as fh:
        return json.load(fh)


def find_options_dir() -> str:
    selector = None
    product_info = os.path.join(STUDIO_HOME, "product-info.json")
    if os.path.isfile(product_info):
        with open(product_info, encoding="utf-8") as fh:
            selector = json.load(fh).get("dataDirectoryName")
    if selector:
        path = os.path.expanduser(f"~/.config/Google/{selector}/options")
        if os.path.isdir(path):
            return path
    root = os.path.expanduser("~/.config/Google")
    candidates = []
    if os.path.isdir(root):
        for name in os.listdir(root):
            if name.startswith("AndroidStudio"):
                options = os.path.join(root, name, "options")
                if os.path.isdir(options):
                    candidates.append(options)
    if not candidates:
        raise SystemExit("未找到 Android Studio 配置目录")
    candidates.sort(key=os.path.getmtime, reverse=True)
    return candidates[0]


def xml_option(path: str, component: str, name: str) -> Optional[str]:
    if not os.path.isfile(path):
        return None
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError:
        return None
    for comp in root.findall("component"):
        if comp.get("name") != component:
            continue
        for opt in comp.findall("option"):
            if opt.get("name") == name:
                return opt.get("value")
    return None


def set_xml_options(path: str, component: str, updates: dict[str, Optional[str]]) -> bool:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if os.path.isfile(path):
        tree = ET.parse(path)
        root = tree.getroot()
    else:
        root = ET.Element("application")
        tree = ET.ElementTree(root)
    comp = None
    for item in root.findall("component"):
        if item.get("name") == component:
            comp = item
            break
    if comp is None:
        comp = ET.SubElement(root, "component")
        comp.set("name", component)
        ET.SubElement(comp, "option").set("name", "VERSION")
        list(comp)[-1].set("value", "1")
    changed = False
    for name, value in updates.items():
        existing = None
        for opt in list(comp.findall("option")):
            if opt.get("name") != name:
                continue
            existing = opt
            if value is None:
                comp.remove(opt)
                changed = True
            elif opt.get("value") != value:
                opt.set("value", value)
                changed = True
            break
        if existing is None and value is not None:
            opt = ET.SubElement(comp, "option")
            opt.set("name", name)
            opt.set("value", value)
            changed = True
    if changed:
        ET.indent(tree, space="  ")
        tree.write(path, encoding="utf-8")
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        if not text.endswith("\n"):
            with open(path, "a", encoding="utf-8") as fh:
                fh.write("\n")
    return changed


def not_roamable_block(text: str) -> Optional[str]:
    match = re.search(
        r'<component name="NotRoamableUiSettings">.*?</component>',
        text,
        re.S,
    )
    return match.group(0) if match else None


def not_roamable_option(other_xml: str, name: str) -> Optional[str]:
    if not os.path.isfile(other_xml):
        return None
    text = open(other_xml, encoding="utf-8").read()
    block = not_roamable_block(text)
    if not block:
        return None
    opt = re.search(rf'<option name="{re.escape(name)}" value="([^"]*)"', block)
    return opt.group(1) if opt else None


def ui_font_size(other_xml: str) -> Optional[str]:
    return not_roamable_option(other_xml, "fontSize")


def set_not_roamable_options(other_xml: str, updates: dict[str, Optional[str]]) -> bool:
    if not os.path.isfile(other_xml):
        return False
    text = open(other_xml, encoding="utf-8").read()
    match = re.search(
        r'(<component name="NotRoamableUiSettings">)(.*?)(</component>)',
        text,
        re.S,
    )
    if not match:
        return False
    body = match.group(2)
    changed = False
    for name, value in updates.items():
        existing = re.search(
            rf'<option name="{re.escape(name)}" value="([^"]*)"',
            body,
        )
        if value is None:
            if existing:
                body, count = re.subn(
                    rf'\n[ \t]*<option name="{re.escape(name)}" value="[^"]*" />',
                    "",
                    body,
                    count=1,
                )
                if count:
                    changed = True
            continue
        if existing:
            if existing.group(1) == value:
                continue
            body, count = re.subn(
                rf'(<option name="{re.escape(name)}" value=")[^"]*(" />)',
                rf"\g<1>{value}\2",
                body,
                count=1,
            )
            if count:
                changed = True
            continue
        body = f'\n    <option name="{name}" value="{value}" />' + body
        changed = True
    if not changed:
        return False
    new_text = text[: match.start()] + match.group(1) + body + match.group(3) + text[match.end() :]
    open(other_xml, "w", encoding="utf-8").write(new_text)
    return True


def font_scale_ok(value: Optional[str]) -> bool:
    if value is None:
        return False
    try:
        return float(value) > 0
    except ValueError:
        return False


def read_current(options_dir: str) -> dict:
    editor = os.path.join(options_dir, "editor-font.xml")
    terminal = os.path.join(options_dir, "terminal-font.xml")
    console = os.path.join(options_dir, "console-font.xml")
    other = os.path.join(options_dir, "other.xml")
    return {
        "ui_font_size": ui_font_size(other),
        "override_laf_fonts": not_roamable_option(other, "overrideLafFonts"),
        "ui_font_scale": not_roamable_option(other, "fontScale"),
        "ui_font_face": not_roamable_option(other, "fontFace"),
        "editor_font_size": xml_option(editor, "DefaultFont", "FONT_SIZE"),
        "editor_font_size_2d": xml_option(editor, "DefaultFont", "FONT_SIZE_2D"),
        "terminal_font_size": xml_option(terminal, "TerminalFontOptions", "FONT_SIZE"),
        "terminal_font_size_2d": xml_option(terminal, "TerminalFontOptions", "FONT_SIZE_2D"),
        "console_font_size": xml_option(console, "ConsoleFont", "FONT_SIZE"),
        "console_font_size_2d": xml_option(console, "ConsoleFont", "FONT_SIZE_2D"),
    }


LABELS = [
    ("ui_font_size", "界面"),
    ("editor_font_size", "编辑器"),
    ("editor_font_size_2d", "编辑器2D"),
    ("terminal_font_size", "终端"),
    ("terminal_font_size_2d", "终端2D"),
    ("console_font_size", "控制台"),
    ("console_font_size_2d", "控制台2D"),
]


def diffs(current: dict, baseline: dict) -> list[tuple[str, str, Optional[str], Optional[str]]]:
    items = []
    for key, label in LABELS:
        expected = baseline.get(key)
        actual = current.get(key)
        if expected != actual:
            items.append((key, label, actual, expected))
    if baseline.get("ui_font_size"):
        expected_override = baseline.get("override_laf_fonts") or "true"
        if current.get("override_laf_fonts") != expected_override:
            items.append(("override_laf_fonts", "界面自定义字体", current.get("override_laf_fonts"), expected_override))
        expected_scale = baseline.get("ui_font_scale") or "1.0"
        if current.get("ui_font_scale") != expected_scale and not (
            expected_scale == "1.0" and font_scale_ok(current.get("ui_font_scale")) and baseline.get("ui_font_scale") is None
        ):
            if current.get("ui_font_scale") != expected_scale:
                items.append(("ui_font_scale", "界面fontScale", current.get("ui_font_scale"), expected_scale))
        expected_face = baseline.get("ui_font_face")
        if expected_face and current.get("ui_font_face") != expected_face:
            items.append(("ui_font_face", "界面字体", current.get("ui_font_face"), expected_face))
    return items


def apply_baseline(options_dir: str, baseline: dict) -> list[str]:
    changed = []
    other = os.path.join(options_dir, "other.xml")
    ui_updates = {
        "fontSize": baseline["ui_font_size"],
        "fontScale": baseline.get("ui_font_scale") or "1.0",
        "overrideLafFonts": baseline.get("override_laf_fonts") or "true",
    }
    face = baseline.get("ui_font_face") or not_roamable_option(other, "fontFace") or "Inter"
    ui_updates["fontFace"] = face
    if set_not_roamable_options(other, ui_updates):
        changed.append("界面")
    if set_xml_options(
        os.path.join(options_dir, "editor-font.xml"),
        "DefaultFont",
        {
            "FONT_SIZE": baseline["editor_font_size"],
            "FONT_SIZE_2D": baseline["editor_font_size_2d"],
        },
    ):
        changed.append("编辑器")
    if set_xml_options(
        os.path.join(options_dir, "terminal-font.xml"),
        "TerminalFontOptions",
        {
            "FONT_SIZE": baseline["terminal_font_size"],
            "FONT_SIZE_2D": baseline["terminal_font_size_2d"],
        },
    ):
        changed.append("终端")
    if set_xml_options(
        os.path.join(options_dir, "console-font.xml"),
        "ConsoleFont",
        {
            "FONT_SIZE": baseline["console_font_size"],
            "FONT_SIZE_2D": baseline["console_font_size_2d"],
        },
    ):
        changed.append("控制台")
    return changed


def fmt(value: Optional[str]) -> str:
    return "默认" if value is None else value


def fmt_item(key: str, value: Optional[str]) -> str:
    if key == "override_laf_fonts":
        return "开" if value == "true" else "关"
    return fmt(value)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="only compare, do not write")
    args = parser.parse_args()
    baseline = load_baseline()
    options_dir = find_options_dir()
    current = read_current(options_dir)
    mismatch = diffs(current, baseline)
    if not mismatch:
        print(f"字体已与记录一致: {options_dir}")
        for key, label in LABELS:
            if key.endswith("_2d"):
                continue
            print(f"- {label}: {fmt_item(key, current.get(key))}")
        return 0
    print(f"字体与记录不一致: {options_dir}")
    for key, label, actual, expected in mismatch:
        print(f"- {label}: {fmt_item(key, actual)} -> {fmt_item(key, expected)}")
    if args.check:
        return 1
    changed = apply_baseline(options_dir, baseline)
    after = diffs(read_current(options_dir), baseline)
    if after:
        print("字体同步失败，仍不一致")
        for key, label, actual, expected in after:
            print(f"- {label}: {fmt_item(key, actual)} -> {fmt_item(key, expected)}")
        return 1
    print("已同步字体大小: " + "、".join(changed) if changed else "已同步字体大小")
    return 0


if __name__ == "__main__":
    sys.exit(main())
