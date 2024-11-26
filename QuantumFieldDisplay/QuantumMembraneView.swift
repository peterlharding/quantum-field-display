//
//  QuantumMembraneView.swift
//  QuantumFieldDisplay
//
//  Created by Peter Harding on 26/11/2024.
//


import SwiftUI

struct QuantumMembraneView: View {
    @State private var phase: CGFloat = 0
    @State private var fadeInOut: Bool = true
    @State private var membraneOffsets: [CGFloat] = Array(repeating: 0, count: 5)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Multiple membranes
                ForEach(0..<5, id: \.self) { index in
                    MembraneShape(controlOffset: membraneOffsets[index])
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(fadeInOut ? 0.5 : 0.2),
                                    Color.purple.opacity(fadeInOut ? 0.3 : 0.1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .opacity(Double(index + 1) / 5) // Layered opacity
                        .blendMode(.plusLighter)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: fadeInOut)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    fadeInOut.toggle()
                }
                
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    for i in 0..<membraneOffsets.count {
                        membraneOffsets[i] = CGFloat.random(in: -100...100)
                    }
                }
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}

struct MembraneShape: Shape {
    var controlOffset: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Start at the top-left corner
        path.move(to: CGPoint(x: 0, y: height / 2))
        
        // Create an undulating path with control points
        let step = width / 8
        for i in stride(from: 0, through: 8, by: 1) {
            let x = CGFloat(i) * step
            let controlX = x - step / 2
            let controlY = height / 2 + (i % 2 == 0 ? controlOffset : -controlOffset)
            
            path.addQuadCurve(
                to: CGPoint(x: x, y: height / 2),
                control: CGPoint(x: controlX, y: controlY)
            )
        }
        
        // Close the path at the bottom
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct QuantumMembraneView_Previews: PreviewProvider {
    static var previews: some View {
        QuantumMembraneView()
    }
}
