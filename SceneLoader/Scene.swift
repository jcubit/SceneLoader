//
//  Scene.swift
//  IntroBlender
//

import MetalKit

/// Container for all models to be rendered
public class Scene {
    
    var models = [Model]()
    
    public init() {
        
        self.models = [Model(name: "Cornell_Box-_Original", withExtension: "usdz", subdirectory: "Resources/Models/CornellBox",
                             pose: simd_float4x4(scaleBy: SIMD3<Float>(0.8,0.8,0.8)) * simd_float4x4(translationBy: SIMD3<Float>(0,-0.5,-3)) * simd_float4x4(rotationAroundAxis: SIMD3<Float>(1,0,0), by: radians_from_degrees(-90.0))),
                       Model(name: "model", withExtension: "obj", subdirectory: "Resources/Models/PoliceStation",
                             pose: simd_float4x4(scaleBy: SIMD3<Float>(0.5,0.5,0.5)) * simd_float4x4(translationBy: SIMD3<Float>(0,0,2))),
                       Model(name: "GamePrimitive", withExtension: "obj", subdirectory: "Resources/Models/Box",
                             pose: simd_float4x4(scaleBy: SIMD3<Float>(0.5,0.5,0.5)) * simd_float4x4(translationBy: SIMD3<Float>(0,4,0)))]
        
    }
    
}
