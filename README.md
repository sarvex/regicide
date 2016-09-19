# Regicide

Multiplayer Action Strategy Game

Implemented in [Zig](http://ziglang.org/).

## Building and Running

 0. Install the dependencies.
 0. On Linux, `zig build src/main.zig --name regicide --export exe --library c --library m --library glfw --library epoxy`
 0. On MacOS, `zig build src/main.zig --name regicide --export exe --library c --library m --library glfw3 --library epoxy -isystem /nix/store/i2s4i9475q0p27wbqhc5mhmfy87xpcwr-user-environment/include/ -isystem ~/local/include/ --library-path /nix/store/i2s4i9475q0p27wbqhc5mhmfy87xpcwr-user-environment/lib --library-path ~/local/lib -mmacosx-version-min 10.11 -framework CoreFoundation -framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo`
 0. `./tetris`

MacOS support and build instructions coming soon.
