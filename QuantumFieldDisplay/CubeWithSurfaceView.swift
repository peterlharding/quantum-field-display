//
//  CubeWithSurfaceView.swift
//  QuantumFieldDisplay
//
//  Created by Peter Harding on 26/11/2024.
//


import SwiftUI
import SceneKit
import Foundation


struct CubeWithSurfaceView: View {
    @State private var scene = SCNScene() // Manage the scene state
    @State private var lastDragValue: CGSize = .zero
    @State private var rotationX: CGFloat = 0
    @State private var rotationY: CGFloat = 0
    @State private var cubeSize: CGFloat = 1.0 // Cube size controlled by slider
    @State private var time: Double = 0.0
    @State private var uiColor = UIColor.red
    @State private var surfaceColor: UIColor = .red
    
    
    // -----------------------------------------------------------------------
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                SceneView(
                    scene: scene,
                    options: [.allowsCameraControl]
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let deltaX = value.translation.width - lastDragValue.width
                            let deltaY = value.translation.height - lastDragValue.height

                            rotationX += deltaY / 100 // Adjust sensitivity
                            rotationY += deltaX / 100

                            lastDragValue = value.translation
                            updateCubeRotation()
                        }
                        .onEnded { _ in
                            lastDragValue = .zero
                        }
                )
                .onAppear {
                    setupScene()
                }
            }

            // Slider for adjusting cube size
            VStack {
                Text("Cube Size: \(String(format: "%.2f", cubeSize))")
                Slider(value: $cubeSize, in: 0.5...3.0, step: 0.1) // Adjust range and step size
                    .padding()
                    .onChange(of: cubeSize) { _, _ in
                        updateCubeSize()
                    }
            }
            .padding()
        }
    }

    // -----------------------------------------------------------------------
    
    func setupScene() {
        // Create wireframe cube
        let cubeNode = createWireframeCube(size: cubeSize)
        // let cubeNode = createDottedWireframeCube(size: 1.0, segmentCount: 20)

        cubeNode.name = "Cube"

        // Add cube to the scene
        scene.rootNode.addChildNode(cubeNode)

        // Add a surface inside the cube
        // let surfaceNode = createSurface(size: cubeSize)
        let surfaceNode = createAmorphousSurfaceWithPerlinNoise(size: cubeSize) // createAmorphousSurface(size: cubeSize)
        surfaceNode.name = "Surface"
        scene.rootNode.addChildNode(surfaceNode)

        
        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
        scene.rootNode.addChildNode(cameraNode)

        // Light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 5, y: 5, z: 5)
        scene.rootNode.addChildNode(lightNode)
        
        // Start the timer for dynamic surface updates
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            self.time += 0.05
            self.updateDynamicSurface()
        }
    }

    // -----------------------------------------------------------------------
    
    func updateDynamicSurface() {
        guard let surfaceNode = scene.rootNode.childNode(withName: "Surface", recursively: true) else {
            return
        }
        
        // Create a new geometry with updated y-values
        let newGeometry = createDynamicSurfaceGeometry(size: cubeSize, time: time)
        surfaceNode.geometry = newGeometry
    }
  
    // -----------------------------------------------------------------------

    func calculateNormals(vertices: [SCNVector3], indices: [Int32]) -> [SCNVector3] {
        var normals = Array(repeating: SCNVector3(0, 0, 0), count: vertices.count)
        
        for i in stride(from: 0, to: indices.count, by: 3) {
            let index1 = Int(indices[i])
            let index2 = Int(indices[i + 1])
            let index3 = Int(indices[i + 2])
            
            let v1 = vertices[index1]
            let v2 = vertices[index2]
            let v3 = vertices[index3]
            
            // Calculate normal for the triangle
            let edge1 = v2 - v1
            let edge2 = v3 - v1
            let normal = edge1.cross(edge2).normalized()
            
            // Add this normal to each vertex of the triangle
            normals[index1] = normals[index1] + normal
            normals[index2] = normals[index2] + normal
            normals[index3] = normals[index3] + normal
            
            // or if you add the += to the extension below...
            //
            //            normals[index1] += normal
            //            normals[index2] += normal
            //            normals[index3] += normal
        }
        
        // Normalize all vertex normals
        return normals.map { $0.normalized() }
    }


    // -----------------------------------------------------------------------
    
    func createDynamicSurfaceGeometry(size: CGFloat, time: Double) -> SCNGeometry {
        let halfSize = size / 2
        let perlin = PerlinNoise(seed: 42)
        
        // Create a grid for the surface
        let rows = 50
        let columns = 50
        var vertices: [SCNVector3] = []
        var indices: [Int32] = []
        var colors: [SCNVector4] = [] // For per-vertex colors

        let minAmplitude: CGFloat = -0.5
        let maxAmplitude: CGFloat = 0.5

        for row in 0...rows {
            for column in 0...columns {
                let x = -halfSize + (CGFloat(column) / CGFloat(columns)) * size
                let z = -halfSize + (CGFloat(row) / CGFloat(rows)) * size
                
                // Dynamically adjust y-values using Perlin noise and time
                let frequency: Double = 1.5
                let amplitude: Double = 0.5
                let y = perlin.noise(x: Double(x) * frequency, y: Double(z) * frequency + time) * amplitude
                
                vertices.append(SCNVector3(x, CGFloat(y), z))
                
                // Map the y-value to a color gradient
                let normalizedY = (CGFloat(y) - minAmplitude) / (maxAmplitude - minAmplitude)
                let color = gradientColor(for: normalizedY) // Get the color for the vertex
                colors.append(color) // Add the color to the array
            }
        }
        
        for row in 0..<rows {
            for column in 0..<columns {
                let topLeft = row * (columns + 1) + column
                let topRight = topLeft + 1
                let bottomLeft = topLeft + (columns + 1)
                let bottomRight = bottomLeft + 1
                
                indices.append(contentsOf: [
                    Int32(topLeft), Int32(bottomLeft), Int32(topRight),
                    Int32(topRight), Int32(bottomLeft), Int32(bottomRight)
                ])
            }
        }
        
        // Convert colors to Data for SCNGeometrySource
        let colorData = colors.flatMap { color in
            [Float(color.x), Float(color.y), Float(color.z), Float(color.w)]
        }.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }

        
        let normals = calculateNormals(vertices: vertices, indices: indices)
        let normalSource = SCNGeometrySource(normals: normals)

        let vertexSource = SCNGeometrySource(vertices: vertices)
        
        let colorSource = SCNGeometrySource(
            data: colorData,
            semantic: .color,
            vectorCount: colors.count,
            usesFloatComponents: true,
            componentsPerVector: 4, // RGBA
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<Float>.size * 4
        )
        
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        
        
        let geometry = SCNGeometry(sources: [vertexSource, colorSource, normalSource], elements: [element])
        
        geometry.firstMaterial?.diffuse.contents = uiColor.withAlphaComponent(0.6) // Surface color
        geometry.firstMaterial?.isDoubleSided = true
        geometry.firstMaterial?.diffuse.contents = UIColor.white // Diffuse is unused with vertex colors

        geometry.firstMaterial?.isLitPerPixel = true // Enable per-pixel lighting for smoother shading
        geometry.firstMaterial?.shininess = 0.1     // Reduce shininess for less specular artifacts
        geometry.firstMaterial?.lightingModel = SCNMaterial.LightingModel.constant
        return geometry
    }

    // -----------------------------------------------------------------------
    
    func createWireframeCube(size: CGFloat) -> SCNNode {
        // Define cube vertices
        let halfSize = size / 2
        let vertices: [SCNVector3] = [
            SCNVector3(-halfSize, -halfSize, -halfSize),
            SCNVector3(halfSize, -halfSize, -halfSize),
            SCNVector3(halfSize, halfSize, -halfSize),
            SCNVector3(-halfSize, halfSize, -halfSize),
            SCNVector3(-halfSize, -halfSize, halfSize),
            SCNVector3(halfSize, -halfSize, halfSize),
            SCNVector3(halfSize, halfSize, halfSize),
            SCNVector3(-halfSize, halfSize, halfSize)
        ]

        // Define edges using pairs of vertex indices
        let edges: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 0), // Back face
            (4, 5), (5, 6), (6, 7), (7, 4), // Front face
            (0, 4), (1, 5), (2, 6), (3, 7)  // Connections
        ]

