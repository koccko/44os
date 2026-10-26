#!/usr/bin/env python3
"""Generate the 44NOVA Aurorae window decoration theme.

Aurorae slices decoration.svg as a 9-patch frame (elements <prefix>-topleft,
-top, -topright, -left, -center, -right, -bottomleft, -bottom, -bottomright).
Every element here is drawn explicitly inside its own cell, so each element's
bounding box is exactly its cell (no clipping tricks Qt SVG might ignore).

Output: config/includes.chroot/usr/share/aurorae/themes/44NOVA/
"""
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "config/includes.chroot/usr/share/aurorae/themes/44NOVA"

# Geometry (px). Padding holds the shadow; it is outside the window.
PAD_L = PAD_R = 18
PAD_T = 12
PAD_B = 24
BORDER = 1
RADIUS = 10
TITLE_EDGE_T = 8
TITLE_EDGE_B = 8
TITLE_H = 18
TITLEBAR = TITLE_EDGE_T + TITLE_H + TITLE_EDGE_B      # 34 px of title bar

# Cell sizes of the 9-patch
L = PAD_L + RADIUS          # 28
R = PAD_R + RADIUS
T = PAD_T + TITLEBAR        # 46
B = PAD_B + BORDER          # 25
MID_W = MID_H = 40

STYLES = {
    "decoration": dict(fill="#111A2B", fill2="#162238", border="#344765", sheen=0.10, shadow=0.55),
    "decoration-inactive": dict(fill="#0D1422", fill2="#101a2c", border="#2A3A55", sheen=0.04, shadow=0.35),
}

CELL = {  # name -> (x, y, w, h) in the sheet
    "topleft": (0, 0, L, T), "top": (L, 0, MID_W, T), "topright": (L + MID_W, 0, R, T),
    "left": (0, T, L, MID_H), "center": (L, T, MID_W, MID_H), "right": (L + MID_W, T, R, MID_H),
    "bottomleft": (0, T + MID_H, L, B), "bottom": (L, T + MID_H, MID_W, B),
    "bottomright": (L + MID_W, T + MID_H, R, B),
}


def shadow_defs(prefix, s):
    a = s["shadow"]
    stops = (f'<stop offset="0" stop-color="#000" stop-opacity="{a:.2f}"/>'
             f'<stop offset="0.45" stop-color="#000" stop-opacity="{a * 0.35:.2f}"/>'
             f'<stop offset="1" stop-color="#000" stop-opacity="0"/>')
    p = prefix
    return f'''
    <linearGradient id="g{p}-sh-t" x1="0" y1="1" x2="0" y2="0">{stops}</linearGradient>
    <linearGradient id="g{p}-sh-b" x1="0" y1="0" x2="0" y2="1">{stops}</linearGradient>
    <linearGradient id="g{p}-sh-l" x1="1" y1="0" x2="0" y2="0">{stops}</linearGradient>
    <linearGradient id="g{p}-sh-r" x1="0" y1="0" x2="1" y2="0">{stops}</linearGradient>
    <radialGradient id="g{p}-sh-c" cx="0" cy="0" r="1">{stops}</radialGradient>
    <linearGradient id="g{p}-title" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{s['fill2']}"/><stop offset="1" stop-color="{s['fill']}"/></linearGradient>'''


