import re
import subprocess
import sys

import lxml.html as LH
from lxml.etree import SubElement

DECL = "data-cppdoc-decl"
CHROME = (
    "//div[contains(@class, '_attribution')] | //div[contains(@class, 't-inheritance-diagram')]"
    " | //p[normalize-space(.)='Inheritance diagram'] | //figure | //img"
)
TOKEN_CLASS = re.compile(r"^[a-z]{1,2}\d?$")
IDENTIFIER = re.compile(r"[A-Za-z_]\w*")
KIND_WORDS = {
    "public", "protected", "private", "member", "function", "type", "class",
    "template", "alias", "object", "constant", "enum", "typedef", "concept",
    "struct", "union", "and", "specialization",
}


def squash(el):
    return re.sub(r"\s+", " ", el.text_content()).strip()


def append_text(el, text):
    if len(el):
        el[-1].tail = (el[-1].tail or "") + text
    else:
        el.text = (el.text or "") + text


def is_token(el):
    return el is not None and el.tag == "span" and TOKEN_CLASS.match(el.get("class") or "") is not None


def wrap_highlighted(root):
    for span in root.xpath("//span[@class]"):
        if span.getparent() is None or not is_token(span) or span.xpath("ancestor::pre | ancestor::code"):
            continue
        previous = span.getprevious()
        if is_token(previous) and not (previous.tail or "").strip():
            continue

        run = [span]
        while is_token(run[-1].getnext()) and not (run[-1].tail or "").strip():
            run.append(run[-1].getnext())

        code = LH.Element("code")
        code.text = "".join(s.text_content() + (s.tail or "") for s in run[:-1]) + run[-1].text_content()
        code.tail = run[-1].tail
        span.addprevious(code)
        for s in run:
            s.getparent().remove(s)


def rewrite_declarations(root):
    for t in root.xpath("//table[contains(@class, 't-dcl-begin') or contains(@class, 't-sdsc-begin')]"):
        out = []
        for tr in t.xpath(".//tr"):
            tds = tr.xpath("./td")
            if len(tds) < 2:
                head = squash(tr)
                if head:
                    out += ["", "// " + head]
                continue
            code = tds[0].text_content().strip("\n").rstrip()
            if not code.strip():
                continue
            lines = code.split("\n")
            lines[0] = lines[0].lstrip()
            marks = " ".join(m for m in map(squash, tds[1:3]) if m)
            if marks:
                lines[-1] += "  // " + marks
            out.extend(lines)

        pre = LH.Element("pre")
        code = SubElement(pre, "code")
        code.set("class", "cpp")
        code.text = "\n".join(out).strip("\n")
        if "t-dcl-begin" in t.get("class"):
            pre.set(DECL, "1")
        t.getparent().replace(t, pre)


def rewrite_tables(root):
    for t in root.xpath("//table[contains(@class, 't-par-begin') or contains(@class, 't-dsc-begin')]"):
        described = "t-dsc-begin" in t.get("class")
        ul = LH.Element("ul")
        for tr in t.xpath(".//tr"):
            tds = tr.xpath("./td")
            if not tds or not squash(tr):
                continue
            li = SubElement(ul, "li")

            versions = [squash(m) for m in tds[0].xpath(".//span[contains(@class, 't-mark')]")]
            for m in tds[0].xpath(".//span[contains(@class, 't-mark')]"):
                m.drop_tree()
            name = squash(tds[0])
            body = tds[-1] if len(tds) > 1 else None

            if body is None or not squash(body):
                if described:
                    SubElement(li, "strong").text = name
                else:
                    li.text = re.sub(r"^\s*-\s*", "", tds[0].text or "")
                    for child in list(tds[0]):
                        li.append(child)
                continue

            kind = []
            for mark in body.xpath(".//span[@class='t-mark']"):
                words = squash(mark).strip("()").lower().split()
                if words and all(w in KIND_WORDS for w in words):
                    kind = words
                    if mark.getprevious() is not None and mark.getprevious().tag == "br":
                        mark.getprevious().drop_tree()
                    mark.drop_tree()

            code = SubElement(li, "code")
            code.text = name + "()" if "function" in kind and IDENTIFIER.fullmatch(name) else name
            for version in versions:
                append_text(li, " ")
                SubElement(li, "em").text = version
            append_text(li, " — " + (body.text or "").lstrip())
            for child in list(body):
                li.append(child)

        if len(ul):
            t.getparent().replace(t, ul)
        else:
            t.drop_tree()


def italicize_marks(root):
    for span in root.xpath("//span[contains(@class, 't-mark')]"):
        span.tag = "em"
        span.attrib.clear()


