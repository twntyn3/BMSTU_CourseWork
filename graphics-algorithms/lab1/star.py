import glfw
from OpenGL.GL import *
import sys
import math

class InteractiveStar:
    def __init__(self):
        if not glfw.init():
            print("Ошибка инициализации библиотеки")
            sys.exit(1)
        self.star_x = 0.0
        self.star_y = 0.0
        self.star_size = 0.4

        self.star_color_r = 1.0
        self.star_color_g = 0.8  
        self.star_color_b = 0.0  

        self.star_rotation = 0.0
        self.rotation_speed = 0.5
        self.auto_rotate = True
    
    def draw_star(self):
        glBegin(GL_LINE_LOOP)
        glColor3f(self.star_color_r, self.star_color_g, self.star_color_b)
        for i in range(10):
            # Вычисляем угол для текущей вершины
            angle = math.radians(self.star_rotation) + (2 * math.pi * i / 10)
            
            # Чередуем внешние и внутренние вершины
            if i % 2 == 0:  # Чётные - внешние вершины (концы лучей)
                radius = self.star_size
            else:  # Нечётные - внутренние вершины (впадины)
                radius = self.star_size * 0.38
            
            # вычисляем координаты вершины
            x = self.star_x + radius * math.cos(angle)
            y = self.star_y + radius * math.sin(angle)
            
            # Добавляем вершину
            glVertex2f(x, y)
        glEnd()

    def create_window(self):
        self.window = glfw.create_window(800,600,"LAB1", None, None)
        if not self.window:
            glfw.terminate()

            print("window error")
            sys.exit(1)

        glfw.make_context_current(self.window)
    
    def run(self):
        self.create_window()

        while not glfw.window_should_close(self.window):
            glClearColor( 0.0, 0.0, 0.0, 1.0)
            glClear(GL_COLOR_BUFFER_BIT)



            self.star_rotation += self.rotation_speed  # поворачиваем звезду
            if self.star_rotation > 360:
                self.star_rotation -= 360
            
            self.draw_star()  # рисуем звезду


            glfw.swap_buffers(self.window)
            glfw.poll_events()
            
        glfw.terminate()
if __name__== "__main__":

    app = InteractiveStar()

    app.run()
