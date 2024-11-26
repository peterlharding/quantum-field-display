//
//  QuantumSurfaceView.swift
//  QuantumFieldDisplay
//
//  Created by Peter Harding on 26/11/2024.
//


import SwiftUI
import SceneKit

struct QuantumSurfaceView: View {
    var body: some View {
        SceneView(
            scene: createScene(),
            options: [.allowsCameraControl, .autoenablesDefaultLighting]
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    func createScene() -> SCNScene {
        let scene = SCNScene()
        
        // Add the surface
        let surfaceNode = createSurfaceNode()
        scene.rootNode.addChildNode(surfaceNode)
        
        // Add a camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 2, z: 5)
        scene.rootNode.addChildNode(cameraNode)
        
        // Add a light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 5, z: 5)
        scene.rootNode.addChildNode(lightNode)
        
        return scene
    }
    
    func createSurfaceNode() -> SCNNode {
        let width: CGFloat = 4
        let depth: CGFloat = 4
        let rows = 50
        let columns = 50
        let geometry = createSurfaceGeometry(width: width, depth: depth, rows: rows, columns: columns)
        
        let surfaceNode = SCNNode(geometry: geometry)
        surfaceNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.8)
        surfaceNode.geometry?.firstMaterial?.isDoubleSided = true
        surfaceNode.position = SCNVector3(x: 0, y: 0, z: 0)
        
        return surfaceNode
    }
    
    func createSurfaceGeometry(width: CGFloat, depth: CGFloat, rows: Int, columns: Int) -> SCNGeometry {
        var vertices: [SCNVector3] = []
        var indices: [Int32] = []
        
        for row in 0...rows {
            for column in 0...columns {
                let x = width * (CGFloat(column) / CGFloat(columns) - 0.5)
                let z = depth * (CGFloat(row) / CGFloat(rows) - 0.5)
                let y = sin(2 * .pi * x) * cos(2 * .pi * z) * 0.5 // Surface formula
                
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
        
        return SCNGeometry(sources: [vertexSource], elements: [element])
    }
}

struct QuantumSurfaceView_Previews: PreviewProvider {
    static var previews: some View {
        QuantumSurfaceView()
    }
}
