"""Headless Blender renderer for the Meshy FBX squishy models.

Photographs a Meshy-generated FBX (card art -> image-to-3D) with a studio
rig that matches the card-art look: warm key upper-left, soft cool fill,
rim pop, transparent background. Outputs hero stills, turntable frame
sequences, and/or a GLB export for the web viewer.

Run via Blender (NOT plain python):

  & "C:\\Program Files\\Blender Foundation\\Blender 4.3\\blender.exe" -b ^
      --factory-startup -P blender_render_squishy.py -- ^
      --fbx C:\\path\\to\\soft_dumpling.fbx ^
      --out C:\\Users\\chris\\Squishy-smash\\_tmp_3d_renders\\soft_dumpling ^
      --name soft_dumpling --hero 1024,2048 --turntable 60 --res 1080 --glb

Everything after `--` is ours; everything before is Blender's.
"""

import math
import sys
import time

import bpy
from mathutils import Vector


# ---------------------------------------------------------------- args


def parse_args():
    argv = sys.argv
    argv = argv[argv.index("--") + 1 :] if "--" in argv else []
    args = {
        "fbx": None,
        "out": None,
        "name": "squishy",
        "hero": [],          # list of square hero resolutions
        "turntable": 0,      # frame count, 0 = skip
        "res": 1080,         # turntable resolution (square)
        "glb": False,
        "yaw": 0.0,          # proven facing for Meshy FBX + this camera (soft_dumpling proof)
        "samples": 64,
        "elev": 12.0,        # camera elevation degrees
        "squish": 0,         # squish-animation frame count, 0 = skip
        "squishres": 512,
    }
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--fbx":
            args["fbx"] = argv[i + 1]; i += 2
        elif a == "--out":
            args["out"] = argv[i + 1]; i += 2
        elif a == "--name":
            args["name"] = argv[i + 1]; i += 2
        elif a == "--hero":
            args["hero"] = [int(x) for x in argv[i + 1].split(",") if x]; i += 2
        elif a == "--turntable":
            args["turntable"] = int(argv[i + 1]); i += 2
        elif a == "--res":
            args["res"] = int(argv[i + 1]); i += 2
        elif a == "--glb":
            args["glb"] = True; i += 1
        elif a == "--yaw":
            args["yaw"] = float(argv[i + 1]); i += 2
        elif a == "--samples":
            args["samples"] = int(argv[i + 1]); i += 2
        elif a == "--elev":
            args["elev"] = float(argv[i + 1]); i += 2
        elif a == "--squish":
            args["squish"] = int(argv[i + 1]); i += 2
        elif a == "--squishres":
            args["squishres"] = int(argv[i + 1]); i += 2
        else:
            i += 1
    if not args["fbx"] or not args["out"]:
        raise SystemExit("--fbx and --out are required")
    return args


# ---------------------------------------------------------------- scene


def clean_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.lights, bpy.data.cameras):
        for datum in list(block):
            if datum.users == 0:
                block.remove(datum)


def import_fbx(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=path)
    return [o for o in bpy.data.objects if o not in before]


def normalize(objs, yaw_deg):
    """Center the model at the origin and scale max dimension to 2.0."""
    meshes = [o for o in objs if o.type == "MESH"]
    if not meshes:
        raise SystemExit("no mesh objects imported")

    # rig empty: rotation target for the turntable
    rig = bpy.data.objects.new("RIG", None)
    bpy.context.collection.objects.link(rig)

    # parent top-level imported objects to the rig (keep transforms)
    for o in objs:
        if o.parent is None or o.parent not in objs:
            o.parent = rig

    bpy.context.view_layer.update()

    def world_bbox():
        pts = []
        for m in meshes:
            for c in m.bound_box:
                pts.append(m.matrix_world @ Vector(c))
        lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        return lo, hi

    lo, hi = world_bbox()
    center = (lo + hi) / 2
    max_dim = max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z)
    if max_dim <= 0:
        raise SystemExit("degenerate bounding box")

    rig.scale = (2.0 / max_dim,) * 3
    bpy.context.view_layer.update()
    lo, hi = world_bbox()
    center = (lo + hi) / 2
    rig.location = rig.location - center
    rig.rotation_euler = (0.0, 0.0, math.radians(yaw_deg))
    bpy.context.view_layer.update()
    return rig


