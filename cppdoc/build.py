import json
import os
import sys
import urllib.request
from concurrent.futures import ProcessPoolExecutor

from convert import convert

BASE = "https://documents.devdocs.io/cpp/"
USER_AGENT = "cppdoc-nvim (https://github.com/neovim/neovim)"


def fetch(name):
    req = urllib.request.Request(BASE + name, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=180) as r:
        return json.load(r)


def render(item):
    path, html = item
    try:
        return path, convert(html), None
    except Exception as e:
        return path, None, str(e)


def main(out_dir):
    md_dir = os.path.join(out_dir, "md")
    os.makedirs(md_dir, exist_ok=True)

    print("downloading index...", flush=True)
    entries = fetch("index.json")["entries"]
    print("downloading pages...", flush=True)
    db = fetch("db.json")

    paths = sorted({e["path"] for e in entries if e["path"] in db})
    print(f"converting {len(paths)} pages...", flush=True)

    converted, failed = set(), []
    with ProcessPoolExecutor() as pool:
        for path, md, err in pool.map(render, ((p, db[p]) for p in paths), chunksize=16):
            if err:
                failed.append((path, err))
                continue
            target = os.path.join(md_dir, path + ".md")
            os.makedirs(os.path.dirname(target), exist_ok=True)
            with open(target, "w") as f:
                f.write(md)
            converted.add(path)
            if len(converted) % 500 == 0:
                print(f"  {len(converted)}/{len(paths)}", flush=True)

    names = {e["name"]: e["path"] for e in entries if e["path"] in converted}
    with open(os.path.join(out_dir, "index.json"), "w") as f:
        json.dump(names, f)

    for path, err in failed:
        print(f"failed: {path}: {err}", file=sys.stderr)
    print(f"done: {len(converted)} pages, {len(names)} names, {len(failed)} failed -> {out_dir}", flush=True)


if __name__ == "__main__":
    main(sys.argv[1])
