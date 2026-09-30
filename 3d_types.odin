package paper_3d

Camera3D :: struct {
	position: 	[3]f32,
	target: 	[3]f32,
	up:		[3]f32,
	fovy:		f32,
	projection:	enum{Perspective, Orthographic },
}

Vertex3D :: struct {
	pos: 	[3]f32,
	normal: [3]f32,
	uv: 	[2]f32,
	color: 	[4]f32, 
}

Mesh :: struct {
	vao, vbo, ebo: 	u32,
	vertex_count: 	i32,
	index_count: 	i32,
}

Renderer3D :: struct {
	shader_id: 			u32,
	u_model_loc: 		i32,
	u_view_loc:			i32,
	u_proj_loc: 		i32,
	u_light_dir_loc:	i32,
	u_light_col_loc:	i32,
	u_ambient_col_loc: 	i32,
	u_use_tex_loc: 	i32,
	u_texture_loc: 		i32,
	default_cube: 		Mesh,
	default_plane: 		Mesh,
	default_sphere: 	Mesh,
	default_cylinder: 	Mesh,
	is_initialized: 	bool,
}
global_renderer_3d: Renderer3D