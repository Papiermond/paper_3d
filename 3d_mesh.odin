package paper_3d

import gl "vendor:OpenGL"

create_mesh :: proc(vertices: []Vertex3D, indices: []u32) -> Mesh {
    mesh: Mesh
    mesh.vertex_count = i32(len(vertices))
    mesh.index_count = i32(len(indices))

    gl.GenVertexArrays(1, &mesh.vao)
    gl.GenBuffers(1, &mesh.vbo)
    gl.GenBuffers(1, &mesh.ebo)

    gl.BindVertexArray(mesh.vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(Vertex3D), raw_data(vertices), gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(u32), raw_data(indices), gl.STATIC_DRAW)

    stride := i32(size_of(Vertex3D))

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, stride, offset_of(Vertex3D, pos))

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, stride, offset_of(Vertex3D, normal))

    gl.EnableVertexAttribArray(2)
	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, stride, offset_of(Vertex3D, uv))
	
	gl.EnableVertexAttribArray(3)
	gl.VertexAttribPointer(3, 4, gl.FLOAT, gl.FALSE, stride, offset_of(Vertex3D, color))
	
    gl.BindVertexArray(0)
	return mesh
}

destroy_mesh :: proc(mesh: ^Mesh) {
    if mesh.vao != 0 {
        gl.DeleteVertexArrays(1, &mesh.vao)
        mesh.vao = 0
    }
    
    if mesh.vbo != 0 {
        gl.DeleteBuffers(1, &mesh.vbo)
        mesh.vbo = 0
    }

    if mesh.ebo != 0 {
        gl.DeleteBuffers(1, &mesh.ebo)
        mesh.ebo = 0
    }

    mesh.vertex_count = 0
    mesh.index_count = 0
}