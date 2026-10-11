"""Contact sheet of art/shop_icons/*.png on a card-coloured background (run with Blender -b --python)."""
import bpy, numpy as np, os, sys
ROOT = "/Users/ryanchen/HatchLawyers/art/shop_icons"
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
names = argv or sorted(f[:-4] for f in os.listdir(ROOT) if f.endswith(".png") and not f.startswith("_"))
cols, cell = 4, 256
rows = (len(names) + cols - 1) // cols
sheet = np.zeros((rows * cell, cols * cell, 4), np.float32)
bgs = [(0.30, 0.78, 0.18), (0.31, 0.71, 0.93), (0.61, 0.30, 0.94), (1.0, 0.75, 0.12)]
for i, n in enumerate(names):
    img = bpy.data.images.load(os.path.join(ROOT, n + ".png"))
    w, h = img.size
    px = np.array(img.pixels[:], np.float32).reshape(h, w, 4)
    step = w // cell
    px = px[::step, ::step][:cell, :cell]
    r, c = rows - 1 - i // cols, i % cols
    bg = np.array(bgs[i % 4] + (1.0,), np.float32)
    a = px[..., 3:4]
    tile = px * a + bg * (1 - a)
    tile[..., 3] = 1
    sheet[r * cell:(r + 1) * cell, c * cell:(c + 1) * cell] = tile
out = bpy.data.images.new("sheet", cols * cell, rows * cell, alpha=True)
out.pixels.foreach_set(sheet.ravel())
out.filepath_raw = os.path.join(ROOT, "_sheet.png")
out.file_format = "PNG"
out.save()
print("SHEET", names)