// @@@  This does not work!
//
//        let dashedLineShader = """
//#pragma transparent
//#pragma body
//
//// Pattern length and gaps
//float patternLength = 0.1;
//float gapLength = 0.05;
//float totalLength = patternLength + gapLength;
//
//// Calculate the distance along the line
//float linePosition = fract(_surface.diffuseTexcoord.x / totalLength);
//
//// Create a dashed effect
//if (linePosition > patternLength / totalLength) {
//    discard; // Skip rendering for gaps
//}
//"""
        
        // Create edge geometry
        var edgeVertices: [SCNVector3] = []
        for edge in edges {
            edgeVertices.append(vertices[edge.0])
            edgeVertices.append(vertices[edge.1])
        }

        let vertexSource = SCNGeometrySource(vertices: edgeVertices)
        let edgeIndices = Array(0..<edgeVertices.count).map { Int32($0) }
        let element = SCNGeometryElement(indices: edgeIndices, primitiveType: .line)

        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
        geometry.firstMaterial?.emission.contents = UIColor.blue // Line color
        geometry.firstMaterial?.isDoubleSided = true

// @@@  This does not work!
//
//        geometry.firstMaterial?.shaderModifiers = [
//            .surface: dashedLineShader
//        ]
        
        return SCNNode(geometry: geometry)
    }

    
    // -----------------------------------------------------------------------
   
    func createDottedWireframeCube(size: CGFloat, segmentCount: Int) -> SCNNode {
        let halfSize = Float(size / 2) // Convert to Float
        
        // Define cube vertices
        let vertices: [SCNVector3] = [
            SCNVector3(-halfSize, -halfSize, -halfSize),
            SCNVector3(halfSize, -halfSize, -halfSize),
            SCNVector3(halfSize, halfSize, -halfSize),
            SCNVector3(-halfSize, halfSize, -halfSize),
            SCNVector3(-halfSize, -halfSize, halfSize),
            SCNVector3(halfSize, -halfSize, halfSize),
            SCNVector3(halfSize, halfSize, halfSize),
            SCNVector3(-halfSize, halfSize, halfSize)
        ]
        
        // Define edges as pairs of vertex indices
        let edges: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 0), // Back face
            (4, 5), (5, 6), (6, 7), (7, 4), // Front face
            (0, 4), (1, 5), (2, 6), (3, 7)  // Connections
        ]
        
        var edgeVertices: [SCNVector3] = []
        
        // Create small segments along each edge
        for edge in edges {
            let start = vertices[edge.0]
            let end = vertices[edge.1]
            
            // Interpolate points along the edge
            for i in 0..<segmentCount {
                let t = Float(i) / Float(segmentCount) // Convert `CGFloat` to `Float`
                let x = start.x + t * (end.x - start.x)
                let y = start.y + t * (end.y - start.y)
                let z = start.z + t * (end.z - start.z)
                
                // Add gaps to create the dotted effect
                if i % 2 == 0 { // Every other segment is part of the line
                    edgeVertices.append(SCNVector3(x, y, z))
                }
            }
        }
        
        // Create geometry for points
        let vertexSource = SCNGeometrySource(vertices: edgeVertices)
        let element = SCNGeometryElement(indices: Array(0..<edgeVertices.count).map { Int32($0) }, primitiveType: .point)
        
        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue // Color of dotted edges
        material.lightingModel = .constant
        
        // Add shader to control point size
        material.shaderModifiers = [
            .geometry: """
        gl_PointSize = 5.0;
        """
        ]
        geometry.materials = [material]
        
        return SCNNode(geometry: geometry)
    }
    
    
    // -----------------------------------------------------------------------
    
    func createSurface(size: CGFloat) -> SCNNode {
        let halfSize = size / 2

        // Create a grid for the surface
        let rows = 10
        let columns = 10
        var vertices: [SCNVector3] = []
        var indices: [Int32] = []

        for row in 0...rows {
            for column in 0...columns {
                let x = -halfSize + (CGFloat(column) / CGFloat(columns)) * size
                let z = -halfSize + (CGFloat(row) / CGFloat(rows)) * size
                let y = 0.0 // Keep the surface flat

                vertices.append(SCNVector3(x, y, z))
            }
        }

        for row in 0..<rows {
            for column in 0..<columns {
                let topLeft = row * (columns + 1) + column
                let topRight = topLeft + 1
                let bottomLeft = topLeft + (columns + 1)
                let bottomRight = bottomLeft + 1

                indices.append(contentsOf: [
                    Int32(topLeft), Int32(bottomLeft), Int32(topRight),
                    Int32(topRight), Int32(bottomLeft), Int32(bottomRight)
                ])
            }
        }

        let vertexSource = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)

        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
        geometry.firstMaterial?.diffuse.contents = UIColor.red.withAlphaComponent(0.5) // Surface color
        geometry.firstMaterial?.isDoubleSided = true

        return SCNNode(geometry: geometry)
    }

    // -----------------------------------------------------------------------
    
    func createAmorphousSurface(size: CGFloat) -> SCNNode {
        let halfSize = size / 2
        
        // Create a grid for the surface
        let rows = 20
        let columns = 20
        var vertices: [SCNVector3] = []
        var indices: [Int32] = []
        
        for row in 0...rows {
            for column in 0...columns {
                let x = -halfSize + (CGFloat(column) / CGFloat(columns)) * size
                let z = -halfSize + (CGFloat(row) / CGFloat(rows)) * size
                
                // Amorphous y-value using sine and cosine functions
                // let frequency: CGFloat = 2.0
                let amplitude: CGFloat = 0.3
                // let y = sin(frequency * x) * cos(frequency * z) * amplitude
                let y = perlinNoise(x: x, y: z) * amplitude

                vertices.append(SCNVector3(x, y, z))
            }
        }
        
        for row in 0..<rows {
            for column in 0..<columns {
                let topLeft = row * (columns + 1) + column
                let topRight = topLeft + 1
                let bottomLeft = topLeft + (columns + 1)
                let bottomRight = bottomLeft + 1
                
                indices.append(contentsOf: [
                    Int32(topLeft), Int32(bottomLeft), Int32(topRight),
                    Int32(topRight), Int32(bottomLeft), Int32(bottomRight)
                ])
            }
        }
        
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        
        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
        geometry.firstMaterial?.diffuse.contents = uiColor.withAlphaComponent(0.6) // Surface color
        geometry.firstMaterial?.isDoubleSided = true
        
        return SCNNode(geometry: geometry)
    }

    // -----------------------------------------------------------------------
    
    
    func createAmorphousSurfaceWithPerlinNoise(size: CGFloat) -> SCNNode {
        let halfSize = size / 2
        let perlin = PerlinNoise(seed: 42) // Seed for deterministic noise
        
        // Create a grid for the surface
        let rows = 20
        let columns = 20
        var vertices: [SCNVector3] = []
        var indices: [Int32] = []
        
        for row in 0...rows {
            for column in 0...columns {
                let x = -halfSize + (CGFloat(column) / CGFloat(columns)) * size
                let z = -halfSize + (CGFloat(row) / CGFloat(rows)) * size
                
                // Use Perlin noise to calculate y
                let frequency: Double = 1.5
                let amplitude: Double = 0.5
                let y = perlin.noise(x: Double(x) * frequency, y: Double(z) * frequency) * amplitude
                
                vertices.append(SCNVector3(x, CGFloat(y), z))
            }
        }
        
        for row in 0..<rows {
            for column in 0..<columns {
                let topLeft = row * (columns + 1) + column
                let topRight = topLeft + 1
                let bottomLeft = topLeft + (columns + 1)
                let bottomRight = bottomLeft + 1
                
                indices.append(contentsOf: [
                    Int32(topLeft), Int32(bottomLeft), Int32(topRight),
                    Int32(topRight), Int32(bottomLeft), Int32(bottomRight)
                ])
            }
        }
        
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        

        
        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
        geometry.firstMaterial?.diffuse.contents = uiColor.withAlphaComponent(0.6) // Surface color
        geometry.firstMaterial?.isDoubleSided = true
        
        return SCNNode(geometry: geometry)
    }

    
    
    // -----------------------------------------------------------------------
    
    func updateCubeRotation() {
        // Find the cube node
        guard let cubeNode = scene.rootNode.childNode(withName: "Cube", recursively: true) else { return }

        // Apply rotation
        cubeNode.eulerAngles = SCNVector3(rotationX, rotationY, 0)

        // Rotate the surface with the cube
        if let surfaceNode = scene.rootNode.childNode(withName: "Surface", recursively: true) {
            surfaceNode.eulerAngles = SCNVector3(rotationX, rotationY, 0)
        }
    }

    // -----------------------------------------------------------------------
    
    func updateCubeSize() {
        // Remove the old cube and surface
        scene.rootNode.childNode(withName: "Cube", recursively: true)?.removeFromParentNode()
        scene.rootNode.childNode(withName: "Surface", recursively: true)?.removeFromParentNode()

        // Add a new cube with the updated size
        let newCube = createWireframeCube(size: cubeSize)
        newCube.name = "Cube"
        scene.rootNode.addChildNode(newCube)

        // Add a new surface with the updated size
        // let newSurface = createAmorphousSurface(size: cubeSize)
        let newSurface = createAmorphousSurfaceWithPerlinNoise(size: cubeSize)
        newSurface.name = "Surface"
        scene.rootNode.addChildNode(newSurface)
    }
    
    
    // -----------------------------------------------------------------------
    
    func perlinNoise(x: Double, y: Double) -> Double {
        func fade(_ t: Double) -> Double {
            return t * t * t * (t * (t * 6 - 15) + 10)
        }
        
        func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
            return a + t * (b - a)
        }
        
        func grad(hash: Int, x: Double, y: Double) -> Double {
            let h = hash & 3
            let u = h < 2 ? x : y
            let v = h < 2 ? y : x
            return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
        }
        
        let xi = Int(floor(x)) & 255
        let yi = Int(floor(y)) & 255
        let xf = x - floor(x)
        let yf = y - floor(y)
        
        let u = fade(xf)
        let v = fade(yf)
        
        let p: [Int] = (0...255).map { _ in Int.random(in: 0...255) } + (0...255).map { _ in Int.random(in: 0...255) }
        
        let aa = p[p[xi] + yi]
        let ab = p[p[xi] + yi + 1]
        let ba = p[p[xi + 1] + yi]
        let bb = p[p[xi + 1] + yi + 1]
        
        let x1 = lerp(grad(hash: aa, x: xf, y: yf),
                      grad(hash: ba, x: xf - 1, y: yf), u)
        let x2 = lerp(grad(hash: ab, x: xf, y: yf - 1),
                      grad(hash: bb, x: xf - 1, y: yf - 1), u)
        return lerp(x1, x2, v)
    }

    // -----------------------------------------------------------------------
    
