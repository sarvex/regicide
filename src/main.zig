const std = @import("std");
const c = @import("c.zig");
const debug_gl = @import("debug_gl.zig");
const all_shaders = @import("all_shaders.zig");
const math3d = @import("math3d.zig");
const Vec2 = math3d.Vec2;
const Vec3 = math3d.Vec3;
const Vec4 = math3d.Vec4;
const Mat4x4 = math3d.Mat4x4;
const static_geometry = @import("static_geometry.zig");

struct Platform {
    left: f32,
    top: f32,
    width: f32,
    height: f32,
    corner_radius: f32,
}

struct KqMap {
    name: []u8,
    bg_top_color: Vec4,
    bg_bottom_color: Vec4,
    platforms: []Platform,
}

const default_corner_radius = 4.0;
const debug_draw_platforms = !@compileVar("is_release");
const debug_platform_color = math3d.vec4(96.0/255.0, 71.0/255.0, 0.0/255.0, 1.0);
const debug_player_color = math3d.vec4(249.0/255.0, 178.0/255.0, 102.0/255.0, 1.0);

enum PlayerKind {
    Worker,
    Warrior,
    Queen,
}

struct Player {
    kind: PlayerKind,
    pos: Vec2,
    size: Vec2,
    alive: bool,
}

// TODO initialize with enum values as array indexes
const player_kind_sizes = []Vec2 {
    math3d.vec2(20.0, 50.0),
    math3d.vec2(20.0, 50.0),
    math3d.vec2(20.0, 50.0),
};

// TODO 10
const player_count = 1;

const day_map = KqMap {
    .name = "Day Map",
    .bg_top_color = math3d.vec4(16.0/255.0, 149.0/255.0, 220.0/255.0, 1.0),
    .bg_bottom_color = math3d.vec4(97.0/255.0, 198.0/255.0, 217.0/255.0, 1.0),
    .platforms = []Platform {
        Platform {
            .left = 100.0,
            .top = 100.0,
            .width = 500.0,
            .height = 20.0,
            .corner_radius = default_corner_radius,
        },
        Platform {
            .left = 900.0,
            .top = 100.0,
            .width = 500.0,
            .height = 20.0,
            .corner_radius = default_corner_radius,
        },
        Platform {
            .left = 100.0,
            .top = 400.0,
            .width = 500.0,
            .height = 20.0,
            .corner_radius = default_corner_radius,
        },
        Platform {
            .left = 900.0,
            .top = 400.0,
            .width = 500.0,
            .height = 20.0,
            .corner_radius = default_corner_radius,
        },
    },
};

struct KillerQueen {
    window: &c.GLFWwindow,
    framebuffer_width: c_int,
    framebuffer_height: c_int,
    width: f32,
    height: f32,
    shaders: all_shaders.AllShaders,
    projection: Mat4x4,
    static_geometry: static_geometry.StaticGeometry,
    cur_map: KqMap,
    players: [player_count]Player,
}

extern fn error_callback(err: c_int, description: ?&const u8) {
    c.fprintf(c.stderr, c"Error: %s\n", description);
    c.abort();
}

extern fn key_callback(window: ?&c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) {
    if (action != c.GLFW_PRESS) return;
    const kq = (&KillerQueen)(??c.glfwGetWindowUserPointer(window));

    switch (key) {
        c.GLFW_KEY_ESCAPE => c.glfwSetWindowShouldClose(window, c.GL_TRUE),
        else => {},
    }
}

var kq_state: KillerQueen = undefined;

