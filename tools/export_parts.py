"""Export the firm kit as Roblox Part data (run inside Blender, after editing firm_pieces.py):
    exec(open("/Users/ryanchen/HatchLawyers/tools/export_parts.py").read())

The game builds the firm from plain Plastic Parts (ServerStorage.Templates.FirmKitParts) so it matches the rest of
the map, which is all Plastic Parts. This records every box firm_pieces.py would put in a mesh and writes, per piece,
tools/firm_parts_<Piece>.txt: rows "x,y,z,sx,sy,sz,colorIndex;" in Roblox space (X = -Blender x, Y = Blender z,
Z = Blender y; pivot = the piece's origin), plus tools/firm_parts_palette.txt ("r,g,b;..." in index order).
Printed patterns become Parts: book spines -> 4 colored bands, caution stripes -> 2-stud yellow/black blocks.
Load them in Studio with ServerStorage.Templates.FirmKitParts.Build(name, rows) (see SESSION_LOG).
"""
import importlib
import os
import sys

TOOLS = "/Users/ryanchen/HatchLawyers/tools"
sys.path.insert(0, TOOLS)
import firm_kit  # noqa: E402
import firm_pieces  # noqa: E402

importlib.reload(firm_kit)
importlib.reload(firm_pieces)

BOOKS = [(150, 30, 30), (28, 44, 110), (30, 110, 50), (230, 200, 130)]


def record_pieces():
    """{piece name: [(min, max, rgb, pattern)]} without building any mesh."""
    orig_init, orig_box = firm_kit.Piece.__init__, firm_kit.Piece.box

    def init(self, name):
        self.name, self._rec = name, []

    def box(self, mn, mx, color, bevel=0.06, tile=None, bottom=True):
        _, rgb, pattern = firm_kit.SW[color][0], firm_kit.SW[color][1], firm_kit.SW[color][2]
        self._rec.append((tuple(mn), tuple(mx), tuple(rgb), pattern))

    firm_kit.Piece.__init__, firm_kit.Piece.box = init, box
    try:
        return {p.name: p._rec for p in (fn() for fn in firm_pieces.PIECES)}
    finally:
        firm_kit.Piece.__init__, firm_kit.Piece.box = orig_init, orig_box


def export():
    palette, out = [], {}

    def ci(rgb):
        if rgb not in palette:
            palette.append(rgb)
        return palette.index(rgb) + 1

    for name, boxes in record_pieces().items():
        rows = []

        def emit(mn, mx, rgb):
            c = [(a + b) / 2 for a, b in zip(mn, mx)]
            s = [b - a for a, b in zip(mn, mx)]
            if min(s) > 0.001:
                rows.append("%g,%g,%g,%g,%g,%g,%d" % (round(-c[0], 3), round(c[2], 3), round(c[1], 3),
                                                      round(s[0], 3), round(s[2], 3), round(s[1], 3), ci(rgb)))

        for mn, mx, rgb, pattern in boxes:
            if pattern in ("books", "caution"):
                ax = 0 if (mx[0] - mn[0]) >= (mx[1] - mn[1]) else 1
                length = mx[ax] - mn[ax]
                n = 4 if pattern == "books" else max(1, round(length / 2.0))
                start = BOOKS.index(rgb) if rgb in BOOKS else 0
                for i in range(n):
                    a, b = list(mn), list(mx)
                    a[ax], b[ax] = mn[ax] + length * i / n, mn[ax] + length * (i + 1) / n
                    color = BOOKS[(start + i) % 4] if pattern == "books" else ((255, 190, 50) if i % 2 == 0 else (30, 30, 34))
                    emit(a, b, color)
            else:
                emit(mn, mx, rgb)
        out[name] = rows
        with open(os.path.join(TOOLS, f"firm_parts_{name}.txt"), "w") as f:
            f.write(";".join(rows))
    with open(os.path.join(TOOLS, "firm_parts_palette.txt"), "w") as f:
        f.write(";".join("%d,%d,%d" % c for c in palette))
    return {k: len(v) for k, v in out.items()}, len(palette)


print(export())
