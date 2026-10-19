# environment-redesign/kit/kit_preview.py - a sheet of every kit piece, to review the look (studs, bevels, plastic,
# lighting) before building islands. Run: Blender -b --python environment-redesign/kit/kit_preview.py
# Writes environment-redesign/kit/renders/kit_sheet.jpg (+ a close-up of the studs).
import bpy, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import hl_kit as K

scene = K.reset(["Kit_Preview", "Lighting", "Presentation"])
C = K.COLS["Kit_Preview"]
m = K.Mesh("KitSheet", C)
m.brick(0, 0, -1, 80, 44, 1, "grass")  # studded ground
m.brick(-28, -10, 0, 16, 10, 0.3, "path", studs=True)
for k in range(16):  # dashed white path edge
    m.brick(-35.5 + k, -15.2, 0.3, 0.6, 0.4, 0.15, "path_edge", studs=False, bevel=0.03) if k % 2 == 0 else None
K.tree_round(m, -30, 10, 1.0)
K.tree_pine(m, -18, 12, 1.1)
K.tree_palm(m, -6, 12, 1.0, lean=20)
K.tree_blossom(m, 6, 12, 0.95)
K.bush(m, -14, 2)
K.flowerbed(m, -2, 2, 8, 4)
K.rocks(m, 10, 2, 1.2)
K.lamp(m, 16, 2, 11, double=True)
K.bench(m, 22, 2, rot=0)
K.planter(m, 28, 2, 4, 4)
# a wall with a window, a door, columns, stairs, railing, flag, banner
m.brick(10, -10, 0, 24, 6, 12, "cream", studs=False)
m.brick(10, -10, 12, 25, 7, 1.2, "white")
K.window(m, 4, -13.0, 4, 4, 5, 0, frame="white", shutters="roof_blue")
K.door(m, 12, -13.0, 0.6, 4, 7, 0, frame="white", arch=True)
K.window(m, 19, -13.0, 4, 4, 5, 0, frame="white", mullions=2)
K.stairs(m, 12, -17.5, 0, 6, 3, 0.2, 1.2, 90, look="stone")
for x in (-2, 24):
    K.column(m, x, -14.5, 0, 12, 1.4)
K.railing(m, 24, -18, 34, -18, 0, 2.6)
K.flag(m, 32, -8, 0, 12, "red", rot=0)
K.banner(m, 36, -10, 2, 8, 2.6, "purple", rot=0)
m.roof_gable(10, -10, 13.2, 24, 7, 4.5, "roof_red", trim="white")
m.roof_hip(30, 12, 0, 6, 6, 4, "roof_blue", trim="white", cap="gold")
m.done()
K.studs_done(C)
world, sun = K.sky_and_sun(scene)
K.COLS["Lighting"].objects.link(sun)
K.setup_eevee(scene, samples=32)
os.makedirs(os.path.join(HERE, "renders"), exist_ok=True)
cam = K.camera("Cam_Sheet", (6, -62, 30), (4, 0, 4), lens=40, collection=K.COLS["Presentation"])
K.render(scene, cam, os.path.join(HERE, "renders", "kit_sheet.jpg"), 1800, 1000)
cam2 = K.camera("Cam_Studs", (-25, -22, 4.5), (-29, -12, 0), lens=50, collection=K.COLS["Presentation"])
K.render(scene, cam2, os.path.join(HERE, "renders", "kit_studs_closeup.jpg"), 1400, 800)
