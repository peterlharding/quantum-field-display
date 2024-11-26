//
//  QuantumFieldView.swift
//  QuantumFieldDisplay
//
//  Created by Peter Harding on 26/11/2024.
//


import SwiftUI

struct QuantumFieldView: View {
    @State private var waveOffset: CGFloat = 0
    
    @State private var particlePositions: [CGPoint] = (0..<10).map { _ in
        CGPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1))
    }
    
    @State private var blurRadius: CGFloat = 3

    
    var body: some View {
        
//        ZStack {
//            Color.black.opacity(0.5) // Dim background
//                .edgesIgnoringSafeArea(.all)
//                .blur(radius: 20) // Background blur
//
////            Color.clear.background(.ultraThinMaterial)
////                .edgesIgnoringSafeArea(.all)
////                .blur(radius: 20) // Background blur

            GeometryReader { geometry in
                ZStack {
                    // Wave Background
                    ForEach(0..<5, id: \.self) { index in
                        WaveShape(phase: waveOffset, amplitude: 30, frequency: Double(index) + 1)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple.opacity(0.5)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                            .frame(height: geometry.size.height / CGFloat(index + 2))
                            .offset(y: CGFloat(index) * geometry.size.height / 10)
                            .blur(radius: 1)
                    }
                    
                    // Particles
                    ForEach(0..<particlePositions.count, id: \.self) { index in
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(width: 10, height: 10)
                            .position(
                                x: particlePositions[index].x * geometry.size.width,
                                y: particlePositions[index].y * geometry.size.height
                            )
                            .opacity(0.8)
                            .blur(radius: 3) // Blur only the particles
                            .animation(
                                Animation.easeInOut(duration: 1.5).repeatForever(),
                                value: particlePositions
                            )
                    }
                }
                .blur(radius: blurRadius)
                .onAppear {
                    withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                        waveOffset += .pi * 2
                    }
//                    withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
//                        blurRadius = 15
//                    }
                    updateParticlePositions(in: geometry.size)
                }
            }
//            .background(Color.black)
//            .ignoresSafeArea()
//        }
    }
    
    // Randomize particle positions
    private func updateParticlePositions(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            particlePositions = particlePositions.map { _ in
                CGPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1))
            }
        }
    }
}

struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.midY
        
        path.move(to: CGPoint(x: 0, y: height))
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX + phase) * .pi * frequency) * amplitude
            path.addLine(to: CGPoint(x: x, y: height + CGFloat(sine)))
        }
        
        return path
    }
}

struct QuantumFieldView_Previews: PreviewProvider {
    static var previews: some View {
        QuantumFieldView()
    }
}
