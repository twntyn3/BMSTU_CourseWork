import math
import glfw
from OpenGL.GL import *

rot_x = 25.0
rot_y = 35.0
scale = 1.0
wireframe = True


def draw_conical_cylinder_faces(r1=0.95, r2=0.45, h=1.8, n=40):
    y1 = -h / 2.0
    y2 = h / 2.0

    glBegin(GL_QUADS)
    glColor3f(0.9, 0.4, 0.2)
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
        glVertex3f(x2t, y2, z2t)
        glVertex3f(x1t, y2, z1t)
    glEnd()

    glBegin(GL_TRIANGLE_FAN)
    glColor3f(0.2, 0.8, 0.9)
    glVertex3f(0.0, y2, 0.0)
    for i in range(n + 1):
        a = 2.0 * math.pi * i / n
        x = r2 * math.cos(a)
        z = r2 * math.sin(a)
        glVertex3f(x, y2, z)
    glEnd()

    glBegin(GL_TRIANGLE_FAN)
    glColor3f(0.8, 0.2, 0.8)
    glVertex3f(0.0, y1, 0.0)
    for i in range(n + 1):
        a = 2.0 * math.pi * (n - i) / n
        x = r1 * math.cos(a)
        z = r1 * math.sin(a)
        glVertex3f(x, y1, z)
    glEnd()


def draw_conical_cylinder_edges(r1=0.95, r2=0.45, h=1.8, n=40):
    y1 = -h / 2.0
    y2 = h / 2.0

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


def draw_conical_cylinder(r1=0.95, r2=0.45, h=1.8, n=40):
    if wireframe: #как раз-таки переключение режимов
        draw_conical_cylinder_edges(r1, r2, h, n)
    else:
        draw_conical_cylinder_faces(r1, r2, h, n)
        glEnable(GL_POLYGON_OFFSET_LINE)
        glPolygonOffset(-1.0, -1.0)
        draw_conical_cylinder_edges(r1, r2, h, n)
        glDisable(GL_POLYGON_OFFSET_LINE)


def draw_reference_conical_cylinder(): #рисую мал фигуру
    glPushMatrix()
    glTranslatef(2.2, -2.0, 0.0)
    draw_conical_cylinder(0.38, 0.18, 0.7, 30)
    glPopMatrix()


def set_ortho_projection(w, h):
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()

    aspect = w / h if h != 0 else 1.0 #соотношение сторон области вывода
    box = 3.2 #половина размеров видимого пространства

    if aspect >= 1.0:
        glOrtho(-box * aspect, box * aspect, -box, box, -20.0, 20.0)
    else:
        glOrtho(-box, box, -box / aspect, box / aspect, -20.0, 20.0)

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()


def apply_user_transform(): #применяю изменения для фигуры
    glScalef(scale, scale, scale)
    glRotatef(rot_x, 1.0, 0.0, 0.0)
    glRotatef(rot_y, 0.0, 1.0, 0.0)


def draw_scene(view_name):
    glLoadIdentity()
    glTranslatef(0.0, 0.0, -8.0)
#три проекции
    if view_name == "front":
        pass
    elif view_name == "top":
        glRotatef(90.0, 1.0, 0.0, 0.0) 
    elif view_name == "side":
        glRotatef(90.0, 0.0, 1.0, 0.0) 

    glPushMatrix()
    apply_user_transform()
    draw_conical_cylinder(0.95, 0.45, 1.8, 40)
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


def render(window):
    w, h = glfw.get_framebuffer_size(window)
    third = w // 3

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
    elif key == glfw.KEY_R:
        rot_x = 25.0
        rot_y = 35.0
        scale = 1.0
    elif key == glfw.KEY_ESCAPE:
        glfw.set_window_should_close(window, True)


def main():
    if not glfw.init():
        return

    window = glfw.create_window(1350, 520, "lab2", None, None)
    if not window:
        glfw.terminate()
        return

    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)

    glEnable(GL_DEPTH_TEST)
    glClearColor(0.0, 0.0, 0.0, 1.0)
    glLineWidth(2.0)

    while not glfw.window_should_close(window):
        render(window)
        glfw.swap_buffers(window)
        glfw.poll_events()

    glfw.terminate()


if __name__ == "__main__":
    main()