def piece(prefix, name, s, oy=0):
    x, y, w, h = CELL[name]
    y += oy
    p = prefix
    inv = '<rect x="{}" y="{}" width="{}" height="{}" fill="#000" fill-opacity="0.004"/>'.format(x, y, w, h)
    parts = [inv]
    # Window edges inside each cell (cell-local helpers)
    wx0 = x + PAD_L if name.endswith("left") else x            # window left edge
    wx1 = x + w - PAD_R if name.endswith("right") else x + w     # window right edge
    if name in ("topleft", "top", "topright"):
        wy0 = y + PAD_T                                          # window top
        # shadow above the window
        parts.append(f'<rect x="{wx0}" y="{y}" width="{wx1 - wx0}" height="{PAD_T}" fill="url(#g{p}-sh-t)"/>')
        if name == "topleft":
            parts.append(f'<rect x="{x}" y="{wy0}" width="{PAD_L}" height="{h - PAD_T}" fill="url(#g{p}-sh-l)"/>')
            parts.append(f'<rect x="{x}" y="{y}" width="{PAD_L}" height="{PAD_T}" fill="url(#g{p}-sh-t)" opacity="0.5"/>')
            body = (f'M{wx0} {y + h} V{wy0 + RADIUS} A{RADIUS} {RADIUS} 0 0 1 {wx0 + RADIUS} {wy0} '
                    f'H{x + w} V{y + h} Z')
            edge = f'M{wx0 + 0.5} {y + h} V{wy0 + RADIUS} A{RADIUS - 0.5} {RADIUS - 0.5} 0 0 1 {wx0 + RADIUS} {wy0 + 0.5} H{x + w}'
            sheen = f'M{wx0 + RADIUS} {wy0 + 1.5} H{x + w}'
        elif name == "topright":
            parts.append(f'<rect x="{wx1}" y="{wy0}" width="{PAD_R}" height="{h - PAD_T}" fill="url(#g{p}-sh-r)"/>')
            parts.append(f'<rect x="{wx1}" y="{y}" width="{PAD_R}" height="{PAD_T}" fill="url(#g{p}-sh-t)" opacity="0.5"/>')
            body = (f'M{x} {y + h} V{wy0} H{wx1 - RADIUS} A{RADIUS} {RADIUS} 0 0 1 {wx1} {wy0 + RADIUS} '
                    f'V{y + h} Z')
            edge = f'M{x} {wy0 + 0.5} H{wx1 - RADIUS} A{RADIUS - 0.5} {RADIUS - 0.5} 0 0 1 {wx1 - 0.5} {wy0 + RADIUS} V{y + h}'
            sheen = f'M{x} {wy0 + 1.5} H{wx1 - RADIUS}'
        else:
            body = f'M{x} {wy0} H{x + w} V{y + h} H{x} Z'
            edge = f'M{x} {wy0 + 0.5} H{x + w}'
            sheen = f'M{x} {wy0 + 1.5} H{x + w}'
        parts.append(f'<path d="{body}" fill="url(#g{p}-title)"/>')
        parts.append(f'<path d="{edge}" fill="none" stroke="{s["border"]}" stroke-width="1"/>')
        parts.append(f'<path d="{sheen}" fill="none" stroke="#FFFFFF" stroke-opacity="{s["sheen"]}" stroke-width="1"/>')
    elif name in ("left", "center", "right"):
        if name == "left":
            parts.append(f'<rect x="{x}" y="{y}" width="{PAD_L}" height="{h}" fill="url(#g{p}-sh-l)"/>')
            parts.append(f'<rect x="{wx0}" y="{y}" width="{x + w - wx0}" height="{h}" fill="{s["fill"]}"/>')
            parts.append(f'<path d="M{wx0 + 0.5} {y} V{y + h}" stroke="{s["border"]}" stroke-width="1"/>')
        elif name == "right":
            parts.append(f'<rect x="{wx1}" y="{y}" width="{PAD_R}" height="{h}" fill="url(#g{p}-sh-r)"/>')
            parts.append(f'<rect x="{x}" y="{y}" width="{wx1 - x}" height="{h}" fill="{s["fill"]}"/>')
            parts.append(f'<path d="M{wx1 - 0.5} {y} V{y + h}" stroke="{s["border"]}" stroke-width="1"/>')
        else:
            parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{s["fill"]}"/>')
    else:  # bottom row: 1 px border then shadow below
        wy1 = y + BORDER
        if name == "bottomleft":
            parts.append(f'<rect x="{x}" y="{y}" width="{PAD_L}" height="{BORDER}" fill="url(#g{p}-sh-l)"/>')
            parts.append(f'<rect x="{wx0}" y="{y}" width="{x + w - wx0}" height="{BORDER}" fill="{s["border"]}"/>')
            parts.append(f'<rect x="{x}" y="{wy1}" width="{PAD_L}" height="{PAD_B}" fill="url(#g{p}-sh-b)" opacity="0.5"/>')
            parts.append(f'<rect x="{wx0}" y="{wy1}" width="{x + w - wx0}" height="{PAD_B}" fill="url(#g{p}-sh-b)"/>')
        elif name == "bottomright":
            parts.append(f'<rect x="{wx1}" y="{y}" width="{PAD_R}" height="{BORDER}" fill="url(#g{p}-sh-r)"/>')
            parts.append(f'<rect x="{x}" y="{y}" width="{wx1 - x}" height="{BORDER}" fill="{s["border"]}"/>')
            parts.append(f'<rect x="{wx1}" y="{wy1}" width="{PAD_R}" height="{PAD_B}" fill="url(#g{p}-sh-b)" opacity="0.5"/>')
            parts.append(f'<rect x="{x}" y="{wy1}" width="{wx1 - x}" height="{PAD_B}" fill="url(#g{p}-sh-b)"/>')
        else:
            parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{BORDER}" fill="{s["border"]}"/>')
            parts.append(f'<rect x="{x}" y="{wy1}" width="{w}" height="{PAD_B}" fill="url(#g{p}-sh-b)"/>')
    return f'  <g id="{prefix}-{name}">\n    ' + "\n    ".join(parts) + "\n  </g>"


