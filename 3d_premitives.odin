package paper_3d

import gl "vendor:OpenGL"

gen_cube_mesh :: proc(size: [3]f32, col: [4]f32 = {1, 1, 1, 1}) -> Mesh {
	hx := size.x * 0.5
	hy := size.y * 0.5
	hz := size.z * 0.5

	vertices := [24]Vertex3D {
		{pos = {-hx, -hy, hz}, normal = {0, 0, 1}, uv = {0, 0}, color = col},
		{pos = {hx, -hy, hz}, normal = {0, 0, 1}, uv = {1, 0}, color = col},
		{pos = {hx, hy, hz}, normal = {0, 0, 1}, uv = {1, 1}, color = col},
		{pos = {-hx, hy, hz}, normal = {0, 0, 1}, uv = {0, 1}, color = col},
		{pos = {hx, -hy, -hz}, normal = {0, 0, -1}, uv = {0, 0}, color = col},
		{pos = {-hx, -hy, -hz}, normal = {0, 0, -1}, uv = {1, 0}, color = col},
		{pos = {-hx, hy, -hz}, normal = {0, 0, -1}, uv = {1, 1}, color = col},
		{pos = {hx, hy, -hz}, normal = {0, 0, -1}, uv = {0, 1}, color = col},
		{pos = {-hx, hy, hz}, normal = {0, 1, 0}, uv = {0, 0}, color = col},
		{pos = {hx, hy, hz}, normal = {0, 1, 0}, uv = {1, 0}, color = col},
		{pos = {hx, hy, -hz}, normal = {0, 1, 0}, uv = {1, 1}, color = col},
		{pos = {-hx, hy, -hz}, normal = {0, 1, 0}, uv = {0, 1}, color = col},
		{pos = {-hx, -hy, -hz}, normal = {0, -1, 0}, uv = {0, 0}, color = col},
		{pos = {hx, -hy, -hz}, normal = {0, -1, 0}, uv = {1, 0}, color = col},
		{pos = {hx, -hy, hz}, normal = {0, -1, 0}, uv = {1, 1}, color = col},
		{pos = {-hx, -hy, hz}, normal = {0, -1, 0}, uv = {0, 1}, color = col},
		{pos = {hx, -hy, hz}, normal = {1, 0, 0}, uv = {0, 0}, color = col},
		{pos = {hx, -hy, -hz}, normal = {1, 0, 0}, uv = {1, 0}, color = col},
		{pos = {hx, hy, -hz}, normal = {1, 0, 0}, uv = {1, 1}, color = col},
		{pos = {hx, hy, hz}, normal = {1, 0, 0}, uv = {0, 1}, color = col},
		{pos = {-hx, -hy, -hz}, normal = {-1, 0, 0}, uv = {0, 0}, color = col},
		{pos = {-hx, -hy, hz}, normal = {-1, 0, 0}, uv = {1, 0}, color = col},
		{pos = {-hx, hy, hz}, normal = {-1, 0, 0}, uv = {1, 1}, color = col},
		{pos = {-hx, hy, -hz}, normal = {-1, 0, 0}, uv = {0, 1}, color = col},
	}

	indices := [36]u32 {
		0,
		1,
		2,
		2,
		3,
		0, // Front
		4,
		5,
		6,
		6,
		7,
		4, // Back
		8,
		9,
		10,
		10,
		11,
		8, // Top
		12,
		13,
		14,
		14,
		15,
		12, // Bottom
		16,
		17,
		18,
		18,
		19,
		16, // Right
		20,
		21,
		22,
		22,
		23,
		20, // Left
	}

	return create_mesh(vertices[:], indices[:])
}

import "core:math"
import "core:math/linalg/glsl"

