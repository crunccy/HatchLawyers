# tools/blender/encode_preview.py - turns the PNG frames boss_anims.py renders ("-- frames") into MP4 previews with the
# server's phases labelled and a timer burned in (Blender's sequencer + its own FFmpeg; no ffmpeg install needed).
# Mac: /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup -P tools/blender/encode_preview.py -- \
#        <frames dir> <out.mp4> [speed=1.0] [title] [boss=Megalodon]
# Phases (seconds into the preview, from each boss's timeline in tools/blender/boss_clips/<boss>.py) are labelled.
import bpy, os, sys, glob

args = sys.argv[sys.argv.index("--") + 1:]
src, out = args[0], args[1]
speed = float(args[2]) if len(args) > 2 else 1.0
title = args[3] if len(args) > 3 else ""
FPS = 30
BOSS = args[4] if len(args) > 4 else "Megalodon"
PHASES = {
    "Megalodon": [(0.0, "walk"), (0.5, "WINDUP  1.0 s  (warning on the floor)"), (1.5, "CHARGE  130 studs @ 150/s = 0.87 s"),
                  (2.367, "DIZZY  2.0 s"), (4.367, "RECOVER  0.6 s"), (4.967, "walk")],
    "SeniorPartner": [(0.0, "walk"), (0.5, "WINDUP  1.2 s  (warning on the floor)"),
                      (1.7, "ATTACK  0.45 s  (the hit: its first frame; the case lands at +0.05)"),
                      (2.15, "RECOVER  0.6 s"), (2.75, "walk")],
    "BigCheese": [(0.0, "walk"), (0.5, "WINDUP  1.2 s  (warning on the floor)"), (1.7, "ROLL  110 studs @ 120/s = 0.92 s"),
                  (2.617, "RECOVER  0.6 s"), (3.217, "walk")],
    "BarristerBulldog": [(0.0, "walk"), (0.5, "WINDUP  1.4 s  (warning on the floor)"),
                         (1.9, "ATTACK  0.45 s  (the bark: its first frame)"), (2.35, "RECOVER  0.6 s"), (2.95, "walk")],
    "JudgeMartello": [(0.0, "walk"), (0.5, "WINDUP = THE HOP  1.1 s  (airborne)"),
                      (1.6, "ATTACK  0.45 s  (the strike: its first frame)"), (2.05, "RECOVER  0.6 s"), (2.65, "walk")],
    "Eclipse": [(0.0, "walk"), (0.5, "PULL WINDUP  1.4 s"), (1.9, "PULL  2.0 s  (drags in everyone within 44)"),
                (3.9, "RECOVER  0.6 s"), (4.5, "walk"), (5.0, "RING WINDUP  1.4 s"),
                (6.4, "RING  0.45 s  (the gavels fling out: its first frame)"), (6.85, "RECOVER  0.6 s"), (7.45, "walk")],
}[BOSS]

files = sorted(glob.glob(os.path.join(src, "f_*.png")))
sc = bpy.data.scenes.new("Encode")
sc.render.fps = max(1, int(round(FPS * speed)))
sc.view_settings.view_transform = "Standard"  # (the frames are already final colours)
sc.render.resolution_x, sc.render.resolution_y = 1280, 720
se = sc.sequence_editor_create()
strips = se.strips if hasattr(se, "strips") else se.sequences
img = strips.new_image("frames", files[0], 1, 1)
for f in files[1:]:
    img.elements.append(os.path.basename(f))
n = len(files)
sc.frame_start, sc.frame_end = 1, n


def text(label, start, end, channel, y, size, color=(1, 1, 1, 1)):
    try:
        t = strips.new_effect(label[:20], "TEXT", channel, frame_start=start, length=max(1, end - start))
    except TypeError:
        t = strips.new_effect(label[:20], "TEXT", channel, frame_start=start, frame_end=end)
    t.text = label
    t.font_size = size
    t.color = color
    t.use_shadow = True
    t.location = (0.03, y)
    t.anchor_x = "LEFT"
    return t


for i, (t0, label) in enumerate(PHASES):
    t1 = PHASES[i + 1][0] if i + 1 < len(PHASES) else n / FPS
    text(label, int(round(t0 * FPS)) + 1, int(round(t1 * FPS)) + 1, 2 + (i % 2), 0.06, 40)
if title:
    text(title, 1, n + 1, 4, 0.92, 34, (1, 0.86, 0.3, 1))
# the timer: preview time, burned in by the stamp (frame / 30 s, whatever the playback speed)
r = sc.render
r.use_stamp = True
for k in ("use_stamp_date", "use_stamp_render_time", "use_stamp_camera", "use_stamp_lens", "use_stamp_scene",
          "use_stamp_filename", "use_stamp_memory", "use_stamp_hostname", "use_stamp_marker", "use_stamp_sequencer_strip"):
    if hasattr(r, k):
        setattr(r, k, False)
r.use_stamp_frame = True
r.use_stamp_time = False
r.use_stamp_note = True
r.stamp_note_text = "30 fps" + ("" if speed == 1 else "  -  played at %gx speed" % speed)
r.stamp_font_size = 22
ims = r.image_settings
if hasattr(ims, "media_type"):
    ims.media_type = "VIDEO"
ims.file_format = "FFMPEG"
r.ffmpeg.format = "MPEG4"
r.ffmpeg.codec = "H264"
r.ffmpeg.constant_rate_factor = "HIGH"
r.filepath = out
with bpy.context.temp_override(scene=sc):
    bpy.ops.render.render(animation=True, scene=sc.name)
print("encoded", n, "frames ->", out)
