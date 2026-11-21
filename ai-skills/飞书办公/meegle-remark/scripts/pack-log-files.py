#!/usr/bin/env python3
import argparse
import json
import sys
import zipfile
from pathlib import Path


def default_output(files):
    parents = {p.resolve().parent.name or "logs" for p in files}
    name = parents.pop() if len(parents) == 1 else "logs"
    return Path("/tmp") / f"{name}.zip"


def main():
    parser = argparse.ArgumentParser(description="Pack original log files into one zip")
    parser.add_argument("files", nargs="+", help="original log files")
    parser.add_argument("-o", "--output", help="zip path")
    args = parser.parse_args()

    files = []
    names = []
    seen = set()
    for raw in args.files:
        path = Path(raw)
        if not path.is_file():
            print(json.dumps({"ok": False, "error": f"missing: {raw}"}, ensure_ascii=False))
            sys.exit(1)
        name = path.name
        if name in seen:
            print(json.dumps({"ok": False, "error": f"duplicate basename: {name}"}, ensure_ascii=False))
            sys.exit(1)
        seen.add(name)
        names.append(name)
        files.append(path)

    out = Path(args.output) if args.output else default_output(files)
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.exists():
        out.unlink()

    with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_STORED) as zf:
        for path in files:
            zf.write(path, arcname=path.name)

    print(json.dumps({
        "ok": True,
        "zip_path": str(out),
        "filename": out.name,
        "files": names,
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
