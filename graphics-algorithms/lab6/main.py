import math
import glfw
from OpenGL.GL import *
from OpenGL.GLU import *

rot_x = 25.0
rot_y = 35.0
scale = 1.0
wireframe = False

lighting_enabled = True
texture_enabled = True
animation_enabled = True
show_help = True

global_ambient_mode = 1
texture_id = None

figure_y = 1.6
figure_vy = 0.0
g_acc = -2.8
floor_y = -2.2
figure_half_height = 0.9
last_time = 0.0


def create_checker_texture(size=64, cell=8):
    global texture_id

    data = []
    for y in range(size):
        for x in range(size):
            block_x = x // cell
            block_y = y // cell
            if (block_x + block_y) % 2 == 0:
                value = 240
            else:
                value = 80
            data.extend([value, value, value])

    raw = bytes(data)

    texture_id = glGenTextures(1)
    glBindTexture(GL_TEXTURE_2D, texture_id)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)


    
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE)
    glTexImage2D(
        GL_TEXTURE_2D,
        0,
        GL_RGB,
        size,
        size,
        0,
        GL_RGB,
        GL_UNSIGNED_BYTE,
        raw,
    )



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



def draw_floor():
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
    glBegin(GL_QUADS)
    glNormal3f(0.0, 1.0, 0.0)
    glVertex3f(-3.8, floor_y, -3.2)
    glVertex3f(3.8, floor_y, -3.2)
    glVertex3f(3.8, floor_y, 3.2)
    glVertex3f(-3.8, floor_y, 3.2)
    glEnd()



def draw_axes():
    glDisable(GL_LIGHTING)
    glDisable(GL_TEXTURE_2D)

    glBegin(GL_LINES)
    glColor3f(1.0, 0.0, 0.0)
    glVertex3f(0.0, 0.0, 0.0)
    glVertex3f(2.3, 0.0, 0.0)

    glColor3f(0.0, 1.0, 0.0)
    glVertex3f(0.0, 0.0, 0.0)
    glVertex3f(0.0, 2.3, 0.0)

    glColor3f(0.0, 0.5, 1.0)
    glVertex3f(0.0, 0.0, 0.0)
    glVertex3f(0.0, 0.0, 2.3)
    glEnd()

    if lighting_enabled:
        glEnable(GL_LIGHTING)



def draw_conical_cylinder_faces(r1=0.95, r2=0.45, h=1.8, n=40):
    y1 = -h / 2.0
    y2 = h / 2.0

    glColor3f(0.9, 0.4, 0.2)
    glBegin(GL_QUADS)
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

        nx1 = math.cos(a1)
        nz1 = math.sin(a1)
        nx2 = math.cos(a2)
        nz2 = math.sin(a2)

        t1 = i / n
        t2 = (i + 1) / n

        glNormal3f(nx1, 0.35, nz1)
        glTexCoord2f(t1, 0.0)
        glVertex3f(x1b, y1, z1b)

        glNormal3f(nx2, 0.35, nz2)
        glTexCoord2f(t2, 0.0)
        glVertex3f(x2b, y1, z2b)

        glNormal3f(nx2, 0.35, nz2)
        glTexCoord2f(t2, 1.0)
        glVertex3f(x2t, y2, z2t)

        glNormal3f(nx1, 0.35, nz1)
        glTexCoord2f(t1, 1.0)
        glVertex3f(x1t, y2, z1t)
    glEnd()

    glColor3f(0.2, 0.8, 0.9)
    glBegin(GL_TRIANGLE_FAN)
    glNormal3f(0.0, 1.0, 0.0)
    glTexCoord2f(0.5, 0.5)
    glVertex3f(0.0, y2, 0.0)
    for i in range(n + 1):
        a = 2.0 * math.pi * i / n
        x = r2 * math.cos(a)
        z = r2 * math.sin(a)
        glNormal3f(0.0, 1.0, 0.0)
        glTexCoord2f(0.5 + 0.5 * math.cos(a), 0.5 + 0.5 * math.sin(a))
        glVertex3f(x, y2, z)
    glEnd()

    glColor3f(0.8, 0.2, 0.8)
    glBegin(GL_TRIANGLE_FAN)
    glNormal3f(0.0, -1.0, 0.0)
    glTexCoord2f(0.5, 0.5)
    glVertex3f(0.0, y1, 0.0)
    for i in range(n + 1):
        a = 2.0 * math.pi * (n - i) / n
        x = r1 * math.cos(a)
        z = r1 * math.sin(a)
        glNormal3f(0.0, -1.0, 0.0)
        glTexCoord2f(0.5 + 0.5 * math.cos(a), 0.5 + 0.5 * math.sin(a))
        glVertex3f(x, y1, z)
    glEnd()



def draw_conical_cylinder_edges(r1=0.95, r2=0.45, h=1.8, n=40):
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



def draw_conical_cylinder(r1=0.95, r2=0.45, h=1.8, n=40):
    if wireframe:
        draw_conical_cylinder_edges(r1, r2, h, n)
    else:
        enable_texture_for_object()
        setup_material()
        draw_conical_cylinder_faces(r1, r2, h, n)
        disable_texture_after_object()

        glEnable(GL_POLYGON_OFFSET_LINE)
        glPolygonOffset(-1.0, -1.0)
        draw_conical_cylinder_edges(r1, r2, h, n)
        glDisable(GL_POLYGON_OFFSET_LINE)



def draw_reference_conical_cylinder():
    glPushMatrix()
    glTranslatef(2.2, -1.6, 0.0)
    glScalef(0.8, 0.8, 0.8)
    draw_conical_cylinder(0.38, 0.18, 0.7, 30)
    glPopMatrix()



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
    draw_axes()
    draw_floor()

    glPushMatrix()
    glTranslatef(0.0, figure_y, 0.0)
    apply_user_transform()
    draw_conical_cylinder(0.95, 0.45, 1.8, 40)
    glPopMatrix()

    glPushMatrix()
    draw_reference_conical_cylinder()
    glPopMatrix()



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



def draw_text(window, text, x, y):
    pass



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
    elif key == glfw.KEY_ESCAPE:
        glfw.set_window_should_close(window, True)



def main():
    global last_time

    if not glfw.init():
        return

    window = glfw.create_window(1500, 620, "lab6", None, None)
    if not window:
        glfw.terminate()
        return

    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)

    glEnable(GL_DEPTH_TEST)
    glEnable(GL_NORMALIZE)
    glShadeModel(GL_SMOOTH)
    glClearColor(0.08, 0.08, 0.12, 1.0)
    glLineWidth(2.0)

    create_checker_texture()
    last_time = glfw.get_time()

    while not glfw.window_should_close(window):
        render(window)
        glfw.swap_buffers(window)
        glfw.poll_events()

    glfw.terminate()


if __name__ == "__main__":
    main()