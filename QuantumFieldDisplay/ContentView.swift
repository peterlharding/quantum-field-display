//
//  ContentView.swift
//  QuantumFieldDisplay
//
//  Created by Peter Harding on 26/11/2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        CubeWithSurfaceView()
            .ignoresSafeArea()
            .padding()
    }
}

#Preview {
    ContentView()
}
