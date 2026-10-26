# tools/blender/overhaul/gagstuds.py - THE STUDS (crnuch + partner 2026-10-26, option B of the Grow a Garden examples):
# Grow a Garden-style studs on EVERY face of every solid surface, as a surface pattern - not raised geometry. A half-stud
# grid of small rounded-square studs (0.36 of a cell across), each with a dark sliver on its lower-right side, a lit one
# on its upper-left and a faint outline; world-aligned on each face's main axis; faded out on strongly curved faces (a
# bush, a ball: no flat face for a stud). Water, glow, glass and see-through materials stay smooth.
#   apply_all()      every material in the scene gets the studs (idempotent; ohkit.render + the island renders call it)
#   no_raised()      the old raised studs off: hl_kit.studs_done (the v2 islands' stud pass) + ohstuds (modelled studs)
#   bake_maps(out)   the same pattern as Roblox MaterialVariant maps (a 1-stud tile = 2 x 2 studs): colour (white, tinted
#                    by each part's Color in the game), normal (OpenGL, +Y up), roughness - docs/ART_STYLE_STUDS.md
#   Blender -b --factory-startup --python tools/blender/overhaul/gagstuds.py -- <out dir>   (bakes the maps)
import bpy, math, os, sys

PITCH = 0.5               # studs between stud centres (option B: the half-stud grid)
HALF = 0.18               # a stud's half-width, in cells (0.36 of a cell across)
R = HALF * 0.36           # its corner radius
LINE = 0.03               # the faint outline's half-width, cells
OFF = 0.05                # how far the shadow / lit sliver reaches past the stud's edge, cells
SKIP = ("glow", "glass", "water", "foam", "pool", "sky", "cloud", "beam", "vortex", "goo", "soda", "fall", "plasma", "pond",
        "neon", "lamp_glow", "screen")  # (looks that stay smooth; not "light": oak_light / stone_light are studded - lights glow)


