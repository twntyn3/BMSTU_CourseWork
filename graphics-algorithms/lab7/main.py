import math
import csv
import time
import ctypes
import glfw
from OpenGL.GL import *

rot_x = 25.0
rot_y = 35.0
scale = 1.0
wireframe = False

lighting_enabled = True
texture_enabled = True
animation_enabled = True

global_ambient_mode = 1
texture_id = None

figure_y = 1.6
figure_vy = 0.0
g_acc = -2.8
floor_y = -2.2
figure_half_height = 0.9
last_time = 0.0

window_title = "lab7 optimization on lab6"

OPTIMIZATION_PRESETS = {
    "baseline": {
        "display_lists": False,
        "vertex_arrays": False,
        "indexed_draw": False,
        "cull_face": False,
        "animation_lod": False,
    },
    "display_lists": {
        "display_lists": True,
        "vertex_arrays": False,
        "indexed_draw": False,
        "cull_face": False,
        "animation_lod": False,
    },
    "display_lists_vertex_arrays": {
        "display_lists": True,
        "vertex_arrays": True,
        "indexed_draw": False,
        "cull_face": False,
        "animation_lod": False,
    },
    "display_lists_vertex_arrays_indexed": {
        "display_lists": True,
        "vertex_arrays": True,
        "indexed_draw": True,
        "cull_face": False,
        "animation_lod": False,
    },
    "all_optimizations": {
        "display_lists": True,
        "vertex_arrays": True,
        "indexed_draw": True,
        "cull_face": True,
        "animation_lod": True,
    },
}

current_preset_name = "all_optimizations"
current_opts = OPTIMIZATION_PRESETS[current_preset_name].copy()

geom_high = {}
geom_low = {}
floor_geom = {}

display_lists = {
    "floor": None,
    "reference_high": None,
    "reference_low": None,
}

def set_current_preset(name):
    global current_preset_name, current_opts
    current_preset_name = name
    current_opts = OPTIMIZATION_PRESETS[name].copy()

def create_checker_texture(size=64, cell=8):
    global texture_id
    data = []
    for y in range(size):
        for x in range(size):
            block_x = x // cell
            block_y = y // cell
            value = 240 if (block_x + block_y) % 2 == 0 else 80
            data.extend([value, value, value])

    raw = bytes(data)
    texture_id = glGenTextures(1)
    glBindTexture(GL_TEXTURE_2D, texture_id)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, size, size, 0, GL_RGB, GL_UNSIGNED_BYTE, raw)
    glBindTexture(GL_TEXTURE_2D, 0)

def set_global_ambient():
    if global_ambient_mode == 1:
        ambient = [0.08, 0.08, 0.08, 1.0]
    elif global_ambient_mode == 2:
        ambient = [0.35, 0.35, 0.35, 1.0]
    else:
        ambient = [0.75, 0.75, 0.75, 1.0]

    glLightModelfv(GL_LIGHT_MODEL_AMBIENT, ambient)
    glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER, GL_TRUE)

def setup_lighting():
    if lighting_enabled:
        glEnable(GL_LIGHTING)
        glEnable(GL_LIGHT0)
    else:
        glDisable(GL_LIGHT0)
        glDisable(GL_LIGHTING)
        return

    set_global_ambient()

    light_pos = [3.5, 4.5, 6.0, 1.0]
    light_ambient = [0.15, 0.15, 0.15, 1.0]
    light_diffuse = [0.9, 0.9, 0.9, 1.0]
    light_specular = [1.0, 1.0, 1.0, 1.0]

    glLightfv(GL_LIGHT0, GL_POSITION, light_pos)
    glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient)
    glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse)
    glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular)

def setup_material():
    mat_ambient = [0.75, 0.55, 0.35, 1.0]
    mat_diffuse = [0.85, 0.55, 0.30, 1.0]
    mat_specular = [0.95, 0.95, 0.95, 1.0]
    mat_shininess = [64.0]

    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, mat_ambient)
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, mat_diffuse)
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, mat_specular)
    glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, mat_shininess)

def enable_texture_for_object():
    if texture_enabled and texture_id is not None and not wireframe:
        glEnable(GL_TEXTURE_2D)
        glBindTexture(GL_TEXTURE_2D, texture_id)
    else:
        glDisable(GL_TEXTURE_2D)

def disable_texture_after_object():
    glDisable(GL_TEXTURE_2D)

