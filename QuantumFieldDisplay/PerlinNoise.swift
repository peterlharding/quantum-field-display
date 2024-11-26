//
//  PerlinNoise.swift
//  QuantumFieldDisplay
//
//  Created by Peter Harding on 26/11/2024.
//


import Foundation


struct PerlinNoise {
    private let permutation: [Int]
    
    init(seed: Int = 0) {
        // Generate a deterministic random permutation of integers
        var p = Array(0...255)
        var generator = SeededGenerator(seed: seed) // Create a mutable generator
        p.shuffle(using: &generator) // Pass the generator as an inout argument
        permutation = p + p
    }
    
    func noise(x: Double, y: Double) -> Double {
        // Find unit grid cell containing the point
        let xi = Int(floor(x)) & 255
        let yi = Int(floor(y)) & 255
        
        // Relative x, y position in grid cell
        let xf = x - floor(x)
        let yf = y - floor(y)
        
        // Fade curves for x and y
        let u = fade(xf)
        let v = fade(yf)
        
        // Hash coordinates of the 4 corners
        let aa = permutation[permutation[xi] + yi]
        let ab = permutation[permutation[xi] + yi + 1]
        let ba = permutation[permutation[xi + 1] + yi]
        let bb = permutation[permutation[xi + 1] + yi + 1]
        
        // Add blended results from 4 corners of the grid
        let x1 = lerp(u, grad(hash: aa, x: xf, y: yf), grad(hash: ba, x: xf - 1, y: yf))
        let x2 = lerp(u, grad(hash: ab, x: xf, y: yf - 1), grad(hash: bb, x: xf - 1, y: yf - 1))
        
        return lerp(v, x1, x2)
    }
    
    private func fade(_ t: Double) -> Double {
        // Fade function to smooth transitions
        return t * t * t * (t * (t * 6 - 15) + 10)
    }
    
    private func lerp(_ t: Double, _ a: Double, _ b: Double) -> Double {
        // Linear interpolation
        return a + t * (b - a)
    }
    
    private func grad(hash: Int, x: Double, y: Double) -> Double {
        // Gradient function for pseudo-random directions
        switch hash & 3 {
        case 0: return x + y
        case 1: return -x + y
        case 2: return x - y
        case 3: return -x - y
        default: return 0 // Should never happen
        }
    }
}

// Seeded random number generator
struct SeededGenerator: RandomNumberGenerator {
    private var seed: UInt64
    
    init(seed: Int) {
        self.seed = UInt64(seed)
    }
    
    mutating func next() -> UInt64 {
        seed = seed &* 6364136223846793005 &+ 1
        return seed
    }
}

// Usage

//  let perlin = PerlinNoise(seed: 42)
//  let value = perlin.noise(x: 1.0, y: 1.0)
//  print("Perlin noise value: \(value)")



// Take 1

//struct PerlinNoise {
//    private let permutation: [Int]
//
//    init(seed: Int = 0) {
//        // Generate a deterministic random permutation of integers
//        var p = Array(0...255)
//        p.shuffle(using: &SeededGenerator(seed: seed))
//        permutation = p + p
//    }
//
//    func noise(x: Double, y: Double) -> Double {
//        // Find unit grid cell containing the point
//        let xi = Int(floor(x)) & 255
//        let yi = Int(floor(y)) & 255
//
//        // Relative x, y position in grid cell
//        let xf = x - floor(x)
//        let yf = y - floor(y)
//
//        // Fade curves for x and y
//        let u = fade(xf)
//        let v = fade(yf)
//
//        // Hash coordinates of the 4 corners
//        let aa = permutation[permutation[xi] + yi]
//        let ab = permutation[permutation[xi] + yi + 1]
//        let ba = permutation[permutation[xi + 1] + yi]
//        let bb = permutation[permutation[xi + 1] + yi + 1]
//
//        // Add blended results from 4 corners of the grid
//        let x1 = lerp(u, grad(hash: aa, x: xf, y: yf), grad(hash: ba, x: xf - 1, y: yf))
//        let x2 = lerp(u, grad(hash: ab, x: xf, y: yf - 1), grad(hash: bb, x: xf - 1, y: yf - 1))
//
//        return lerp(v, x1, x2)
//    }
//
//    private func fade(_ t: Double) -> Double {
//        // Fade function to smooth transitions
//        return t * t * t * (t * (t * 6 - 15) + 10)
//    }
//
//    private func lerp(_ t: Double, _ a: Double, _ b: Double) -> Double {
//        // Linear interpolation
//        return a + t * (b - a)
//    }
//
//    private func grad(hash: Int, x: Double, y: Double) -> Double {
//        // Gradient function for pseudo-random directions
//        switch hash & 3 {
//        case 0: return x + y
//        case 1: return -x + y
//        case 2: return x - y
//        case 3: return -x - y
//        default: return 0 // Should never happen
//        }
//    }
//}
//
//// Seeded random number generator
//struct SeededGenerator: RandomNumberGenerator {
//    private var seed: UInt64
//
//    init(seed: Int) {
//        self.seed = UInt64(seed)
//    }
//
//    mutating func next() -> UInt64 {
//        seed = seed &* 6364136223846793005 &+ 1
//        return seed
//    }
//}
