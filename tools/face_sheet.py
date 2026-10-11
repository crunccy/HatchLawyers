"""Contact sheet of art/client_faces/*.png, each on its own skin colour (Blender -b --python)."""
import bpy, numpy as np, os, sys
sys.path.insert(0, "/Users/ryanchen/HatchLawyers/tools")
ROOT = "/Users/ryanchen/HatchLawyers/art/client_faces"
import importlib.util
spec = importlib.util.spec_from_file_location("cf", "/Users/ryanchen/HatchLawyers/tools/client_faces.py")
names = sorted(f[:-4] for f in os.listdir(ROOT) if f.endswith(".png") and not f.startswith("_"))
src = open("/Users/ryanchen/HatchLawyers/tools/client_faces.py").read()
ns = {}
exec(src.split("FACES = {")[0].split("def hexc")[0], ns)  # constants only
skins = {}
import re
for n in names:
    m = re.search(r'"%s": \{\s*"skin": (S\d|"[0-9a-f]+")' % n, src)
    tok = m.group(1) if m else '"f1c49a"'
    S = {"S1": "f6d2b0", "S2": "f1c49a", "S3": "e0a87a", "S4": "c98b5f", "S5": "a86a42", "S6": "7a4a2c"}
    skins[n] = S.get(tok, tok.strip('"'))
cols, cw, ch = 8, 156, 144
rows = (len(names) + cols - 1) // cols
sheet = np.ones((rows * ch, cols * cw, 4), np.float32)
for i, n in enumerate(names):
    img = bpy.data.images.load(os.path.join(ROOT, n + ".png"))
    w, h = img.size
    px = np.array(img.pixels[:], np.float32).reshape(h, w, 4)
    px = px[::max(1, h // ch), ::max(1, w // cw)][:ch, :cw]
    hx = skins[n]
    bg = np.array([int(hx[k:k + 2], 16) / 255 for k in (0, 2, 4)] + [1.0], np.float32)
    a = px[..., 3:4]
    tile = px * a + bg * (1 - a)
    tile[..., 3] = 1
    r, c = rows - 1 - i // cols, i % cols
    th, tw = tile.shape[:2]
    sheet[r * ch:r * ch + th, c * cw:c * cw + tw] = tile
out = bpy.data.images.new("sheet", cols * cw, rows * ch, alpha=True)
out.pixels.foreach_set(sheet.ravel())
out.filepath_raw = os.path.join(ROOT, "_sheet.png")
out.file_format = "PNG"
out.save()
print("SHEET", len(names))
