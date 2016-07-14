const std = @import("std");
const c = @import("c.zig");
const debug_gl = @import("debug_gl.zig");

struct KillerQueen {
    window: &c.GLFWwindow,
    framebuffer_width: c_int,
    framebuffer_height: c_int,
}

extern fn error_callback(err: c_int, description: ?&const u8) {
    c.fprintf(c.stderr, c"Error: %s\n", description);
    c.abort();
}

extern fn key_callback(window: ?&c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) {
    if (action != c.GLFW_PRESS) return;
    const t = (&KillerQueen)(??c.glfwGetWindowUserPointer(window));

    switch (key) {
        c.GLFW_KEY_ESCAPE => c.glfwSetWindowShouldClose(window, c.GL_TRUE),
        else => {},
    }
}

var kq: KillerQueen = undefined;

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


    const window_width = 800;
    const window_height = 600;
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


    c.glfwGetFramebufferSize(window, &kq.framebuffer_width, &kq.framebuffer_height);

    c.glClearColor(0.0, 0.0, 0.0, 1.0);
    c.glEnable(c.GL_BLEND);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
    c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 1);

    c.glViewport(0, 0, kq.framebuffer_width, kq.framebuffer_height);
    c.glfwSetWindowUserPointer(window, (&c_void)(&kq));

    debug_gl.assert_no_err();

    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        c.glClear(c.GL_COLOR_BUFFER_BIT|c.GL_DEPTH_BUFFER_BIT|c.GL_STENCIL_BUFFER_BIT);

        c.glfwSwapBuffers(window);

        c.glfwPollEvents();
    }

    debug_gl.assert_no_err();

    return 0;
}