def flatten_tables(root):
    while True:
        leaves = [t for t in root.xpath("//table") if not t.xpath(".//table")]
        if not leaves:
            return
        for t in leaves:
            rows = [tr.xpath("./td | ./th") for tr in t.xpath(".//tr")]
            tabular = (
                "t-rev-begin" not in (t.get("class") or "")
                and rows
                and not t.xpath(".//td/pre | .//td/div | .//td/table")
            )
            if tabular:
                ul = LH.Element("ul")
                for cells in rows:
                    li = SubElement(ul, "li")
                    for i, cell in enumerate(cells):
                        if i:
                            append_text(li, " — ")
                        target = SubElement(li, "strong") if cell.tag == "th" else li
                        append_text(target, cell.text or "")
                        for child in list(cell):
                            target.append(child)
                t.getparent().replace(t, ul)
                continue

            holder = LH.Element("div")
            for cell in t.xpath(".//td | .//th"):
                text = (cell.text or "").strip()
                if text:
                    SubElement(holder, "p").text = text
                for child in list(cell):
                    holder.append(child)
            if not any(squash(child) for child in holder if child.tag != "em"):
                t.drop_tree()
                continue
            if len(holder) > 1 and holder[-1].tag == "em" and holder[-2].tag == "p":
                append_text(holder[-2], " ")
                holder[-2].append(holder[-1])
            if len(holder):
                t.getparent().replace(t, holder)
            else:
                t.drop_tree()


def label_code_blocks(root):
    for pre in root.xpath("//pre"):
        codes = pre.xpath("./code")
        c = codes[0] if codes else pre
        if c.get("class"):
            continue
        previous = pre.getprevious()
        if previous is not None and re.search(r"output", squash(previous), re.I):
            continue
        c.set("class", "cpp")


def host_of(root):
    for cand in root.iter():
        if len(cand.xpath("./h3")) > 0:
            return cand
    return root


def reorder(host):
    kids = list(host)
    groups, cur = [], []
    for k in kids:
        if k.tag == "h3":
            groups.append(cur)
            cur = [k]
        else:
            cur.append(k)
    groups.append(cur)

    head, rest = groups[0], [g for g in groups[1:] if g]
    title = [e for e in head if e.tag == "h1"]
    declarations = [e for e in head if e.get(DECL)]
    prose = [e for e in head if e.tag != "h1" and not e.get(DECL)]

    example, remaining = [], []
    for g in rest:
        into = example if squash(g[0]).lower().startswith("example") else remaining
        into.extend(g)

    for el in kids:
        host.remove(el)
    for el in title + example + declarations + prose + remaining:
        host.append(el)


def prune(md):
    blocks = re.split(r"(?m)^(?=#{2,3} )", md)
    kept = []
    for block in blocks:
        body = re.sub(r"^#{2,3} .*\n?", "", block) if block.startswith("#") else block
        if block.startswith("#") and body.strip() in ("", "TABLE", "[TABLE]"):
            continue
        kept.append(block)
    return "".join(kept)


def tidy(md):
    md = re.sub(r"``` +(\w+)", r"```\1", md)
    md = re.sub(r"\^\(\\\[\d+\\\]\)", "", md)
    md = re.sub(r"[ \t]+$", "", md, flags=re.M)
    md = re.sub(r"\n{3,}", "\n\n", md)
    return prune(md).strip() + "\n"


def convert(html, columns=86):
    root = LH.fragment_fromstring(html, create_parent="div")
    for el in root.xpath(CHROME):
        if el.getparent() is not None:
            el.drop_tree()
    wrap_highlighted(root)
    rewrite_declarations(root)
    rewrite_tables(root)
    italicize_marks(root)
    flatten_tables(root)
    label_code_blocks(root)
    for a in root.xpath("//a"):
        a.drop_tag()
    reorder(host_of(root))
    for pre in root.xpath("//pre[@" + DECL + "]"):
        pre.attrib.pop(DECL)

    res = subprocess.run(
        ["pandoc", "-f", "html", "-t", "gfm-raw_html", "--wrap=auto", "--columns=" + str(columns)],
        input=LH.tostring(root, encoding="unicode"),
        capture_output=True,
        text=True,
    )
    if res.returncode:
        raise RuntimeError(res.stderr.strip() or "pandoc failed")
    return tidy(res.stdout)


if __name__ == "__main__":
    sys.stdout.write(convert(open(sys.argv[1]).read(), int(sys.argv[2]) if len(sys.argv) > 2 else 86))
