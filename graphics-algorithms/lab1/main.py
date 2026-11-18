import math
import glfw
from OpenGL.GL import *

delta = 1.0
angle = 0.0
posx = 0.0
posy = 0.0
size = 0.18
color_mode = 0


def draw_heart():
    global size, color_mode

    glBegin(GL_POLYGON) 

    for i in range(200):
        t = 2.0 * math.pi * i / 200.0

        # сердечко
        x = 16 * (math.sin(t) ** 3)
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)

        x *= size / 10.0
        y *= size / 10.0

        if color_mode == 0:
            # градиент в розово-красных тонах
            glColor3f(0.9, 0.2 + 0.3 * (i % 2), 0.4)
        else:
            # голубой 
            glColor3f(0.2, 0.7, 1.0 if i % 2 == 0 else 0.6)

        glVertex2f(x, y)

    glEnd()



def display(window):
    global angle

    glClearColor(1.0, 1.0, 1.0, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()

    glPushMatrix()
    glTranslatef(posx, posy, 0.0)       # сдвиг
    glRotatef(angle, 0.0, 0.0, 1.0)     # поворот

    draw_heart()

    glPopMatrix()

    angle += delta

    glfw.swap_buffers(window)
    glfw.poll_events()


def key_callback(window, key, scancode, action, mods):
    global delta, posx, posy, color_mode, angle

    if action == glfw.PRESS or action == glfw.REPEAT:
        if key == glfw.KEY_RIGHT:
            delta = -3.0
        elif key == glfw.KEY_LEFT:
            delta = 3.0
        elif key == glfw.KEY_UP:
            posy += 0.05
        elif key == glfw.KEY_DOWN:
            posy -= 0.05
        elif key == glfw.KEY_A:
            posx -= 0.05
        elif key == glfw.KEY_D:
            posx += 0.05
        elif key == glfw.KEY_SPACE:
            delta = 0.0
        elif key == glfw.KEY_ENTER:
            delta = 1.0
        elif key == glfw.KEY_C:
            color_mode = 1 - color_mode   # смена цвета
        elif key == glfw.KEY_R:
            posx = 0.0
            posy = 0.0
            angle = 0.0                   # сброс
        elif key == glfw.KEY_ESCAPE:
            glfw.set_window_should_close(window, True)


def main():
    if not glfw.init():
        return

    window = glfw.create_window(640, 640, "lab1", None, None)
    if not window:
        glfw.terminate()
        return

    glfw.make_context_current(window)

    glfw.set_key_callback(window, key_callback)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()

    while not glfw.window_should_close(window):
        display(window)

    glfw.destroy_window(window)
    glfw.terminate()


if __name__ == "__main__":
    main()