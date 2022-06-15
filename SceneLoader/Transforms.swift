//
//  Transforms.swift
//  IntroBlender
//


import simd


extension simd_float4x4 {
    
    
    /// initializer of an affine rotation transformation
    ///
    /// - Note: This initialization uses Rodriguez formula
    ///
    /// - Parameters:
    ///   - axis: axis of rotation
    ///   - angle: angle of rotation in radians
    init(rotationAroundAxis axis: SIMD3<Float>, by angle: Float) {
        let unitAxis = normalize(axis)
        let ct = cosf(angle)
        let st = sinf(angle)
        let ci = 1 - ct
        let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
        self.init(columns:(SIMD4<Float>(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                           SIMD4<Float>(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                           SIMD4<Float>(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                           SIMD4<Float>(                  0,                   0,                   0, 1)))
    }
    
    init(translationBy v: SIMD3<Float>) {
        self.init(columns:(SIMD4<Float>(1, 0, 0, 0),
                           SIMD4<Float>(0, 1, 0, 0),
                           SIMD4<Float>(0, 0, 1, 0),
                           SIMD4<Float>(v.x, v.y, v.z, 1)))
    }
    
    init(scaleBy s: SIMD3<Float>){
        self.init(columns: (SIMD4<Float>(s.x, 0, 0, 0),
                            SIMD4<Float>(0, s.y, 0, 0),
                            SIMD4<Float>(0, 0, s.z, 0),
                            SIMD4<Float>(0, 0, 0, 1)))
    }
    
}


extension simd_float3x3 {
    
    /// initializer of a 3x3 rotation matrix
    ///
    /// - Note: This initialization uses Rodriguez formula
    ///
    /// - Parameters:
    ///   - axis: axis of rotation
    ///   - angle: angle of rotation in radians
    init(rotationAroundAxis axis: SIMD3<Float>, by angle: Float) {
        let unitAxis = normalize(axis)
        let ct = cosf(angle)
        let st = sinf(angle)
        let ci = 1 - ct
        let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
        self.init(columns:(SIMD3<Float>(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st),
                           SIMD3<Float>(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st),
                           SIMD3<Float>(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci)))
    }
    
}