def set_ortho_projection(w, h):
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()

    aspect = w / h if h != 0 else 1.0
    box = 4.0

    if aspect >= 1.0:
        glOrtho(-box * aspect, box * aspect, -box, box, -20.0, 20.0)
    else:
        glOrtho(-box, box, -box / aspect, box / aspect, -20.0, 20.0)

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()

def apply_user_transform():
    glScalef(scale, scale, scale)
    glRotatef(rot_x, 1.0, 0.0, 0.0)
    glRotatef(rot_y, 0.0, 1.0, 0.0)

def interleaved_vertex(x, y, z, nx, ny, nz, u, v):
    return [u, v, nx, ny, nz, x, y, z]

def build_conical_cylinder_geometry(r1, r2, h, n):
    y1 = -h / 2.0
    y2 = h / 2.0

    vertices = []
    indices = []

    for i in range(n + 1):
        a = 2.0 * math.pi * i / n
        ca = math.cos(a)
        sa = math.sin(a)

        xb = r1 * ca
        zb = r1 * sa
        xt = r2 * ca
        zt = r2 * sa

        nx = ca
        ny = 0.35
        nz = sa
        length = math.sqrt(nx * nx + ny * ny + nz * nz)
        nx /= length
        ny /= length
        nz /= length

        t = i / n
        vertices.extend(interleaved_vertex(xb, y1, zb, nx, ny, nz, t, 0.0))
        vertices.extend(interleaved_vertex(xt, y2, zt, nx, ny, nz, t, 1.0))

    for i in range(n):
        base = i * 2
        indices.extend([base, base + 1, base + 2, base + 1, base + 3, base + 2])

    top_center = len(vertices) // 8
    vertices.extend(interleaved_vertex(0.0, y2, 0.0, 0.0, 1.0, 0.0, 0.5, 0.5))
    for i in range(n + 1):
        a = 2.0 * math.pi * i / n
        x = r2 * math.cos(a)
        z = r2 * math.sin(a)
        u = 0.5 + 0.5 * math.cos(a)
        v = 0.5 + 0.5 * math.sin(a)
        vertices.extend(interleaved_vertex(x, y2, z, 0.0, 1.0, 0.0, u, v))

    ring_start = top_center + 1
    for i in range(n):
        indices.extend([top_center, ring_start + i, ring_start + i + 1])

    bottom_center = len(vertices) // 8
    vertices.extend(interleaved_vertex(0.0, y1, 0.0, 0.0, -1.0, 0.0, 0.5, 0.5))
    for i in range(n + 1):
        a = 2.0 * math.pi * (n - i) / n
        x = r1 * math.cos(a)
        z = r1 * math.sin(a)
        u = 0.5 + 0.5 * math.cos(a)
        v = 0.5 + 0.5 * math.sin(a)
        vertices.extend(interleaved_vertex(x, y1, z, 0.0, -1.0, 0.0, u, v))

    ring_start = bottom_center + 1
    for i in range(n):
        indices.extend([bottom_center, ring_start + i, ring_start + i + 1])

    return {"vertices": vertices, "indices": indices, "vertex_count": len(vertices) // 8}

def build_floor_geometry():
    verts = []
    y = floor_y
    verts.extend(interleaved_vertex(-3.8, y, -3.2, 0.0, 1.0, 0.0, 0.0, 0.0))
    verts.extend(interleaved_vertex( 3.8, y, -3.2, 0.0, 1.0, 0.0, 1.0, 0.0))
    verts.extend(interleaved_vertex( 3.8, y,  3.2, 0.0, 1.0, 0.0, 1.0, 1.0))
    verts.extend(interleaved_vertex(-3.8, y,  3.2, 0.0, 1.0, 0.0, 0.0, 1.0))

    return {"vertices": verts, "indices": [0, 1, 2, 0, 2, 3], "vertex_count": 4}

def init_geometry():
    global geom_high, geom_low, floor_geom
    geom_high = build_conical_cylinder_geometry(0.95, 0.45, 1.8, 40)
    geom_low = build_conical_cylinder_geometry(0.95, 0.45, 1.8, 16)
    floor_geom = build_floor_geometry()

def draw_geometry_immediate_indexed(geom):
    verts = geom["vertices"]
    idx = geom["indices"]

    glBegin(GL_TRIANGLES)
    for i in idx:
        base = i * 8
        u = verts[base + 0]
        v = verts[base + 1]
        nx = verts[base + 2]
        ny = verts[base + 3]
        nz = verts[base + 4]
        x = verts[base + 5]
        y = verts[base + 6]
        z = verts[base + 7]
        glTexCoord2f(u, v)
        glNormal3f(nx, ny, nz)
        glVertex3f(x, y, z)
    glEnd()

def draw_edges_immediate(r1=0.95, r2=0.45, h=1.8, n=40):
    y1 = -h / 2.0
    y2 = h / 2.0

    glDisable(GL_LIGHTING)
    glDisable(GL_TEXTURE_2D)
    glColor3f(1.0, 1.0, 1.0)

    glBegin(GL_LINES)
    for i in range(n):
        a1 = 2.0 * math.pi * i / n
        a2 = 2.0 * math.pi * (i + 1) / n

        x1b = r1 * math.cos(a1)
        z1b = r1 * math.sin(a1)
        x2b = r1 * math.cos(a2)
        z2b = r1 * math.sin(a2)

        x1t = r2 * math.cos(a1)
        z1t = r2 * math.sin(a1)
        x2t = r2 * math.cos(a2)
        z2t = r2 * math.sin(a2)

        glVertex3f(x1b, y1, z1b)
        glVertex3f(x2b, y1, z2b)

        glVertex3f(x1t, y2, z1t)
        glVertex3f(x2t, y2, z2t)

        glVertex3f(x1b, y1, z1b)
        glVertex3f(x1t, y2, z1t)
    glEnd()

    if lighting_enabled:
        glEnable(GL_LIGHTING)

def prepare_interleaved_arrays(geom):
    array_type = GLfloat * len(geom["vertices"])
    return array_type(*geom["vertices"])

def prepare_index_array(geom):
    array_type = GLuint * len(geom["indices"])
    return array_type(*geom["indices"])

def draw_geometry_arrays(geom, use_indices):
    interleaved = prepare_interleaved_arrays(geom)

    glEnableClientState(GL_VERTEX_ARRAY)
    glEnableClientState(GL_NORMAL_ARRAY)
    glEnableClientState(GL_TEXTURE_COORD_ARRAY)

    glInterleavedArrays(GL_T2F_N3F_V3F, 0, interleaved)

    if use_indices:
        index_data = prepare_index_array(geom)
        glDrawElements(GL_TRIANGLES, len(geom["indices"]), GL_UNSIGNED_INT, index_data)
    else:
        glDrawArrays(GL_TRIANGLES, 0, geom["vertex_count"])

    glDisableClientState(GL_TEXTURE_COORD_ARRAY)
    glDisableClientState(GL_NORMAL_ARRAY)
    glDisableClientState(GL_VERTEX_ARRAY)

def build_display_lists():
    if display_lists["floor"] is not None:
        for key in display_lists:
            glDeleteLists(display_lists[key], 1)
            display_lists[key] = None

    display_lists["floor"] = glGenLists(1)
    glNewList(display_lists["floor"], GL_COMPILE)
    draw_floor_immediate()
    glEndList()

    display_lists["reference_high"] = glGenLists(1)
    glNewList(display_lists["reference_high"], GL_COMPILE)
    draw_conical_cylinder_optimized(geom_high, edge_n=30)
    glEndList()

    display_lists["reference_low"] = glGenLists(1)
    glNewList(display_lists["reference_low"], GL_COMPILE)
    draw_conical_cylinder_optimized(geom_low, edge_n=16)
    glEndList()

def draw_floor_immediate():
    if lighting_enabled:
        floor_ambient = [0.25, 0.25, 0.28, 1.0]
        floor_diffuse = [0.45, 0.45, 0.50, 1.0]
        floor_specular = [0.15, 0.15, 0.15, 1.0]
        floor_shininess = [8.0]
        glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, floor_ambient)
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, floor_diffuse)
        glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, floor_specular)
        glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, floor_shininess)

    glColor3f(0.45, 0.45, 0.5)
    draw_geometry_immediate_indexed(floor_geom)