// --- Plane / Quad (XZ Ground Plane) ---
// width = X axis size, length = Z axis size.
// res_x & res_z can be > 1 if you need subdivision (e.g. terrain or water).
gen_plane_mesh :: proc(width, length: f32, res_x: int = 1, res_z: int = 1, col: [4]f32 = {1, 1, 1, 1}) -> Mesh {
	vertices := make([dynamic]Vertex3D, context.temp_allocator)
	indices := make([dynamic]u32, context.temp_allocator)

	hw := width * 0.5
	hl := length * 0.5

	for z in 0 ..= res_z {
		fz := f32(z) / f32(res_z)
		pos_z := hl - fz * length
		for x in 0 ..= res_x {
			fx := f32(x) / f32(res_x)
			pos_x := -hw + fx * width
			append(&vertices, Vertex3D{pos = {pos_x, 0, pos_z}, normal = {0, 1, 0}, uv = {fx, fz}, color = col})
		}
	}

	stride := u32(res_x + 1)
	for z in 0 ..< res_z {
		for x in 0 ..< res_x {
			row1 := u32(z) * stride + u32(x)
			row2 := u32(z + 1) * stride + u32(x)

			append(&indices, row1, row1 + 1, row2 + 1)
			append(&indices, row2 + 1, row2, row1)
		}
	}

	return create_mesh(vertices[:], indices[:])
}

// --- UV Sphere (Fixed CCW Outward Winding) ---
gen_sphere_mesh :: proc(radius: f32, rings: int = 16, sectors: int = 32, col: [4]f32 = {1, 1, 1, 1}) -> Mesh {
	vertices := make([dynamic]Vertex3D, context.temp_allocator)
	indices := make([dynamic]u32, context.temp_allocator)

	for r in 0 ..= rings {
		phi := math.PI * f32(r) / f32(rings)
		sin_phi := math.sin(phi)
		cos_phi := math.cos(phi)

		for s in 0 ..= sectors {
			theta := 2.0 * math.PI * f32(s) / f32(sectors)
			sin_theta := math.sin(theta)
			cos_theta := math.cos(theta)

			n := glsl.normalize([3]f32{cos_theta * sin_phi, cos_phi, sin_theta * sin_phi})
			p := n * radius
			uv := [2]f32{f32(s) / f32(sectors), f32(r) / f32(rings)}

			append(&vertices, Vertex3D{pos = p, normal = n, uv = uv, color = col})
		}
	}

	stride := u32(sectors + 1)
	for r in 0 ..< rings {
		for s in 0 ..< sectors {
			first := u32(r) * stride + u32(s)
			second := first + stride

			// Winding reversed to face outward:
			append(&indices, first, first + 1, second)
			append(&indices, second, first + 1, second + 1)
		}
	}

	return create_mesh(vertices[:], indices[:])
}

// --- Cylinder (Fixed CCW Winding) ---
gen_cylinder_mesh :: proc(radius, height: f32, segments: int = 24, col: [4]f32 = {1, 1, 1, 1}) -> Mesh {
	vertices := make([dynamic]Vertex3D, context.temp_allocator)
	indices := make([dynamic]u32, context.temp_allocator)

	half_h := height * 0.5

	// 1. Side wall vertices
	for i in 0 ..= segments {
		theta := 2.0 * math.PI * f32(i) / f32(segments)
		c := math.cos(theta)
		s := math.sin(theta)
		u := f32(i) / f32(segments)

		norm := [3]f32{c, 0, s}
		append(&vertices, Vertex3D{pos = {radius * c, -half_h, radius * s}, normal = norm, uv = {u, 0}, color = col})
		append(&vertices, Vertex3D{pos = {radius * c, half_h, radius * s}, normal = norm, uv = {u, 1}, color = col})
	}

	// 1. Side wall indices (CCW facing outward)
	for i in 0 ..< segments {
		b1 := u32(i * 2)
		t1 := b1 + 1
		b2 := u32((i + 1) * 2)
		t2 := b2 + 1

		append(&indices, b1, t1, t2)
		append(&indices, b1, t2, b2)
	}

	// 2. Top cap (pointing +Y up)
	top_center_idx := u32(len(vertices))
	append(&vertices, Vertex3D{pos = {0, half_h, 0}, normal = {0, 1, 0}, uv = {0.5, 0.5}, color = col})
	for i in 0 ..= segments {
		theta := 2.0 * math.PI * f32(i) / f32(segments)
		c := math.cos(theta)
		s := math.sin(theta)
		u := 0.5 + 0.5 * c
		v := 0.5 + 0.5 * s
		append(&vertices, Vertex3D{pos = {radius * c, half_h, radius * s}, normal = {0, 1, 0}, uv = {u, v}, color = col})
	}
	for i in 0 ..< segments {
		idx1 := top_center_idx + 1 + u32(i)
		idx2 := top_center_idx + 1 + u32(i + 1)
		append(&indices, top_center_idx, idx2, idx1)
	}

	// 3. Bottom cap (pointing -Y down)
	bot_center_idx := u32(len(vertices))
	append(&vertices, Vertex3D{pos = {0, -half_h, 0}, normal = {0, -1, 0}, uv = {0.5, 0.5}, color = col})
	for i in 0 ..= segments {
		theta := 2.0 * math.PI * f32(i) / f32(segments)
		c := math.cos(theta)
		s := math.sin(theta)
		u := 0.5 + 0.5 * c
		v := 0.5 + 0.5 * s
		append(&vertices, Vertex3D{pos = {radius * c, -half_h, radius * s}, normal = {0, -1, 0}, uv = {u, v}, color = col})
	}
	for i in 0 ..< segments {
		idx1 := bot_center_idx + 1 + u32(i)
		idx2 := bot_center_idx + 1 + u32(i + 1)
		append(&indices, bot_center_idx, idx1, idx2)
	}

	return create_mesh(vertices[:], indices[:])
}

