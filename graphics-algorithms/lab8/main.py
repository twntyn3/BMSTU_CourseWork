import math
import ctypes
import glfw
import numpy as np
from OpenGL.GL import *
from OpenGL.GL.shaders import compileProgram, compileShader




rot_x = 25.0
rot_y = 35.0
scale = 1.0
wireframe = False

lighting_enabled = True
texture_enabled = True
animation_enabled = True

global_ambient_mode = 1

figure_y = 1.6
figure_vy = 0.0
g_acc = -2.8
floor_y = -2.2
figure_half_height = 0.9
last_time = 0.0

window_width = 1500
window_height = 620

shader_program = None
line_shader_program = None

vao_main = None
vbo_main = None
ebo_main = None
main_index_count = 0

vao_floor = None
vbo_floor = None
ebo_floor = None
floor_index_count = 0

vao_lines = None
vbo_lines = None

texture_id = None

uniforms = {}
line_uniforms = {}




def identity():
    return np.identity(4, dtype=np.float32)


def translate(x, y, z):
    m = identity()
    m[0, 3] = x
    m[1, 3] = y
    m[2, 3] = z
    return m


def scale_matrix(sx, sy, sz):
    m = identity()
    m[0, 0] = sx
    m[1, 1] = sy
    m[2, 2] = sz
    return m


def rotate_x(angle_deg):
    a = math.radians(angle_deg)
    c = math.cos(a)
    s = math.sin(a)
    m = identity()
    m[1, 1] = c
    m[1, 2] = -s
    m[2, 1] = s
    m[2, 2] = c
    return m


def rotate_y(angle_deg):
    a = math.radians(angle_deg)
    c = math.cos(a)
    s = math.sin(a)
    m = identity()
    m[0, 0] = c
    m[0, 2] = s
    m[2, 0] = -s
    m[2, 2] = c
    return m


def ortho(left, right, bottom, top, near, far):
    m = np.zeros((4, 4), dtype=np.float32)
    m[0, 0] = 2.0 / (right - left)
    m[1, 1] = 2.0 / (top - bottom)
    m[2, 2] = -2.0 / (far - near)
    m[3, 3] = 1.0
    m[0, 3] = -(right + left) / (right - left)
    m[1, 3] = -(top + bottom) / (top - bottom)
    m[2, 3] = -(far + near) / (far - near)
    return m


def normal_matrix_from_model(model):
    return np.linalg.inv(model[:3, :3]).T.astype(np.float32)


def mat4_to_gl(m):
    return np.array(m.T, dtype=np.float32)


def mat3_to_gl(m):
    return np.array(m.T, dtype=np.float32)



# weyderi 3d

VERTEX_SHADER = """
#version 330 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aTexCoord;

uniform mat4 uModel;
uniform mat4 uView;
uniform mat4 uProjection;
uniform mat3 uNormalMatrix;

out vec3 FragPos;
out vec3 Normal;
out vec2 TexCoord;

void main()
{
    vec4 worldPos = uModel * vec4(aPos, 1.0);
    FragPos = worldPos.xyz;
    Normal = normalize(uNormalMatrix * aNormal);
    TexCoord = aTexCoord;
    gl_Position = uProjection * uView * worldPos;
}
"""

FRAGMENT_SHADER = """
#version 330 core

in vec3 FragPos;
in vec3 Normal;
in vec2 TexCoord;

out vec4 FragColor;

uniform vec3 uLightPos;
uniform vec3 uViewPos;

uniform vec3 uGlobalAmbient;
uniform vec3 uLightAmbient;
uniform vec3 uLightDiffuse;
uniform vec3 uLightSpecular;

uniform vec3 uMaterialAmbient;
uniform vec3 uMaterialDiffuse;
uniform vec3 uMaterialSpecular;
uniform float uShininess;

uniform bool uUseTexture;
uniform bool uLightingEnabled;
uniform sampler2D uTextureSampler;

void main()
{
    vec3 baseColor = uMaterialDiffuse;

    if (uUseTexture)
    {
        baseColor *= texture(uTextureSampler, TexCoord).rgb;
    }

    if (!uLightingEnabled)
    {
        FragColor = vec4(baseColor, 1.0);
        return;
    }

    vec3 ambient = (uGlobalAmbient + uLightAmbient) * uMaterialAmbient;

    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(uLightPos - FragPos);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = uLightDiffuse * diff * baseColor;

    vec3 viewDir = normalize(uViewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), uShininess);
    vec3 specular = uLightSpecular * spec * uMaterialSpecular;

    vec3 result = ambient + diffuse + specular;
    FragColor = vec4(result, 1.0);
}
"""