def draw_floor():
    if current_opts["display_lists"] and display_lists["floor"] is not None:
        glCallList(display_lists["floor"])
    else:
        draw_floor_immediate()

def draw_conical_cylinder_optimized(geom, edge_n):
    if wireframe:
        draw_edges_immediate(n=edge_n)
        return

    enable_texture_for_object()
    setup_material()
    glColor3f(0.9, 0.4, 0.2)

    if current_opts["vertex_arrays"]:
        draw_geometry_arrays(geom, current_opts["indexed_draw"])
    else:
        draw_geometry_immediate_indexed(geom)

    disable_texture_after_object()

    glEnable(GL_POLYGON_OFFSET_LINE)
    glPolygonOffset(-1.0, -1.0)
    draw_edges_immediate(n=edge_n)
    glDisable(GL_POLYGON_OFFSET_LINE)

def choose_main_geometry():
    if current_opts["animation_lod"] and animation_enabled:
        return geom_low, 16
    return geom_high, 40

def draw_main_object():
    geom, edge_n = choose_main_geometry()
    draw_conical_cylinder_optimized(geom, edge_n)

def draw_reference_conical_cylinder():
    glPushMatrix()
    glTranslatef(2.2, -1.6, 0.0)
    glScalef(0.8, 0.8, 0.8)

    if current_opts["display_lists"]:
        if current_opts["animation_lod"]:
            glCallList(display_lists["reference_low"])
        else:
            glCallList(display_lists["reference_high"])
    else:
        draw_conical_cylinder_optimized(geom_high, 30)

    glPopMatrix()