// --- Cone (Fixed CCW Winding) ---
gen_cone_mesh :: proc(radius, height: f32, segments: int = 24, col: [4]f32 = {1, 1, 1, 1}) -> Mesh {
	vertices := make([dynamic]Vertex3D, context.temp_allocator)
	indices := make([dynamic]u32, context.temp_allocator)

	half_h := height * 0.5
	apex_pos := [3]f32{0, half_h, 0}

	// 1. Slanted side triangles (CCW facing outward)
	for i in 0 ..< segments {
		th1 := 2.0 * math.PI * f32(i) / f32(segments)
		th2 := 2.0 * math.PI * f32(i + 1) / f32(segments)

		c1, s1 := math.cos(th1), math.sin(th1)
		c2, s2 := math.cos(th2), math.sin(th2)

		p1 := [3]f32{radius * c1, -half_h, radius * s1}
		p2 := [3]f32{radius * c2, -half_h, radius * s2}

		n1 := glsl.normalize([3]f32{c1 * height, radius, s1 * height})
		n2 := glsl.normalize([3]f32{c2 * height, radius, s2 * height})
		n_apex := glsl.normalize([3]f32{(c1 + c2) * 0.5 * height, radius, (s1 + s2) * 0.5 * height})

		start := u32(len(vertices))
		append(&vertices, Vertex3D{pos = apex_pos, normal = n_apex, uv = {0.5, 1}, color = col})
		append(&vertices, Vertex3D{pos = p1, normal = n1, uv = {f32(i) / f32(segments), 0}, color = col})
		append(&vertices, Vertex3D{pos = p2, normal = n2, uv = {f32(i + 1) / f32(segments), 0}, color = col})

		append(&indices, start, start + 2, start + 1)
	}

	// 2. Base cap (pointing -Y down)
	bot_center_idx := u32(len(vertices))
	append(&vertices, Vertex3D{pos = {0, -half_h, 0}, normal = {0, -1, 0}, uv = {0.5, 0.5}, color = col})
	for i in 0 ..= segments {
		theta := 2.0 * math.PI * f32(i) / f32(segments)
		c := math.cos(theta)
		s := math.sin(theta)
		append(&vertices, Vertex3D{pos = {radius * c, -half_h, radius * s}, normal = {0, -1, 0}, uv = {0.5 + 0.5 * c, 0.5 + 0.5 * s}, color = col})
	}
	for i in 0 ..< segments {
		idx1 := bot_center_idx + 1 + u32(i)
		idx2 := bot_center_idx + 1 + u32(i + 1)
		append(&indices, bot_center_idx, idx1, idx2)
	}

	return create_mesh(vertices[:], indices[:])
}