# weyderi dlya liniy

LINE_VERTEX_SHADER = """
#version 330 core

layout (location = 0) in vec2 aPos;

void main()
{
    gl_Position = vec4(aPos, 0.0, 1.0);
}
"""

LINE_FRAGMENT_SHADER = """
#version 330 core

out vec4 FragColor;
uniform vec3 uLineColor;

void main()
{
    FragColor = vec4(uLineColor, 1.0);
}
"""



def add_vertex(container, x, y, z, nx, ny, nz, u, v):
    container.extend([x, y, z, nx, ny, nz, u, v])


def create_conical_cylinder_geometry(r1=0.95, r2=0.45, h=1.8, n=40):
    vertices = []
    indices = []
    y1 = -h / 2.0
    y2 = h / 2.0


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
        add_vertex(vertices, xb, y1, zb, nx, ny, nz, t, 0.0)
        add_vertex(vertices, xt, y2, zt, nx, ny, nz, t, 1.0)

    for i in range(n):
        base = i * 2
        indices.extend([base, base + 1, base + 2])
        indices.extend([base + 1, base + 3, base + 2])


    top_center = len(vertices) // 8
    add_vertex(vertices, 0.0, y2, 0.0, 0.0, 1.0, 0.0, 0.5, 0.5)

    for i in range(n + 1):
        a = 2.0 * math.pi * i / n
        x = r2 * math.cos(a)
        z = r2 * math.sin(a)
        u = 0.5 + 0.5 * math.cos(a)
        v = 0.5 + 0.5 * math.sin(a)
        add_vertex(vertices, x, y2, z, 0.0, 1.0, 0.0, u, v)

    ring_start = top_center + 1
    for i in range(n):
        indices.extend([top_center, ring_start + i, ring_start + i + 1])


    bottom_center = len(vertices) // 8
    add_vertex(vertices, 0.0, y1, 0.0, 0.0, -1.0, 0.0, 0.5, 0.5)

    for i in range(n + 1):
        a = 2.0 * math.pi * (n - i) / n
        x = r1 * math.cos(a)
        z = r1 * math.sin(a)
        u = 0.5 + 0.5 * math.cos(a)
        v = 0.5 + 0.5 * math.sin(a)
        add_vertex(vertices, x, y1, z, 0.0, -1.0, 0.0, u, v)

    ring_start = bottom_center + 1
    for i in range(n):
        indices.extend([bottom_center, ring_start + i, ring_start + i + 1])

    return np.array(vertices, dtype=np.float32), np.array(indices, dtype=np.uint32)


def create_floor_geometry():
    vertices = []
    y = floor_y

    add_vertex(vertices, -3.8, y, -3.2, 0.0, 1.0, 0.0, 0.0, 0.0)
    add_vertex(vertices,  3.8, y, -3.2, 0.0, 1.0, 0.0, 1.0, 0.0)
    add_vertex(vertices,  3.8, y,  3.2, 0.0, 1.0, 0.0, 1.0, 1.0)
    add_vertex(vertices, -3.8, y,  3.2, 0.0, 1.0, 0.0, 0.0, 1.0)

    indices = [0, 1, 2, 0, 2, 3]
    return np.array(vertices, dtype=np.float32), np.array(indices, dtype=np.uint32)


def create_vao(vertices, indices):
    vao = glGenVertexArrays(1)
    vbo = glGenBuffers(1)
    ebo = glGenBuffers(1)

    glBindVertexArray(vao)

    glBindBuffer(GL_ARRAY_BUFFER, vbo)
    glBufferData(GL_ARRAY_BUFFER, vertices.nbytes, vertices, GL_STATIC_DRAW)

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.nbytes, indices, GL_STATIC_DRAW)

    stride = 8 * 4

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, stride, ctypes.c_void_p(0))
    glEnableVertexAttribArray(0)

    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, stride, ctypes.c_void_p(12))
    glEnableVertexAttribArray(1)

    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, stride, ctypes.c_void_p(24))
    glEnableVertexAttribArray(2)

    glBindVertexArray(0)
    return vao, vbo, ebo


def create_line_vao():
    vao = glGenVertexArrays(1)
    vbo = glGenBuffers(1)

    glBindVertexArray(vao)
    glBindBuffer(GL_ARRAY_BUFFER, vbo)

    glBufferData(GL_ARRAY_BUFFER, 4 * 2 * 4, None, GL_DYNAMIC_DRAW)

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * 4, ctypes.c_void_p(0))
    glEnableVertexAttribArray(0)

    glBindVertexArray(0)
    return vao, vbo