def update_animation():
    global figure_y, figure_vy, last_time
    now = glfw.get_time()
    dt = now - last_time
    last_time = now

    if not animation_enabled:
        return

    if dt > 0.05:
        dt = 0.05

    figure_vy += g_acc * dt
    figure_y += figure_vy * dt

    min_y = floor_y + figure_half_height
    if figure_y <= min_y:
        figure_y = min_y
        figure_vy = -figure_vy

def apply_optimization_state():
    if current_opts["cull_face"]:
        glEnable(GL_CULL_FACE)
        glCullFace(GL_BACK)
    else:
        glDisable(GL_CULL_FACE)

    glDisable(GL_NORMALIZE)

def draw_scene(view_name):
    glLoadIdentity()
    glTranslatef(0.0, 0.0, -8.0)

    if view_name == "front":
        pass
    elif view_name == "top":
        glRotatef(90.0, 1.0, 0.0, 0.0)
    elif view_name == "side":
        glRotatef(90.0, 0.0, 1.0, 0.0)

    setup_lighting()
    apply_optimization_state()
    draw_floor()

    glPushMatrix()
    glTranslatef(0.0, figure_y, 0.0)
    apply_user_transform()
    draw_main_object()
    glPopMatrix()

    draw_reference_conical_cylinder()

def draw_separator_lines(window):
    w, h = glfw.get_framebuffer_size(window)

    glViewport(0, 0, w, h)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    glOrtho(0, w, 0, h, -1, 1)

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()

    glDisable(GL_LIGHTING)
    glDisable(GL_TEXTURE_2D)
    glDisable(GL_DEPTH_TEST)

    glColor3f(0.5, 0.5, 0.5)
    x1 = w / 3.0
    x2 = 2.0 * w / 3.0

    glBegin(GL_LINES)
    glVertex2f(x1, 0)
    glVertex2f(x1, h)
    glVertex2f(x2, 0)
    glVertex2f(x2, h)
    glEnd()

    glEnable(GL_DEPTH_TEST)
    if lighting_enabled:
        glEnable(GL_LIGHTING)

def render(window):
    w, h = glfw.get_framebuffer_size(window)
    third = w // 3

    update_animation()
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    glViewport(0, 0, third, h)
    set_ortho_projection(third, h)
    draw_scene("front")

    glViewport(third, 0, third, h)
    set_ortho_projection(third, h)
    draw_scene("top")

    glViewport(third * 2, 0, w - third * 2, h)
    set_ortho_projection(w - third * 2, h)
    draw_scene("side")

    draw_separator_lines(window)

def run_single_benchmark(window, preset_name, seconds=5.0):
    global figure_y, figure_vy, last_time

    set_current_preset(preset_name)
    figure_y = 1.6
    figure_vy = 0.0
    last_time = glfw.get_time()

    start = time.perf_counter()
    frames = 0

    while not glfw.window_should_close(window):
        now = time.perf_counter()
        if now - start >= seconds:
            break

        render(window)
        glfw.swap_buffers(window)
        glfw.poll_events()
        frames += 1

    elapsed = time.perf_counter() - start
    fps = frames / elapsed if elapsed > 0 else 0.0
    ms = 1000.0 / fps if fps > 0 else 0.0

    return {
        "preset": preset_name,
        "elapsed_s": round(elapsed, 3),
        "frames": frames,
        "avg_fps": round(fps, 2),
        "avg_frame_ms": round(ms, 3),
    }

