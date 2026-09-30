package paper_3d

import gfx "../paper_gfx"
import "core:fmt"
import "core:math"
import "core:math/linalg/glsl"
import gl "vendor:OpenGL"

init_3d :: proc() -> bool {
	if global_renderer_3d.is_initialized do return true

	prog, ok := create_shader_program(Shader3D_Vertex, Shader3D_Fragment)
	if !ok {
		fmt.eprintfln("Failed to create 3D default shader program")
		return false
	}
	global_renderer_3d.shader_id = prog

	global_renderer_3d.u_model_loc = gl.GetUniformLocation(prog, "u_model")
	global_renderer_3d.u_view_loc = gl.GetUniformLocation(prog, "u_view")
	global_renderer_3d.u_proj_loc = gl.GetUniformLocation(prog, "u_projection")
	global_renderer_3d.u_light_dir_loc = gl.GetUniformLocation(prog, "u_light_dir")
	global_renderer_3d.u_light_col_loc = gl.GetUniformLocation(prog, "u_light_color")
	global_renderer_3d.u_ambient_col_loc = gl.GetUniformLocation(prog, "u_ambient_color")
	global_renderer_3d.u_use_tex_loc = gl.GetUniformLocation(prog, "u_use_texture")
	global_renderer_3d.u_texture_loc = gl.GetUniformLocation(prog, "u_texture")

	gl.UseProgram(prog)
	if global_renderer_3d.u_texture_loc != -1 {
		gl.Uniform1i(global_renderer_3d.u_texture_loc, 0)
	}

	global_renderer_3d.default_cube = gen_cube_mesh({1, 1, 1})
	global_renderer_3d.default_sphere = gen_sphere_mesh(1)
	global_renderer_3d.default_plane = gen_plane_mesh(1, 1)
	global_renderer_3d.default_cylinder = gen_cylinder_mesh(1, 1)
	global_renderer_3d.is_initialized = true
	return true
}

clean_up_3d :: proc() {
	if !global_renderer_3d.is_initialized do return

	destroy_mesh(&global_renderer_3d.default_cube)
	destroy_mesh(&global_renderer_3d.default_plane)
	destroy_mesh(&global_renderer_3d.default_sphere)
	destroy_mesh(&global_renderer_3d.default_cylinder)
	gl.DeleteProgram(global_renderer_3d.shader_id)
	global_renderer_3d.is_initialized = false
}

begin_mode_3d :: proc(cam: Camera3D, aspect_ratio: f32) {
	if !global_renderer_3d.is_initialized {
		init_3d()
	}

	gl.Enable(gl.DEPTH_TEST)
	gl.DepthFunc(gl.LESS)
	gl.Enable(gl.CULL_FACE)
	gl.CullFace(gl.BACK)
	gl.FrontFace(gl.CCW)
	gl.Viewport(0, 0, gfx.global_renderer.screen_width, gfx.global_renderer.screen_height)

	gl.UseProgram(global_renderer_3d.shader_id)

	view := glsl.mat4LookAt(cam.position, cam.target, cam.up)
	gl.UniformMatrix4fv(global_renderer_3d.u_view_loc, 1, false, &view[0, 0])

	proj: matrix[4, 4]f32
	switch cam.projection {
	case .Perspective:
		fovy_rad := math.to_radians(cam.fovy)
		proj = glsl.mat4Perspective(fovy_rad, aspect_ratio, 0.1, 1000.0)
	case .Orthographic:
		half_h := cam.fovy * 0.5
		half_w := half_h * aspect_ratio
		proj = glsl.mat4Ortho3d(-half_w, half_w, -half_h, half_h, 0.1, 1000.0)
	}
	gl.UniformMatrix4fv(global_renderer_3d.u_proj_loc, 1, false, &proj[0, 0])

	light_dir := glsl.normalize([3]f32{0.5, 1.0, 0.3})
	gl.Uniform3f(global_renderer_3d.u_light_dir_loc, light_dir.x, light_dir.y, light_dir.z)
	gl.Uniform3f(global_renderer_3d.u_light_col_loc, 0.9, 0.9, 0.9)
	gl.Uniform3f(global_renderer_3d.u_ambient_col_loc, 0.25, 0.25, 0.28)
}