# textura

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
    glBindTexture(GL_TEXTURE_2D, 0)



# weyder setup

def build_shader_program():
    return compileProgram(
        compileShader(VERTEX_SHADER, GL_VERTEX_SHADER),
        compileShader(FRAGMENT_SHADER, GL_FRAGMENT_SHADER),
        validate=False
    )


def build_line_shader_program():
    return compileProgram(
        compileShader(LINE_VERTEX_SHADER, GL_VERTEX_SHADER),
        compileShader(LINE_FRAGMENT_SHADER, GL_FRAGMENT_SHADER),
        validate=False
    )


def fetch_uniform_locations():
    global uniforms
    names = [
        "uModel", "uView", "uProjection", "uNormalMatrix",
        "uLightPos", "uViewPos", "uGlobalAmbient",
        "uLightAmbient", "uLightDiffuse", "uLightSpecular",
        "uMaterialAmbient", "uMaterialDiffuse", "uMaterialSpecular",
        "uShininess", "uUseTexture", "uLightingEnabled", "uTextureSampler"
    ]
    uniforms = {name: glGetUniformLocation(shader_program, name) for name in names}


def fetch_line_uniform_locations():
    global line_uniforms
    line_uniforms = {
        "uLineColor": glGetUniformLocation(line_shader_program, "uLineColor")
    }



#scenehelpers

def get_global_ambient():
    if global_ambient_mode == 1:
        return (0.08, 0.08, 0.08)
    elif global_ambient_mode == 2:
        return (0.35, 0.35, 0.35)
    return (0.75, 0.75, 0.75)


def apply_common_uniforms(view, projection, view_pos):
    glUseProgram(shader_program)

    glUniformMatrix4fv(uniforms["uView"], 1, GL_FALSE, mat4_to_gl(view))
    glUniformMatrix4fv(uniforms["uProjection"], 1, GL_FALSE, mat4_to_gl(projection))

    glUniform3f(uniforms["uLightPos"], 3.5, 4.5, 6.0)
    glUniform3f(uniforms["uViewPos"], *view_pos)

    ga = get_global_ambient()
    glUniform3f(uniforms["uGlobalAmbient"], *ga)
    glUniform3f(uniforms["uLightAmbient"], 0.15, 0.15, 0.15)
    glUniform3f(uniforms["uLightDiffuse"], 0.9, 0.9, 0.9)
    glUniform3f(uniforms["uLightSpecular"], 1.0, 1.0, 1.0)

    glUniform1i(uniforms["uLightingEnabled"], 1 if lighting_enabled else 0)
    glUniform1i(uniforms["uTextureSampler"], 0)


def set_material(ambient, diffuse, specular, shininess):
    glUniform3f(uniforms["uMaterialAmbient"], *ambient)
    glUniform3f(uniforms["uMaterialDiffuse"], *diffuse)
    glUniform3f(uniforms["uMaterialSpecular"], *specular)
    glUniform1f(uniforms["uShininess"], shininess)


def draw_object(vao, index_count, model, use_texture, material):
    normal = normal_matrix_from_model(model)

    glUniformMatrix4fv(uniforms["uModel"], 1, GL_FALSE, mat4_to_gl(model))
    glUniformMatrix3fv(uniforms["uNormalMatrix"], 1, GL_FALSE, mat3_to_gl(normal))

    set_material(*material)
    glUniform1i(uniforms["uUseTexture"], 1 if (use_texture and texture_enabled) else 0)

    if use_texture and texture_enabled:
        glActiveTexture(GL_TEXTURE0)
        glBindTexture(GL_TEXTURE_2D, texture_id)
    else:
        glBindTexture(GL_TEXTURE_2D, 0)

    glBindVertexArray(vao)
    glDrawElements(GL_TRIANGLES, index_count, GL_UNSIGNED_INT, None)
    glBindVertexArray(0)



# Animation

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





def get_projection_for_viewport(w, h):
    aspect = w / h if h != 0 else 1.0
    box = 4.0

    if aspect >= 1.0:
        return ortho(-box * aspect, box * aspect, -box, box, -20.0, 20.0)
    return ortho(-box, box, -box / aspect, box / aspect, -20.0, 20.0)


def get_view_matrix(view_name):
    if view_name == "front":
        view = translate(0.0, 0.0, -8.0)
        view_pos = (0.0, 0.0, 8.0)
    elif view_name == "top":
        view = translate(0.0, 0.0, -8.0) @ rotate_x(90.0)
        view_pos = (0.0, 8.0, 0.0)
    else:
        view = translate(0.0, 0.0, -8.0) @ rotate_y(90.0)
        view_pos = (8.0, 0.0, 0.0)

    return view.astype(np.float32), view_pos