def studio_rig(elev_deg):
    """Camera + the card-look light rig (warm key upper-left, cool fill, rim)."""
    scene = bpy.context.scene

    cam_data = bpy.data.cameras.new("CAM")
    cam_data.lens = 60  # mild telephoto: gentle perspective like the cards
    cam = bpy.data.objects.new("CAM", cam_data)
    bpy.context.collection.objects.link(cam)
    dist = 4.1
    elev = math.radians(elev_deg)
    cam.location = (0.0, -dist * math.cos(elev), dist * math.sin(elev))
    track = cam.constraints.new("TRACK_TO")
    target = bpy.data.objects.new("AIM", None)
    target.location = (0.0, 0.0, 0.0)
    bpy.context.collection.objects.link(target)
    track.target = target
    track.track_axis = "TRACK_NEGATIVE_Z"
    track.up_axis = "UP_Y"
    scene.camera = cam

    def area(name, loc, rot, energy, color, size):
        data = bpy.data.lights.new(name, "AREA")
        data.energy = energy
        data.color = color
        data.size = size
        obj = bpy.data.objects.new(name, data)
        obj.location = loc
        obj.rotation_euler = rot
        bpy.context.collection.objects.link(obj)
        return obj

    # key: warm, upper-left-front (the FLUX card prompt's "warm rim light from upper-left")
    key = area("KEY", (-3.2, -2.6, 3.4), (0, 0, 0), 640, (1.0, 0.90, 0.80), 5.0)
    key.constraints.new("TRACK_TO").target = target
    key.constraints[-1].track_axis = "TRACK_NEGATIVE_Z"
    key.constraints[-1].up_axis = "UP_Y"
    # fill: soft cool, right-front
    fill = area("FILL", (3.4, -2.8, 1.2), (0, 0, 0), 260, (0.85, 0.90, 1.0), 6.0)
    fill.constraints.new("TRACK_TO").target = target
    fill.constraints[-1].track_axis = "TRACK_NEGATIVE_Z"
    fill.constraints[-1].up_axis = "UP_Y"
    # rim: pink-cool pop from behind-above for the toy-gloss edge
    rim = area("RIM", (0.6, 3.4, 3.0), (0, 0, 0), 480, (1.0, 0.82, 0.92), 4.0)
    rim.constraints.new("TRACK_TO").target = target
    rim.constraints[-1].track_axis = "TRACK_NEGATIVE_Z"
    rim.constraints[-1].up_axis = "UP_Y"

    # gentle ambient so shadows stay pastel, not black
    world = bpy.data.worlds.new("WORLD")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.9, 0.88, 0.92, 1.0)
    bg.inputs[1].default_value = 0.4


def render_settings(samples):
    scene = bpy.context.scene
    try:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE"
    try:
        scene.eevee.taa_render_samples = samples
    except AttributeError:
        pass
    try:
        scene.eevee.use_raytracing = True
    except AttributeError:
        pass
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    # keep the pastel texture colors true instead of AgX desaturation
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.exposure = 0.25


def render_still(path, res):
    scene = bpy.context.scene
    scene.render.resolution_x = res
    scene.render.resolution_y = res
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def render_turntable(rig, out_dir, name, frames, res):
    scene = bpy.context.scene
    scene.render.resolution_x = res
    scene.render.resolution_y = res
    base_yaw = rig.rotation_euler.z
    rig.rotation_euler.z = base_yaw
    rig.keyframe_insert("rotation_euler", index=2, frame=1)
    rig.rotation_euler.z = base_yaw + math.tau
    rig.keyframe_insert("rotation_euler", index=2, frame=frames + 1)
    for fc in rig.animation_data.action.fcurves:
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
    scene.frame_start = 1
    scene.frame_end = frames  # frame N+1 == frame 1, so 1..N is a clean loop
    scene.render.filepath = f"{out_dir}/turntable/{name}_"
    bpy.ops.render.render(animation=True)


def render_squish(rig, objs, out_dir, name, frames, res):
    """Squash-and-overshoot pop: compresses toward the floor, wobbles back.

    Re-parents the meshes under a floor-level pivot so the squash keeps the
    character grounded (a centered scale would lift its feet instead).
    """
    meshes = [o for o in objs if o.type == "MESH"]
    bpy.context.view_layer.update()
    bottom = min(
        (m.matrix_world @ Vector(c)).z for m in meshes for c in m.bound_box
    )
    squash = bpy.data.objects.new("SQUASH", None)
    squash.location = (0.0, 0.0, bottom)
    bpy.context.collection.objects.link(squash)
    squash.parent = rig
    for o in objs:
        if o.parent is rig:
            mw = o.matrix_world.copy()
            o.parent = squash
            o.matrix_world = mw

    # (frame_fraction, xy_scale, z_scale) — squash, overshoot, settle
    keys = [
        (0.00, 1.00, 1.00),
        (0.25, 1.30, 0.52),
        (0.50, 0.94, 1.10),
        (0.75, 1.05, 0.95),
        (1.00, 1.00, 1.00),
    ]
    for frac, xy, z in keys:
        f = 1 + round(frac * (frames - 1))
        squash.scale = (xy, xy, z)
        squash.keyframe_insert("scale", frame=f)

    scene = bpy.context.scene
    scene.render.resolution_x = res
    scene.render.resolution_y = res
    scene.frame_start = 1
    scene.frame_end = frames
    scene.render.filepath = f"{out_dir}/squish/{name}_"
    bpy.ops.render.render(animation=True)


def export_glb(objs, path):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True)


# ---------------------------------------------------------------- main


def main():
    t0 = time.time()
    args = parse_args()
    clean_scene()
    objs = import_fbx(args["fbx"])
    rig = normalize(objs, args["yaw"])
    studio_rig(args["elev"])
    render_settings(args["samples"])

    import os
    os.makedirs(args["out"], exist_ok=True)

    for res in args["hero"]:
        render_still(f"{args['out']}/{args['name']}_hero_{res}.png", res)
        print(f"[render3d] hero {res} done @ {time.time() - t0:.1f}s")

    if args["glb"]:
        export_glb([o for o in objs if o.type == "MESH"], f"{args['out']}/{args['name']}.glb")
        print(f"[render3d] glb done @ {time.time() - t0:.1f}s")

    if args["turntable"]:
        render_turntable(rig, args["out"], args["name"], args["turntable"], args["res"])
        print(f"[render3d] turntable x{args['turntable']} done @ {time.time() - t0:.1f}s")

    if args["squish"]:
        render_squish(rig, objs, args["out"], args["name"], args["squish"], args["squishres"])
        print(f"[render3d] squish x{args['squish']} done @ {time.time() - t0:.1f}s")

    print(f"[render3d] ALL DONE {args['name']} in {time.time() - t0:.1f}s")


main()