def stud_nodes(nt, base_socket, base_value):
    """The stud pattern in a material's node tree: returns (colour socket, normal socket) for its Principled BSDF."""
    N, L = nt.nodes, nt.links
    geo = N.new("ShaderNodeNewGeometry")
    sp, sn = N.new("ShaderNodeSeparateXYZ"), N.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Position"], sp.inputs[0])
    L.new(geo.outputs["Normal"], sn.inputs[0])

    def m(op, a, b=None):
        n = N.new("ShaderNodeMath")
        n.operation = op
        for i, s in enumerate((a, b)):
            if s is None:
                continue
            if isinstance(s, (int, float)):
                n.inputs[i].default_value = s
            else:
                L.new(s, n.inputs[i])
        return n.outputs[0]

    def ramp(src, a, b, lo=1.0, hi=0.0):
        r = N.new("ShaderNodeMapRange")
        r.interpolation_type = "SMOOTHSTEP"
        L.new(src, r.inputs["Value"])
        r.inputs["From Min"].default_value, r.inputs["From Max"].default_value = a, b
        r.inputs["To Min"].default_value, r.inputs["To Max"].default_value = lo, hi
        return r.outputs["Result"]
    ax, ay, az = (m("ABSOLUTE", sn.outputs[i]) for i in range(3))
    wz = m("MULTIPLY", m("GREATER_THAN", az, m("SUBTRACT", ax, 1e-4)), m("GREATER_THAN", az, m("SUBTRACT", ay, 1e-4)))
    wx = m("MULTIPLY", m("SUBTRACT", 1.0, wz), m("GREATER_THAN", ax, ay))
    wy = m("SUBTRACT", m("SUBTRACT", 1.0, wz), wx)
    X, Y, Z = sp.outputs[0], sp.outputs[1], sp.outputs[2]
    u = m("ADD", m("ADD", m("MULTIPLY", wz, X), m("MULTIPLY", wx, Y)), m("MULTIPLY", wy, X))
    v = m("ADD", m("ADD", m("MULTIPLY", wz, Y), m("MULTIPLY", wx, Z)), m("MULTIPLY", wy, Z))
    fu, fv = m("SUBTRACT", m("FRACT", m("DIVIDE", u, PITCH)), 0.5), m("SUBTRACT", m("FRACT", m("DIVIDE", v, PITCH)), 0.5)

    def rsq(du, dv):  # (the rounded square's signed distance, shifted by (du, dv) cells)
        qx = m("SUBTRACT", m("ABSOLUTE", m("SUBTRACT", fu, du)), HALF - R)
        qy = m("SUBTRACT", m("ABSOLUTE", m("SUBTRACT", fv, dv)), HALF - R)
        out = m("SQRT", m("ADD", m("POWER", m("MAXIMUM", qx, 0.0), 2.0), m("POWER", m("MAXIMUM", qy, 0.0), 2.0)))
        return m("SUBTRACT", m("ADD", out, m("MINIMUM", m("MAXIMUM", qx, qy), 0.0)), R)
    sdf = rsq(0.0, 0.0)
    ins = ramp(sdf, -0.012, 0.012)
    shadow = m("MULTIPLY", ramp(rsq(OFF, -OFF), -0.012, 0.012), m("SUBTRACT", 1.0, ins))  # (lower-right: the shadow side)
    shine = m("MULTIPLY", ramp(rsq(-OFF, OFF), -0.012, 0.012), m("SUBTRACT", 1.0, ins))   # (upper-left: the lit side)
    fade = ramp(m("MAXIMUM", m("MAXIMUM", ax, ay), az), 0.72, 0.86, 0.0, 1.0)            # (gone on strongly curved faces)
    outline = m("MULTIPLY", ramp(m("ABSOLUTE", sdf), 0.0, LINE), fade)
    bump = N.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value, bump.inputs["Distance"].default_value = 0.5, 0.035 * PITCH
    L.new(m("MULTIPLY", ramp(sdf, -0.03, 0.02), fade), bump.inputs["Height"])
    if base_socket is None:
        rgb = N.new("ShaderNodeRGB")
        rgb.outputs[0].default_value = base_value
        base_socket = rgb.outputs[0]
    dark = N.new("ShaderNodeMix")
    dark.data_type, dark.blend_type = "RGBA", "MULTIPLY"
    dark.inputs[0].default_value = 1.0
    L.new(base_socket, dark.inputs[6])
    dark.inputs[7].default_value = (0.5, 0.5, 0.5, 1.0)
    mix = N.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    L.new(m("MULTIPLY", m("ADD", m("MULTIPLY", shadow, 0.95), m("MULTIPLY", outline, 0.15)), fade), mix.inputs[0])
    L.new(base_socket, mix.inputs[6])
    L.new(dark.outputs[2], mix.inputs[7])
    lit = N.new("ShaderNodeMix")
    lit.data_type, lit.blend_type = "RGBA", "SCREEN"
    L.new(m("MULTIPLY", m("MULTIPLY", shine, fade), 0.32), lit.inputs[0])
    L.new(mix.outputs[2], lit.inputs[6])
    lit.inputs[7].default_value = (1.0, 1.0, 1.0, 1.0)
    return lit.outputs[2], bump.outputs[0]


def apply(mat):
    """Studs on one material (False if it stays smooth or has them already)."""
    if mat.get("gag_studs") or not mat.use_nodes or any(k in mat.name.lower() for k in SKIP):
        return False
    nt = mat.node_tree
    bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if bsdf is None or bsdf.inputs["Alpha"].default_value < 0.99 or bsdf.inputs["Transmission Weight"].default_value > 0.01 \
            or bsdf.inputs["Emission Strength"].default_value > 0.01:
        return False
    bc = bsdf.inputs["Base Color"]
    col, nrm = stud_nodes(nt, bc.links[0].from_socket if bc.is_linked else None, tuple(bc.default_value))
    nt.links.new(col, bc)
    nt.links.new(nrm, bsdf.inputs["Normal"])
    mat["gag_studs"] = 1
    return True