def draw_scene(view_name, vp_x, vp_y, vp_w, vp_h):
    glViewport(vp_x, vp_y, vp_w, vp_h)

    projection = get_projection_for_viewport(vp_w, vp_h)
    view, view_pos = get_view_matrix(view_name)
    apply_common_uniforms(view, projection, view_pos)

    floor_material = (
        (0.25, 0.25, 0.28),
        (0.45, 0.45, 0.50),
        (0.15, 0.15, 0.15),
        8.0,
    )

    main_material = (
        (0.75, 0.55, 0.35),
        (0.85, 0.55, 0.30),
        (0.95, 0.95, 0.95),
        64.0,
    )

    ref_material = (
        (0.55, 0.60, 0.75),
        (0.40, 0.65, 0.90),
        (0.90, 0.90, 0.90),
        32.0,
    )

    floor_model = identity()
    draw_object(vao_floor, floor_index_count, floor_model, False, floor_material)

    model = (
        translate(0.0, figure_y, 0.0)
        @ scale_matrix(scale, scale, scale)
        @ rotate_x(rot_x)
        @ rotate_y(rot_y)
    ).astype(np.float32)
    draw_object(vao_main, main_index_count, model, not wireframe, main_material)

    ref_model = (
        translate(2.2, -1.6, 0.0)
        @ scale_matrix(0.8, 0.8, 0.8)
    ).astype(np.float32)
    draw_object(vao_main, main_index_count, ref_model, False, ref_material)


def draw_separator_lines(w, h):
    x1 = 2.0 / 3.0 - 1.0
    x2 = 4.0 / 3.0 - 1.0

    line_vertices = np.array([
        x1, -1.0,
        x1,  1.0,
        x2, -1.0,
        x2,  1.0,
    ], dtype=np.float32)

    glUseProgram(line_shader_program)
    glUniform3f(line_uniforms["uLineColor"], 0.5, 0.5, 0.5)

    glBindVertexArray(vao_lines)
    glBindBuffer(GL_ARRAY_BUFFER, vbo_lines)
    glBufferSubData(GL_ARRAY_BUFFER, 0, line_vertices.nbytes, line_vertices)

    glDisable(GL_DEPTH_TEST)
    glViewport(0, 0, w, h)
    glDrawArrays(GL_LINES, 0, 4)
    glEnable(GL_DEPTH_TEST)

    glBindVertexArray(0)


def render(window):
    w, h = glfw.get_framebuffer_size(window)
    third = w // 3

    update_animation()

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE if wireframe else GL_FILL)

    draw_scene("front", 0, 0, third, h)
    draw_scene("top", third, 0, third, h)
    draw_scene("side", third * 2, 0, w - third * 2, h)

    draw_separator_lines(w, h)



# input

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



# initializaciya

def init_opengl():
    global shader_program, line_shader_program
    global vao_main, vbo_main, ebo_main, main_index_count
    global vao_floor, vbo_floor, ebo_floor, floor_index_count
    global vao_lines, vbo_lines

    shader_program = build_shader_program()
    line_shader_program = build_line_shader_program()

    vertices, indices = create_conical_cylinder_geometry()
    vao_main, vbo_main, ebo_main = create_vao(vertices, indices)
    main_index_count = len(indices)

    floor_vertices, floor_indices = create_floor_geometry()
    vao_floor, vbo_floor, ebo_floor = create_vao(floor_vertices, floor_indices)
    floor_index_count = len(floor_indices)

    vao_lines, vbo_lines = create_line_vao()

    fetch_uniform_locations()
    fetch_line_uniform_locations()

    create_checker_texture()

    glEnable(GL_DEPTH_TEST)
    glClearColor(0.08, 0.08, 0.12, 1.0)



def main():
    global last_time

    if not glfw.init():
        return

    glfw.window_hint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.window_hint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.window_hint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.window_hint(glfw.OPENGL_FORWARD_COMPAT, GL_TRUE)  # macOS

    window = glfw.create_window(window_width, window_height, "ЛАБ8", None, None)
    if not window:
        glfw.terminate()
        return

    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)

    init_opengl()
    last_time = glfw.get_time()

    while not glfw.window_should_close(window):
        render(window)
        glfw.swap_buffers(window)
        glfw.poll_events()

    glfw.terminate()


if __name__ == "__main__":
    main()