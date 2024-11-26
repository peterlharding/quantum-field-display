//
//  WireframeCubeView.swift
//  QuantumFieldDisplay
//
//  Created by Peter Harding on 26/11/2024.
//


import SwiftUI
import SceneKit

struct WireframeCubeView1: View {
    @State private var scene = SCNScene() // Manage the scene state
    @State private var lastDragValue: CGSize = .zero
    @State private var rotationX: CGFloat = 0
    @State private var rotationY: CGFloat = 0
    @State private var cubeSize: CGFloat = 1.0 // Cube size controlled by slider

    var body: some View {
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
    }
    
    func setupScene() {
        // Create wireframe cube
        let cubeNode = createWireframeCube(size: 1.0)
        cubeNode.name = "Cube"
        
        // Add cube to the scene
        scene.rootNode.addChildNode(cubeNode)
        
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
    }
    
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
        
        return SCNNode(geometry: geometry)
    }
    
    func updateCubeRotation() {
        // Find the cube node
        guard let cubeNode = scene.rootNode.childNode(withName: "Cube", recursively: true) else { return }
        
        // Apply rotation
        cubeNode.eulerAngles = SCNVector3(rotationX, rotationY, 0)
    }
}

struct WireframeCubeView1_Previews: PreviewProvider {
    static var previews: some View {
        WireframeCubeView1()
    }
}