end_mode_3d :: proc() {
	gl.Disable(gl.DEPTH_TEST)
	gl.Disable(gl.CULL_FACE)
}

clear_3d_background :: proc(r, g, b, a: f32) {
	gl.ClearColor(r, g, b, a)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

draw_mesh :: proc(mesh: Mesh, model_matrix: matrix[4, 4]f32, texture_id: u32 = 0) {
	if mesh.vao == 0 do return

	gl.UseProgram(global_renderer_3d.shader_id)
	m := model_matrix
	gl.UniformMatrix4fv(global_renderer_3d.u_model_loc, 1, false, &m[0, 0])

	if texture_id != 0 {
		gl.Uniform1i(global_renderer_3d.u_use_tex_loc, 1)
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, texture_id)
	} else {
		gl.Uniform1i(global_renderer_3d.u_use_tex_loc, 0)
	}

	gl.BindVertexArray(mesh.vao)
	gl.DrawElements(gl.TRIANGLES, mesh.index_count, gl.UNSIGNED_INT, nil)
	gl.BindVertexArray(0)
}

draw_cube :: proc(pos, size: [3]f32, rot_axis: [3]f32 = {0, 1, 0}, rot_angle_deg: f32 = 0, texture_id: u32 = 0) {
	t := glsl.mat4Translate(pos)
	r := glsl.mat4Rotate(rot_axis, math.to_radians(rot_angle_deg))
	s := glsl.mat4Scale(size)
	model := t * r * s
	draw_mesh(global_renderer_3d.default_cube, model, texture_id)
}

draw_plane :: proc(pos: [3]f32, size: [2]f32, texture_id: u32 = 0) {
	t := glsl.mat4Translate(pos)
	s := glsl.mat4Scale({size.x, 1, size.y})
	draw_mesh(global_renderer_3d.default_plane, t * s, texture_id)
}

draw_sphere :: proc(pos: [3]f32, radius: f32, texture_id: u32 = 0) {
	t := glsl.mat4Translate(pos)
	s := glsl.mat4Scale({radius, radius, radius})
	draw_mesh(global_renderer_3d.default_sphere, t * s, texture_id)
}

draw_cylinder :: proc(pos: [3]f32, radius, height: f32, texture_id: u32 = 0) {
	t := glsl.mat4Translate(pos)
	s := glsl.mat4Scale({radius, height, radius})
	draw_mesh(global_renderer_3d.default_cylinder, t * s, texture_id)
}

main :: proc() {
	if !gfx.init_window(1280, 720, "Paper 3D Test") {
		return
	}
	defer gfx.close_window()
	init_3d()
	defer clean_up_3d()

	cam := Camera3D {
		position   = {0.0, 3.0, 5.0},
		target     = {0.0, 0.0, 0.0},
		up         = {0.0, 1.0, 0.0},
		fovy       = 45.0,
		projection = .Perspective,
	}

	aspect := f32(gfx.global_renderer.screen_width) / f32(gfx.global_renderer.screen_height)
	for !gfx.window_should_close() {
		gfx.begin_drawing()
		clear_3d_background(0.1, 0.1, 0.15, 1.0)
		begin_mode_3d(cam, aspect)
		draw_plane(pos = {0, -1, 0}, size = {10, 10})
		rot := f32(gfx.get_time() * 50.0)
		draw_cube(pos = {-2, 0, 0}, size = {1.2, 1.2, 1.2}, rot_axis = {0.0, 1.0, 0.0}, rot_angle_deg = rot)
		draw_sphere(pos = {0, 0, 0}, radius = 0.8)
		draw_cylinder(pos = {2, 0, 0}, radius = 0.6, height = 1.5)
		end_mode_3d()
		gfx.end_drawing()
	}
}