def run_benchmarks(window):
    print("\n--- BENCHMARK START ---")
    results = []

    for preset_name in OPTIMIZATION_PRESETS:
        print(f"Running: {preset_name}")
        result = run_single_benchmark(window, preset_name, seconds=5.0)
        results.append(result)
        print(result)

    out_path = "lab7_benchmark_results.csv"
    with open(out_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["preset", "elapsed_s", "frames", "avg_fps", "avg_frame_ms"]
        )
        writer.writeheader()
        writer.writerows(results)

    print(f"\nSaved results to {out_path}")
    print("--- BENCHMARK END ---\n")

def key_callback(window, key, scancode, action, mods):
    global rot_x, rot_y, scale, wireframe
    global lighting_enabled, texture_enabled, animation_enabled
    global global_ambient_mode, figure_y, figure_vy

    if action not in (glfw.PRESS, glfw.REPEAT):
        return

    if key == glfw.KEY_UP:
        rot_x -= 5.0
    elif key == glfw.KEY_DOWN:
        rot_x += 5.0
    elif key == glfw.KEY_LEFT:
        rot_y -= 5.0
    elif key == glfw.KEY_RIGHT:
        rot_y += 5.0
    elif key == glfw.KEY_W:
        scale += 0.1
    elif key == glfw.KEY_S:
        scale = max(0.2, scale - 0.1)
    elif key == glfw.KEY_SPACE:
        wireframe = not wireframe
    elif key == glfw.KEY_L:
        lighting_enabled = not lighting_enabled
    elif key == glfw.KEY_T:
        texture_enabled = not texture_enabled
    elif key == glfw.KEY_P:
        animation_enabled = not animation_enabled
    elif key == glfw.KEY_1:
        global_ambient_mode = 1
    elif key == glfw.KEY_2:
        global_ambient_mode = 2
    elif key == glfw.KEY_3:
        global_ambient_mode = 3
    elif key == glfw.KEY_B:
        figure_y = 1.6
        figure_vy = 0.0
    elif key == glfw.KEY_R:
        rot_x = 25.0
        rot_y = 35.0
        scale = 1.0
        figure_y = 1.6
        figure_vy = 0.0
        global_ambient_mode = 1
        lighting_enabled = True
        texture_enabled = True
        animation_enabled = True
        wireframe = False
        set_current_preset("all_optimizations")
    elif key == glfw.KEY_F1:
        set_current_preset("baseline")
    elif key == glfw.KEY_F2:
        set_current_preset("display_lists")
    elif key == glfw.KEY_F3:
        set_current_preset("display_lists_vertex_arrays")
    elif key == glfw.KEY_F4:
        set_current_preset("display_lists_vertex_arrays_indexed")
    elif key == glfw.KEY_F5:
        set_current_preset("all_optimizations")
    elif key == glfw.KEY_F9:
        run_benchmarks(window)
    elif key == glfw.KEY_ESCAPE:
        glfw.set_window_should_close(window, True)

def main():
    global last_time

    if not glfw.init():
        return

    window = glfw.create_window(1500, 620, window_title, None, None)
    if not window:
        glfw.terminate()
        return

    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)

    init_geometry()

    glEnable(GL_DEPTH_TEST)
    glShadeModel(GL_SMOOTH)
    glClearColor(0.08, 0.08, 0.12, 1.0)
    glLineWidth(2.0)

    create_checker_texture()
    build_display_lists()
    set_current_preset("all_optimizations")
    last_time = glfw.get_time()

    print("Controls:")
    print("Arrows/W/S/Space/L/T/P/1/2/3/B/R")
    print("F1 baseline")
    print("F2 display lists")
    print("F3 display lists + vertex arrays")
    print("F4 display lists + vertex arrays + indexed draw")
    print("F5 all optimizations")
    print("F9 run benchmark and save CSV")

    while not glfw.window_should_close(window):
        render(window)
        glfw.swap_buffers(window)
        glfw.poll_events()

    glfw.terminate()

if __name__ == "__main__":
    main()