def apply_all():
    """Every material in the file gets the studs; any raised-stud object left over is hidden. Returns how many."""
    n = sum(apply(mat) for mat in bpy.data.materials)
    for ob in bpy.data.objects:
        if ob.name.startswith(("Studs_", "StudSource_")):
            ob.hide_render = True
    return n


def no_raised():
    """The old raised studs off (they'd double up with the pattern): the v2 islands' stud pass + the modelled studs."""
    import hl_kit as K
    import ohstuds
    K.studs_done = lambda *a, **k: None
    ohstuds.ENABLED = False


# ------------------------------------------------------------------ the Roblox maps
def _pattern(px):
    """The pattern over a 1-stud tile (px x px): (colour value, height) arrays - the shader's maths, per pixel."""
    import numpy as np
    t = (np.arange(px) + 0.5) / px                      # stud units across the tile
    U, V = np.meshgrid(t, 1.0 - t)                      # (V up: image row 0 is the top)
    fu, fv = np.mod(U / PITCH, 1.0) - 0.5, np.mod(V / PITCH, 1.0) - 0.5

    def rsq(du, dv):
        qx, qy = np.abs(fu - du) - (HALF - R), np.abs(fv - dv) - (HALF - R)
        return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - R

    def ss(x, a, b):  # (smoothstep falling 1 -> 0 from a to b)
        k = np.clip((x - a) / (b - a), 0, 1)
        return 1 - k * k * (3 - 2 * k)
    sdf = rsq(0, 0)
    ins = ss(sdf, -0.012, 0.012)
    shadow = ss(rsq(OFF, -OFF), -0.012, 0.012) * (1 - ins)
    outline = ss(np.abs(sdf), 0.0, LINE)
    colour = 1.0 - 0.5 * (shadow * 0.95 + outline * 0.15)  # (white, darker where the shadow falls: the part's Color tints it)
    height = ss(sdf, -0.03, 0.02)
    return colour, height


def _save(arr, path):
    import numpy as np
    h, w = arr.shape[:2]
    img = bpy.data.images.new(os.path.basename(path), w, h, alpha=False)
    img.colorspace_settings.name = "Non-Color" if "Normal" in path or "Rough" in path else "sRGB"  # (before the pixels: it resets them)
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[..., :3] = arr if arr.ndim == 3 else arr[..., None]
    img.pixels.foreach_set(rgba[::-1].ravel())  # (Blender's rows go bottom-up)
    img.update()
    img.filepath_raw, img.file_format = path, "PNG"
    img.save()


def bake_maps(out, px=512):
    """GaGStuds_Color / _Normal / _Roughness.png for a Roblox MaterialVariant (StudsPerTile 1: a tile = 1 stud = 2 x 2 studs)."""
    import numpy as np
    os.makedirs(out, exist_ok=True)
    colour, height = _pattern(px)
    step = 1.0 / px
    dz = 0.035 * PITCH                                   # (the bump's height, studs - as in the shader)
    gy, gx = np.gradient(height * dz, step)              # (gy: down the image rows = -V)
    n = np.dstack((-gx, gy, np.ones_like(gx)))           # (OpenGL: +Y up)
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    n = n * 0.5 + np.array([0.0, 0.0, 0.5])              # (the shader's Strength 0.5: halfway to flat)
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    _save(np.dstack([colour] * 3), os.path.join(out, "GaGStuds_Color.png"))
    _save(n * 0.5 + 0.5, os.path.join(out, "GaGStuds_Normal.png"))
    _save(np.full((px, px), 0.78, dtype=np.float32), os.path.join(out, "GaGStuds_Roughness.png"))
    print("[gagstuds] maps in", out)


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    bake_maps(argv[0] if argv else os.path.join(os.path.dirname(os.path.abspath(__file__)), "renders", "gagstuds"))
