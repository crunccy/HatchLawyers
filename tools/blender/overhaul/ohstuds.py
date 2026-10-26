# tools/blender/overhaul/ohstuds.py - the ONE stud shape for the model overhaul: the game's standard stud
# (tools/blender/stud_tiles.py / hl_kit.stud_mesh: a soft rounded-square top 0.46 wide on a 0.60 foot, 0.10 tall, sunk
# 0.05). crnuch 2026-10-24: "i dont want the studs to be protruding so much on anything" - the first benchmark used fat
# 0.64 x 0.2 cylinders; every model now uses this (one stud scale everywhere, docs/ART_STYLE_STUDS.md).
import math
from mathutils import Vector
import hl_kit as K

ENABLED = False            # (crnuch 2026-10-26: Grow a Garden studs are a surface pattern now - gagstuds.py)
HEIGHT = K.STUD_H          # 0.10
SINK = K.STUD_SINK         # 0.05


def add_stud(bm, centre, up=Vector((0, 0, 1)), segs=3):
    """One standard stud on a flat face at `centre` (Blender coords), pointing `up` (default +Z). Off while ENABLED is False."""
    if not ENABLED:
        return
    top = K._outline(K.STUD_TOP_HALF, K.STUD_TOP_R, segs)
    foot = K._outline(K.STUD_TOP_HALF + K.STUD_SLANT, K.STUD_TOP_R + K.STUD_SLANT, segs)
    c = Vector(centre)
    ax = Vector((1, 0, 0)) if abs(up.x) < 0.9 else Vector((0, 1, 0))
    a1 = (ax - up * ax.dot(up)).normalized()
    a2 = up.cross(a1)
    fv = [bm.verts.new(c + a1 * x + a2 * y - up * SINK) for x, y, _, _ in foot]
    tv = [bm.verts.new(c + a1 * x + a2 * y + up * HEIGHT) for x, y, _, _ in top]
    mid = bm.verts.new(c + up * HEIGHT)
    k = len(tv)
    for i in range(k):
        j = (i + 1) % k
        bm.faces.new((fv[i], fv[j], tv[j], tv[i]))
        bm.faces.new((tv[i], tv[j], mid))