def maximized_piece(prefix, name, s):
    # Maximized windows: flat title bar, no shadow, no rounding, no borders.
    size = {"topleft": (1, TITLEBAR), "top": (MID_W, TITLEBAR), "topright": (1, TITLEBAR),
            "left": (1, MID_H), "center": (MID_W, MID_H), "right": (1, MID_H),
            "bottomleft": (1, 1), "bottom": (MID_W, 1), "bottomright": (1, 1)}[name]
    ox = 200 + {"topleft": 0, "top": 1, "topright": 1 + MID_W, "left": 0, "center": 1,
                "right": 1 + MID_W, "bottomleft": 0, "bottom": 1, "bottomright": 1 + MID_W}[name]
    oy = (0 if name in ("topleft", "top", "topright") else
          TITLEBAR if name in ("left", "center", "right") else TITLEBAR + MID_H)
    if prefix.endswith("inactive"):
        oy += 200
    fill = f"url(#g{'decoration-inactive' if 'inactive' in prefix else 'decoration'}-title)" \
        if name in ("topleft", "top", "topright") else s["fill"]
    return (f'  <g id="{prefix}-{name}"><rect x="{ox}" y="{oy}" width="{size[0]}" height="{size[1]}" '
            f'fill="{fill}"/></g>')


def decoration_svg():
    defs, body = [], []
    for prefix, s in STYLES.items():
        defs.append(shadow_defs(prefix, s))
    sheet_h = T + MID_H + B + 20
    for i, (prefix, s) in enumerate(STYLES.items()):
        body.append("\n".join(piece(prefix, n, s, oy=i * sheet_h) for n in CELL))
    for prefix, s in (("decoration-maximized", STYLES["decoration"]),
                      ("decoration-maximized-inactive", STYLES["decoration-inactive"])):
        body.append("\n".join(maximized_piece(prefix, n, s) for n in CELL))
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" viewBox="0 0 300 300">\n'
            "<!-- 44NOVA Aurorae decoration (generated by branding/aurorae.py). -->\n"
            "<defs>" + "".join(defs) + "\n</defs>\n" + "\n".join(body) + "\n</svg>\n")


BUTTONS = {
    # glyph coordinates: x uses {a}/{b}/{mx} (offset per state), y uses {a_y}/{b_y}/{m}
    "close": ("#FF6B7A", '<path d="M{a} 5.2 L{b} 10.8 M{b} 5.2 L{a} 10.8"/>'),
    "minimize": ("#FFBE70", '<path d="M{a} {m} H{b}"/>'),
    "maximize": ("#49D9AD", '<path d="M{mx} 5.2 V10.8 M{a} {m} H{b}"/>'),
    "restore": ("#49D9AD", '<path d="M{a} 10.2 L{a} 5.8 L{b} 5.8 M{b} 5.8 L{b} 10.2 L{a} 10.2" stroke-width="1.3"/>'),
}


