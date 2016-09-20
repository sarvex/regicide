# Regicide

Multiplayer Action Strategy Game

Implemented in [Zig](http://ziglang.org/).

## Building and Running

 0. Install the dependencies.
 0. On Linux, `zig build src/main.zig --name regicide --export exe --library c --library m --library glfw --library epoxy`
 0. On MacOS, `zig build src/main.zig --name regicide --export exe --library c --library m --library glfw3 --library epoxy -mmacosx-version-min 10.11 -framework CoreFoundation -framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo`
 0. `./tetris`

MacOS support and build instructions coming soon.