//    func gradientColor(for normalizedValue: CGFloat) -> SCNVector4 {
//        // Gradient from blue (low) to red (high)
//        let blue = SCNVector4(0, 0, 1, 1) // RGBA for blue
//        let red = SCNVector4(1, 0, 0, 1)  // RGBA for red
//        
//        let interpolatedR = blue.x + normalizedValue * (red.x - blue.x)
//        let interpolatedG = blue.y + normalizedValue * (red.y - blue.y)
//        let interpolatedB = blue.z + normalizedValue * (red.z - blue.z)
//        let interpolatedA = blue.w + normalizedValue * (red.w - blue.w)
//        
//        return SCNVector4(interpolatedR, interpolatedG, interpolatedB, interpolatedA)
//    }

    func gradientColor(for normalizedValue: CGFloat) -> SCNVector4 {
        // Gradient from blue (low) to red (high)
        let blue = SCNVector4(0, 0, 1, 1) // RGBA for blue
        let red = SCNVector4(1, 0, 0, 1)  // RGBA for red
        
        let interpolatedR = Float(blue.x) + Float(normalizedValue) * (Float(red.x) - Float(blue.x))
        let interpolatedG = Float(blue.y) + Float(normalizedValue) * (Float(red.y) - Float(blue.y))
        let interpolatedB = Float(blue.z) + Float(normalizedValue) * (Float(red.z) - Float(blue.z))
        let interpolatedA = Float(blue.w) + Float(normalizedValue) * (Float(red.w) - Float(blue.w))
        
        return SCNVector4(interpolatedR, interpolatedG, interpolatedB, interpolatedA)
    }

    
    // -----------------------------------------------------------------------
    
    
}

// ---------------------------------------------------------------------------

struct CubeWithSurfaceView_Previews: PreviewProvider {
    static var previews: some View {
        CubeWithSurfaceView()
    }
}

// ---------------------------------------------------------------------------

extension SCNVector3 {
    
    static func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    static func +=(lhs: inout SCNVector3, rhs: SCNVector3) {
        lhs = SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    static func -(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
    
    static func *(lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        return SCNVector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }
    
    static func /(lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        return SCNVector3(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }
    
    mutating func normalize() {
        let length = sqrt(x * x + y * y + z * z)
        guard length > 0 else { return }
        self = self / length
    }
    
    func normalized() -> SCNVector3 {
        var copy = self
        copy.normalize()
        return copy
    }
    
    func cross(_ other: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            x: y * other.z - z * other.y,
            y: z * other.x - x * other.z,
            z: x * other.y - y * other.x
        )
    }
}

// ---------------------------------------------------------------------------

