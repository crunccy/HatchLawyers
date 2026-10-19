# environment-redesign/central_hub/showcase.py - render ONE hub piece alone on a studded ground plate, from the front
# and a 3/4 angle, to review its detail before it goes into the hub.
#   Blender -b --python environment-redesign/central_hub/showcase.py -- <piece> [<piece> ...]
# pieces: statue_fountain, license_building, travel_portal, ... (functions in hub_parts.py)
# Writes environment-redesign/central_hub/renders/showcase/<piece>_front.jpg / _34.jpg
import bpy, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "kit"))
import hl_kit as K
import hub_parts as P

SIZES = {"statue_fountain": 48, "license_building": 80, "travel_portal": 72, "spawn_pad": 20, "egg_incubator": 62,
         "shop": 52, "upgrades": 52, "mutation_machine": 50, "bigcase_terrace": 84, "leaderboard_row": 40,
         "firm_main_street": 110, "firm_glass_office": 120, "firm_supreme_tower": 150}
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["statue_fountain"]
out = os.path.join(HERE, "renders", "showcase")
os.makedirs(out, exist_ok=True)
for piece in argv:
    scene = K.reset(["Showcase", "Lighting", "Presentation"])
    C = K.COLS["Showcase"]
    size = SIZES.get(piece, 60)
    m = K.Mesh(piece, C)
    m.brick(0, 0, -1, size * 1.6, size * 1.6, 1, "grass")
    getattr(P, piece)(K.Frame(m, 0, 0, 0))
    m.done()
    K.studs_done(C)
    world, sun = K.sky_and_sun(scene)
    K.COLS["Lighting"].objects.link(sun)
    K.setup_eevee(scene, samples=32)
    d = size * 0.95
    cam = K.camera("Front", (0, -d * 1.25, d * 0.42), (0, 0, size * 0.18), lens=40, collection=K.COLS["Presentation"])
    K.render(scene, cam, os.path.join(out, piece + "_front.jpg"), 1600, 1000)
    cam2 = K.camera("ThreeQuarter", (d * 0.95, -d * 0.95, d * 0.62), (0, 0, size * 0.16), lens=38, collection=K.COLS["Presentation"])
    K.render(scene, cam2, os.path.join(out, piece + "_34.jpg"), 1600, 1000)