export fn main(argc: c_int, argv: &&u8) -> c_int {
    c.glfwSetErrorCallback(error_callback);

    if (c.glfwInit() == c.GL_FALSE) {
        c.fprintf(c.stderr, c"GLFW init failure\n");
        c.abort();
    }
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 2);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
    c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, debug_gl.is_on);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_DEPTH_BITS, 0);
    c.glfwWindowHint(c.GLFW_STENCIL_BITS, 8);
    c.glfwWindowHint(c.GLFW_RESIZABLE, c.GL_FALSE);


    const window_width = 1920;
    const window_height = 1080;
    const window = c.glfwCreateWindow(window_width, window_height, c"Killer Queen", null, null) ?? {
        c.fprintf(c.stderr, c"unable to create window\n");
        c.abort();
    };
    defer c.glfwDestroyWindow(window);

    c.glfwSetKeyCallback(window, key_callback);
    c.glfwMakeContextCurrent(window);
    c.glfwSwapInterval(1);

    // create and bind exactly one vertex array per context and use
    // glVertexAttribPointer etc every frame.
    var vertex_array_object: c.GLuint = undefined;
    c.glGenVertexArrays(1, &vertex_array_object);
    c.glBindVertexArray(vertex_array_object);
    defer c.glDeleteVertexArrays(1, &vertex_array_object);

    const kq = &kq_state;
    c.glfwGetFramebufferSize(window, &kq.framebuffer_width, &kq.framebuffer_height);
    kq.width = f32(kq.framebuffer_width);
    kq.height = f32(kq.framebuffer_height);

    c.glClearColor(0.0, 0.0, 0.0, 1.0);
    c.glEnable(c.GL_BLEND);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
    c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 1);

    c.glViewport(0, 0, kq.framebuffer_width, kq.framebuffer_height);
    c.glfwSetWindowUserPointer(window, (&c_void)(&kq));

    all_shaders.createAllShaders(&kq.shaders);
    defer kq.shaders.destroy();

    kq.static_geometry = static_geometry.createStaticGeometry();
    defer kq.static_geometry.destroy();

    resetProjection(kq);

    resetMap(kq, &day_map);

    debug_gl.assertNoError();

    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        c.glClear(c.GL_COLOR_BUFFER_BIT|c.GL_DEPTH_BUFFER_BIT|c.GL_STENCIL_BUFFER_BIT);

        fillGradient(kq, &kq.cur_map.bg_top_color, &kq.cur_map.bg_bottom_color, 0, 0, kq.width, kq.height);

        if (debug_draw_platforms) {
            for (kq.cur_map.platforms) |*platform| {
                fillRect(kq, &debug_platform_color, platform.left, platform.top, platform.width, platform.height);
            }
        }

        for (kq.players) |*player| {
            fillRect(kq, &debug_player_color, player.pos.x(), player.pos.y(), player.size.x(), player.size.y());
        }

        c.glfwSwapBuffers(window);

        c.glfwPollEvents();
    }

    debug_gl.assertNoError();

    return 0;
}

fn fillGradientMvp(kq: &KillerQueen, top_color: &const Vec4, bottom_color: &const Vec4, mvp: &const Mat4x4) {
    kq.shaders.gradient.bind();
    kq.shaders.gradient.setUniformVec4(kq.shaders.gradient_uniform_color_top, top_color);
    kq.shaders.gradient.setUniformVec4(kq.shaders.gradient_uniform_color_bottom, bottom_color);
    kq.shaders.gradient.setUniformMat4x4(kq.shaders.gradient_uniform_mvp, mvp);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, kq.static_geometry.rect_2d_vertex_buffer);
    c.glEnableVertexAttribArray(c.GLuint(kq.shaders.gradient_attrib_position));
    c.glVertexAttribPointer(c.GLuint(kq.shaders.gradient_attrib_position), 3, c.GL_FLOAT, c.GL_FALSE, 0, null);

    c.glDrawArrays(c.GL_TRIANGLE_STRIP, 0, 4);
}

fn fillGradient(kq: &KillerQueen, top_color: &const Vec4, bottom_color: &const Vec4,
    x: f32, y: f32, w: f32, h: f32)
{
    const model = math3d.mat4x4_identity.translate(x, y, 0.0).scale(w, h, 0.0);
    const mvp = kq.projection.mult(model);
    fillGradientMvp(kq, top_color, bottom_color, &mvp)
}

fn fillRect(kq: &KillerQueen, color: &const Vec4, x: f32, y: f32, w: f32, h: f32) {
    fillGradient(kq, color, color, x, y, w, h)
}

fn fillRectMvp(kq: &KillerQueen, color: &const Vec4, mvp: &const Mat4x4) {
    fillGradientMvp(kq, color, color, mvp)
}

fn resetProjection(kq: &KillerQueen) {
    kq.projection = math3d.mat4x4_ortho(0.0, kq.width, kq.height, 0.0);
}

fn resetMap(kq: &KillerQueen, map: &const KqMap) {
    kq.cur_map = *map;

    for (kq.players) |*player| {
        *player = Player {
            .alive = true,
            .kind = PlayerKind.Queen,
            .pos = math3d.vec2(200.0, 200.0),
            .size = player_kind_sizes[usize(player.kind)],
        };
    }
}
