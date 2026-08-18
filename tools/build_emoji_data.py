#!/usr/bin/env python3
"""Generate the emoji palette data bundled into the keyboard extension.

Input is Unicode's emoji-test.txt (UTS #51), which lists every RGI emoji in CLDR
order -- the order the file itself recommends for keyboard palettes.

Skin tones are collapsed: an emoji that differs from another only by a skin-tone
modifier becomes a variant of it rather than its own palette entry, so the grid
shows one swatch per emoji and the tones live behind a long press.

Usage:
    python3 tools/build_emoji_data.py \
        --input /tmp/emoji-test.txt \
        --output ArmenianKeyboardExtension/emoji.json
"""

import argparse
import json
import re
from collections import OrderedDict

# Skin-tone modifiers (Fitzpatrick), U+1F3FB..U+1F3FF.
SKIN_TONES = [0x1F3FB, 0x1F3FC, 0x1F3FD, 0x1F3FE, 0x1F3FF]

# Variation selector-16. The untoned form of an emoji often carries it to force
# emoji presentation (U+1F590 U+FE0F) while the toned form drops it, since the
# modifier already implies emoji presentation (U+1F590 U+1F3FB). Ignoring it when
# matching a toned form back to its base keeps the two halves together.
VS16 = 0xFE0F

# Apple groups the Unicode categories slightly differently and orders Activities
# before Travel & Places. Key is the Unicode group, value is (display id, name,
# SF Symbol, sort order).
GROUP_MAP = {
    "Smileys & Emotion": ("smileys", "Smileys & People", "face.smiling", 0),
    "People & Body":     ("smileys", "Smileys & People", "face.smiling", 0),
    "Animals & Nature":  ("nature", "Animals & Nature", "leaf", 1),
    "Food & Drink":      ("food", "Food & Drink", "fork.knife", 2),
    "Activities":        ("activity", "Activity", "basketball", 3),
    "Travel & Places":   ("travel", "Travel & Places", "car", 4),
    "Objects":           ("objects", "Objects", "lightbulb", 5),
    "Symbols":           ("symbols", "Symbols", "heart", 6),
    "Flags":             ("flags", "Flags", "flag", 7),
    # "Component" (bare skin tones and hair components) is intentionally dropped:
    # those are modifiers, not standalone palette entries.
}

LINE_RE = re.compile(r"^([0-9A-Fa-f ]+);\s*(\S+)\s*#\s*(\S+)\s+E[\d.]+\s+(.+)$")


def parse(path):
    """Yield (group, codepoints, emoji, name) for fully-qualified entries."""
    group = None
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            line = line.rstrip("\n")
            if line.startswith("# group:"):
                group = line.split(":", 1)[1].strip()
                continue
            if not line or line.startswith("#"):
                continue

            match = LINE_RE.match(line)
            if not match:
                continue
            codes, status, emoji, name = match.groups()
            if status != "fully-qualified":
                continue
            if group not in GROUP_MAP:
                continue

            cps = tuple(int(c, 16) for c in codes.split())
            yield group, cps, emoji, name


def tone_signature(cps):
    """Return (base key, set of tones used) for a sequence.

    The base key strips both skin tones and VS16 so that a toned sequence and its
    untoned counterpart hash to the same value.
    """
    base = tuple(c for c in cps if c not in SKIN_TONES and c != VS16)
    tones = {c for c in cps if c in SKIN_TONES}
    return base, tones


def build(path):
    # base codepoints -> entry. Insertion order follows the file, i.e. CLDR order.
    entries = OrderedDict()
    skipped_mixed = 0

    for group, cps, emoji, name in parse(path):
        base, tones = tone_signature(cps)

        if not tones:
            entries.setdefault(base, {
                "group": group,
                "emoji": emoji,
                "name": name,
                "variants": {},
            })
            continue

        # Sequences combining two different skin tones (couples, handshakes) need
        # a two-axis picker Apple builds but we do not; keep only uniform tones.
        if len(tones) > 1:
            skipped_mixed += 1
            continue

        parent = entries.get(base)
        if parent is None:
            # Toned form appeared before its untoned base; nothing to attach to.
            skipped_mixed += 1
            continue
        parent["variants"][next(iter(tones))] = emoji

    # Group into display categories, preserving CLDR order within each.
    categories = OrderedDict()
    for entry in entries.values():
        cat_id, cat_name, symbol, order = GROUP_MAP[entry["group"]]
        cat = categories.setdefault(cat_id, {
            "id": cat_id,
            "name": cat_name,
            "symbol": symbol,
            "_order": order,
            "emoji": [],
        })
        item = {"b": entry["emoji"]}
        if entry["variants"]:
            ordered = [entry["variants"][t] for t in SKIN_TONES if t in entry["variants"]]
            # Only offer the picker when the full five-tone set is present.
            if len(ordered) == len(SKIN_TONES):
                item["v"] = ordered
        cat["emoji"].append(item)

    ordered_cats = sorted(categories.values(), key=lambda c: c["_order"])
    for cat in ordered_cats:
        del cat["_order"]

    return ordered_cats, skipped_mixed


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="path to emoji-test.txt")
    parser.add_argument("--output", required=True, help="path to write emoji.json")
    parser.add_argument("--version", default="", help="Unicode emoji version, for the header")
    args = parser.parse_args()

    categories, skipped = build(args.input)
    payload = {"version": args.version, "categories": categories}

    with open(args.output, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, separators=(",", ":"))
        handle.write("\n")

    total = sum(len(c["emoji"]) for c in categories)
    toned = sum(1 for c in categories for e in c["emoji"] if "v" in e)
    print(f"wrote {args.output}")
    print(f"  categories:      {len(categories)}")
    print(f"  palette entries: {total}")
    print(f"  with skin tones: {toned}")
    print(f"  mixed-tone skipped: {skipped}")
    for c in categories:
        print(f"    {c['id']:9s} {len(c['emoji']):5d}  {c['name']}")


if __name__ == "__main__":
    main()
