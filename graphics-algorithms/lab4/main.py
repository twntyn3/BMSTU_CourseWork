import glfw
import numpy as np
from OpenGL.GL import *


win_w = 900
win_h = 700

points = []
polygon_closed = False

buffer = None

fill_color = [170, 210, 255]
point_color = [255, 0, 0]


def create_buffer():
    global buffer
    buffer = np.full((win_h, win_w, 3), 255, dtype=np.uint8)


def clear_all():
    global points, polygon_closed
    points = []
    polygon_closed = False
    create_buffer()


def put_pixel(x, y, color):
    if 0 <= x < win_w and 0 <= y < win_h:
        row = win_h - 1 - y
        buffer[row, x] = color


def darken_pixel(x, y, intensity):
    if 0 <= x < win_w and 0 <= y < win_h:
        row = win_h - 1 - y
        k = max(0, min(255, int(intensity)))

        buffer[row, x, 0] = buffer[row, x, 0] * (255 - k) // 255
        buffer[row, x, 1] = buffer[row, x, 1] * (255 - k) // 255
        buffer[row, x, 2] = buffer[row, x, 2] * (255 - k) // 255


def draw_point(x, y):
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            put_pixel(x + dx, y + dy, point_color)

#b1
def draw_line_bresenham_smooth(x1, y1, x2, y2):
    x1 = int(round(x1))
    y1 = int(round(y1))
    x2 = int(round(x2))
    y2 = int(round(y2))

    dx = abs(x2 - x1)
    dy = abs(y2 - y1)

    sx = 1 if x2 >= x1 else -1
    sy = 1 if y2 >= y1 else -1

    if dx == 0 and dy == 0:
        darken_pixel(x1, y1, 255)
        return
#gorizont
    if dx >= dy:
        err = 0
        step = 0 if dx == 0 else (dy * 255) // dx

        x = x1
        y = y1
#ustr stupen4atosti
        for _ in range(dx + 1):
            darken_pixel(x, y, 255 - err)

            if err > 0:
                darken_pixel(x, y + sy, err)

            x += sx
            err += step

            if err >= 255:
                y += sy
                err -= 255
#vert                
    else:
        err = 0
        step = 0 if dy == 0 else (dx * 255) // dy

        x = x1
        y = y1

        for _ in range(dy + 1):
            darken_pixel(x, y, 255 - err)

            if err > 0:
                darken_pixel(x + sx, y, err)

            y += sy
            err += step

            if err >= 255:
                x += sx
                err -= 255

#a3
def fill_polygon_by_edges(poly):
    fill_mask = np.zeros((win_h, win_w), dtype=np.uint8) #sozdanie maski zalivki

    n = len(poly)

    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]

        if y1 == y2:
            continue

        if y1 > y2:
            x1, y1, x2, y2 = x2, y2, x1, y1
#prohod po rebru i inversiya sprava ot perece4eniya
        dx = (x2 - x1) / (y2 - y1)
        x = x1

        for y in range(y1, y2):
            if 0 <= y < win_h:
                xi = int(round(x))

                if xi < 0:
                    xi = 0

                if xi < win_w:
                    fill_mask[y, xi:win_w] ^= 1

            x += dx
#zaprawivau pixeli kotorie edinicbl
    for y in range(win_h):
        row = win_h - 1 - y
        mask = fill_mask[y] == 1
        buffer[row, mask] = fill_color


def rebuild_buffer():
    create_buffer()
#tol'ko esli mnogoug zamknut
    if polygon_closed and len(points) >= 3:
        fill_polygon_by_edges(points)

    if len(points) >= 2:
        for i in range(len(points) - 1):
            x1, y1 = points[i]
            x2, y2 = points[i + 1]
            draw_line_bresenham_smooth(x1, y1, x2, y2) #dlya kazhdogo rebra

    if polygon_closed and len(points) >= 3:
        x1, y1 = points[-1]
        x2, y2 = points[0]
        draw_line_bresenham_smooth(x1, y1, x2, y2)

    for x, y in points:
        draw_point(x, y)


def mouse_button_callback(window, button, action, mods):
    global polygon_closed

    if action != glfw.PRESS:
        return

    if polygon_closed:
        return

    if button == glfw.MOUSE_BUTTON_LEFT:
        xpos, ypos = glfw.get_cursor_pos(window)

        win_w_now, win_h_now = glfw.get_window_size(window)
        fb_w, fb_h = glfw.get_framebuffer_size(window)

        sx = fb_w / win_w_now
        sy = fb_h / win_h_now

        x = int(round(xpos * sx))
        y = int(round((win_h_now - 1 - ypos) * sy))

        points.append((x, y))
        rebuild_buffer()

    elif button == glfw.MOUSE_BUTTON_RIGHT:
        if len(points) >= 3:
            polygon_closed = True
            rebuild_buffer()


def key_callback(window, key, scancode, action, mods):
    global polygon_closed

    if action not in (glfw.PRESS, glfw.REPEAT):
        return

    if key == glfw.KEY_ENTER:
        if not polygon_closed and len(points) >= 3:
            polygon_closed = True
            rebuild_buffer()

    elif key == glfw.KEY_BACKSPACE:
        if not polygon_closed and len(points) > 0:
            points.pop()
            rebuild_buffer()

    elif key == glfw.KEY_C:
        clear_all()

    elif key == glfw.KEY_ESCAPE:
        glfw.set_window_should_close(window, True)


def framebuffer_size_callback(window, width, height):
    global win_w, win_h

    if width <= 0 or height <= 0:
        return

    win_w = width
    win_h = height

    glViewport(0, 0, win_w, win_h)
    rebuild_buffer()


def render():
    glClear(GL_COLOR_BUFFER_BIT)
    glRasterPos2f(-1.0, -1.0)
    glDrawPixels(win_w, win_h, GL_RGB, GL_UNSIGNED_BYTE, np.flipud(buffer))


def main():
    global win_w, win_h

    if not glfw.init():
        return

    window = glfw.create_window(900, 700, "lab4", None, None)
    if not window:
        glfw.terminate()
        return

    glfw.make_context_current(window)

    glfw.set_mouse_button_callback(window, mouse_button_callback)
    glfw.set_key_callback(window, key_callback)
    glfw.set_framebuffer_size_callback(window, framebuffer_size_callback)

    fb_w, fb_h = glfw.get_framebuffer_size(window)
    win_w = fb_w
    win_h = fb_h

    glViewport(0, 0, win_w, win_h)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()

    glClearColor(1.0, 1.0, 1.0, 1.0)

    create_buffer()

    while not glfw.window_should_close(window):
        render()
        glfw.swap_buffers(window)
        glfw.poll_events()

    glfw.terminate()


if __name__ == "__main__":
    main()