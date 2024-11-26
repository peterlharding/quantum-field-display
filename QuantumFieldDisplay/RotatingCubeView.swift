//
//  RotatingCubeView.swift
//  QuantumFieldDisplay
//
//  Created by Peter Harding on 26/11/2024.
//


import SwiftUI
import SceneKit


struct RotatingCubeView: View {
    @State private var scene = SCNScene() // Manage the scene state
    @State private var lastDragValue: CGSize = .zero
    @State private var rotationX: CGFloat = 0
    @State private var rotationY: CGFloat = 0
    
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
        // Create cube
        let cubeGeometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.05)
        let cubeNode = SCNNode(geometry: cubeGeometry)
        cubeNode.name = "Cube"
        
        // Material
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemBlue
        cubeGeometry.firstMaterial = material
        
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
    
    func updateCubeRotation() {
        // Find the cube node
        guard let cubeNode = scene.rootNode.childNode(withName: "Cube", recursively: true) else { return }
        
        // Apply rotation
        cubeNode.eulerAngles = SCNVector3(rotationX, rotationY, 0)
    }
}

struct RotatingCubeView_Previews: PreviewProvider {
    static var previews: some View {
        RotatingCubeView()
    }
}



//
//struct RotatingCubeView: View {
//    @State private var lastDragValue: CGSize = .zero
//    @State private var rotationX: CGFloat = 0
//    @State private var rotationY: CGFloat = 0
//    
//    var body: some View {
//        GeometryReader { geometry in
//            SceneView(
//                scene: createScene(),
//                options: [.allowsCameraControl]
//            )
//            .gesture(
//                DragGesture()
//                    .onChanged { value in
//                        let deltaX = value.translation.width - lastDragValue.width
//                        let deltaY = value.translation.height - lastDragValue.height
//                        
//                        rotationX += deltaY / 100 // Adjust sensitivity
//                        rotationY += deltaX / 100
//                        
//                        lastDragValue = value.translation
//                        updateCubeRotation()
//                    }
//                    .onEnded { _ in
//                        lastDragValue = .zero
//                    }
//            )
//            .onAppear {
//                updateCubeRotation()
//            }
//        }
//    }
//    
//    func createScene() -> SCNScene {
//        let scene = SCNScene()
//        
//        // Create cube
//        let cubeGeometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.05)
//        let cubeNode = SCNNode(geometry: cubeGeometry)
//        cubeNode.name = "Cube"
//        
//        // Material
//        let material = SCNMaterial()
//        material.diffuse.contents = UIColor.systemBlue
//        cubeGeometry.firstMaterial = material
//        
//        scene.rootNode.addChildNode(cubeNode)
//        
//        // Camera
//        let cameraNode = SCNNode()
//        cameraNode.camera = SCNCamera()
//        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
//        scene.rootNode.addChildNode(cameraNode)
//        
//        // Light
//        let lightNode = SCNNode()
//        lightNode.light = SCNLight()
//        lightNode.light?.type = .omni
//        lightNode.position = SCNVector3(x: 5, y: 5, z: 5)
//        scene.rootNode.addChildNode(lightNode)
//        
//        return scene
//    }
//    
//    func updateCubeRotation() {
//        // Find the cube node
//        guard let scene = SceneView().scene,
//              let cubeNode = scene.rootNode.childNode(withName: "Cube", recursively: true)
//        else { return }
//        
//        // Apply rotation
//        cubeNode.eulerAngles = SCNVector3(rotationX, rotationY, 0)
//    }
//}
//
//struct RotatingCubeView_Previews: PreviewProvider {
//    static var previews: some View {
//        RotatingCubeView()
//    }
//}