def button_svg(kind):
    color, glyph = BUTTONS[kind]
    size = 16
    c = size / 2
    a, b, m = 5.2, size - 5.2, c

    def state(prefix, ox, fill, ring, glyph_opacity, glow=0.0):
        g = glyph.format(a=f"{a + ox:.1f}", b=f"{b + ox:.1f}", m=f"{m:.1f}", mx=f"{m + ox:.1f}")
        halo = (f'<circle cx="{c + ox}" cy="{c}" r="{c}" fill="{fill}" opacity="{glow}"/>' if glow else "")
        return (f'  <g id="{prefix}-center">\n'
                f'    <rect x="{ox}" y="0" width="{size}" height="{size}" fill="#000" fill-opacity="0.004"/>\n'
                f'    {halo}\n'
                f'    <circle cx="{c + ox}" cy="{c}" r="{c - 2}" fill="{fill}"/>\n'
                f'    <circle cx="{c + ox}" cy="{c}" r="{c - 2.5}" fill="none" stroke="{ring}" stroke-opacity="0.35"/>\n'
                f'    <g fill="none" stroke="#0B1222" stroke-width="1.6" stroke-linecap="round" opacity="{glyph_opacity}">{g}</g>\n'
                f'  </g>')

    grey = "#344765"
    states = [
        ("active", color, "#FFFFFF", 0.0),
        ("hover", color, "#FFFFFF", 1.0),
        ("pressed", color, "#000000", 1.0),
        ("inactive", grey, "#FFFFFF", 0.0),
        ("hover-inactive", color, "#FFFFFF", 1.0),
        ("pressed-inactive", color, "#000000", 1.0),
        ("deactivated", "#22314A", "#FFFFFF", 0.0),
        ("deactivated-inactive", "#22314A", "#FFFFFF", 0.0),
    ]
    out = []
    for i, (prefix, fill, ring, op) in enumerate(states):
        glow = 0.22 if prefix.startswith("hover") else 0.0
        out.append(state(prefix, i * (size + 4), fill, ring, op, glow))
    w = len(states) * (size + 4)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{size}" viewBox="0 0 {w} {size}">\n'
            + "\n".join(out) + "\n</svg>\n")


RC = f"""[General]
ActiveTextColor=241,245,255
InactiveTextColor=167,181,204
UseTextShadow=false
TitleAlignment=Center
TitleVerticalAlignment=Center
Animation=160
HaloActive=false
HaloInactive=false
Shadow=true

[Layout]
BorderLeft={BORDER}
BorderRight={BORDER}
BorderBottom={BORDER}
TitleEdgeTop={TITLE_EDGE_T}
TitleEdgeBottom={TITLE_EDGE_B}
TitleEdgeLeft=12
TitleEdgeRight=12
TitleEdgeTopMaximized={TITLE_EDGE_T}
TitleEdgeBottomMaximized={TITLE_EDGE_B}
TitleEdgeLeftMaximized=12
TitleEdgeRightMaximized=12
TitleBorderLeft=12
TitleBorderRight=12
TitleHeight={TITLE_H}
ButtonWidth=16
ButtonHeight=16
ButtonSpacing=8
ButtonMarginTop=1
ButtonMarginTopMaximized=1
ExplicitButtonSpacer=10
PaddingLeft={PAD_L}
PaddingRight={PAD_R}
PaddingTop={PAD_T}
PaddingBottom={PAD_B}
"""

METADATA = """[Desktop Entry]
Name=44NOVA
Comment=44OS NOVA window decoration: glass title bar, rounded corners, orb buttons
X-KDE-PluginInfo-Author=44OS
X-KDE-PluginInfo-Name=44NOVA
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-License=GPL-2.0-or-later
X-KDE-PluginInfo-Website=https://github.com/koccko/44os
"""


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "decoration.svg").write_text(decoration_svg())
    for kind in BUTTONS:
        (OUT / f"{kind}.svg").write_text(button_svg(kind))
    (OUT / "44NOVArc").write_text(RC)
    (OUT / "metadata.desktop").write_text(METADATA)


if __name__ == "__main__":
    main()
