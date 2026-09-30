package paper_3d

import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"

Shader3D_Vertex :: `
#version 330 core

layout (location = 0) in vec3 a_pos;
layout (location = 1) in vec3 a_normal;
layout (location = 2) in vec2 a_uv;
layout (location = 3) in vec4 a_color;

uniform mat4 u_model;
uniform mat4 u_view;
uniform mat4 u_projection;

out vec3 v_normal;
out vec3 v_frag_pos;
out vec2 v_uv;
out vec4 v_color;

void main() {
    vec4 world_pos = u_model * vec4(a_pos, 1.0);
    v_frag_pos = world_pos.xyz;
    v_normal = mat3(u_model) * a_normal;
    v_uv = a_uv;
    v_color = a_color;
    gl_Position = u_projection * u_view * world_pos;
}
`

Shader3D_Fragment :: `
#version 330 core
in vec3 v_normal;
in vec3 v_frag_pos;
in vec2 v_uv;
in vec4 v_color;

out vec4 FragColor;

uniform sampler2D u_texture;
uniform int u_use_texture;
uniform vec3 u_light_dir;
uniform vec3 u_light_color;
uniform vec3 u_ambient_color;

void main() {
    vec3 norm = normalize(v_normal);
    float diff = max(dot(norm, u_light_dir), 0.0);
    vec3 diffuse = diff * u_light_color;
    vec3 lighting = u_ambient_color + diffuse;

    vec4 base_color = v_color;
    if (u_use_texture == 1) {
        base_color *= texture(u_texture, v_uv);
    }
    FragColor = vec4(lighting * base_color.rgb, base_color.a);
}
`
compile_shader :: proc(source: string, shader_type: u32) -> (u32, bool) {
    id:= gl.CreateShader(shader_type)
    c_str:= strings.clone_to_cstring(source, context.temp_allocator)
    gl.ShaderSource(id, 1, &c_str, nil)
    gl.CompileShader(id)

    status: i32
    gl.GetShaderiv(id, gl.COMPILE_STATUS, &status)
    if status == 0 {
        log_buf: [512]u8
        gl.GetShaderInfoLog(id, 512, nil, raw_data(log_buf[:]))
        fmt.eprintfln("3D Shader compile error: %s", string(log_buf[:]))
        gl.DeleteShader(id)
        return 0, false
    }
    return id, true
}

create_shader_program :: proc(vs_src, fs_src: string) -> (u32, bool) {
    vs, vs_ok := compile_shader(vs_src, gl.VERTEX_SHADER)
    if !vs_ok do return 0, false
    defer gl.DeleteShader(vs)

    fs, fs_ok := compile_shader(fs_src, gl.FRAGMENT_SHADER)
    if !fs_ok do return 0, false
    defer gl.DeleteShader(fs)

    prog := gl.CreateProgram()
    gl.AttachShader(prog, vs)
    gl.AttachShader(prog, fs)
    gl.LinkProgram(prog)

    status: i32
    gl.GetProgramiv(prog, gl.LINK_STATUS, &status)
    if status == 0 {
        log_buf: [512]u8
        gl.GetProgramInfoLog(prog, 512, nil, raw_data(log_buf[:]))
        fmt.eprintfln("3D Program link error: %s", string(log_buf[:]))
        gl.DeleteProgram(prog)
        return 0, false
    }
    return prog, true
}
