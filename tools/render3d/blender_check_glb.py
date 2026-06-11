"""Round-trip check: import a GLB and render it with a plain light rig.

  blender -b --factory-startup -P blender_check_glb.py -- --glb <path> --out <png>
"""

import math
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1 :]
glb = argv[argv.index("--glb") + 1]
out = argv[argv.index("--out") + 1]

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)

bpy.ops.import_scene.gltf(filepath=glb)
meshes = [o for o in bpy.data.objects if o.type == "MESH"]

pts = [m.matrix_world @ Vector(c) for m in meshes for c in m.bound_box]
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
center = (lo + hi) / 2
dim = max(hi - lo)

cam_data = bpy.data.cameras.new("CAM")
cam = bpy.data.objects.new("CAM", cam_data)
bpy.context.collection.objects.link(cam)
cam.location = center + Vector((0, -dim * 2.4, dim * 0.5))
track = cam.constraints.new("TRACK_TO")
aim = bpy.data.objects.new("AIM", None)
aim.location = center
bpy.context.collection.objects.link(aim)
track.target = aim
bpy.context.scene.camera = cam

sun = bpy.data.lights.new("SUN", "SUN")
sun.energy = 4
sun_obj = bpy.data.objects.new("SUN", sun)
sun_obj.rotation_euler = (math.radians(50), 0, math.radians(-30))
bpy.context.collection.objects.link(sun_obj)

scene = bpy.context.scene
try:
    scene.render.engine = "BLENDER_EEVEE_NEXT"
except TypeError:
    scene.render.engine = "BLENDER_EEVEE"
scene.render.film_transparent = True
scene.render.resolution_x = 512
scene.render.resolution_y = 512
scene.view_settings.view_transform = "Standard"
scene.render.filepath = out
bpy.ops.render.render(write_still=True)
print("[check_glb] rendered", out)
