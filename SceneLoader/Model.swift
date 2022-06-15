//
//  Model.swift
//  IntroBlender
//

import ModelIO
import Metal
import MetalKit
import simd


/// Container for meshes 
public final class Model {

    let meshes : [Mesh]
    let pose : simd_float4x4

    init(name: String, withExtension: String, subdirectory: String, pose: simd_float4x4) {
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: withExtension, subdirectory: subdirectory) else {
            fatalError("Asset \(name).\(withExtension) does not exist.")
        }
        
        let vertexDescriptor = Renderer.buildMDLVertexDescriptor()
        
        // Tell ModelI/O how to create space to put our vertices
        let bufferAllocator = MTKMeshBufferAllocator(device: Renderer.device)
        
        let asset = MDLAsset(url: modelURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        
        // Get collection of MTKMeshes
        var mtkMeshes = [MTKMesh]()
        var mdlMeshes = [MDLMesh]()
        do {
            (mdlMeshes, mtkMeshes) = try MTKMesh.newMeshes(asset: asset, device: Renderer.device)
        } catch {
            fatalError("Could not extract meshes from Model I/O asset")
        }
        
        self.meshes = zip(mdlMeshes, mtkMeshes).map {
            mesh in Mesh(mdlMesh: mesh.0, mtkMesh: mesh.1)
        }
        
        
        self.pose = pose
        
    }

}


public struct Mesh {
    
    let submeshes : [SubMesh]
    let vertexBuffers: [MTLBuffer]
    
    public init(mdlMesh: MDLMesh, mtkMesh: MTKMesh) {
        
        self.submeshes = zip(mdlMesh.submeshes!, mtkMesh.submeshes).map {
            mesh in SubMesh(mdlSubmesh: mesh.0 as! MDLSubmesh, mtkSubmesh: mesh.1)
        }
        
        self.vertexBuffers =  mtkMesh.vertexBuffers.map {
            mtkMeshBuffer in mtkMeshBuffer.buffer
        }
    }
    
}


public struct SubMesh {
    
    let indexCount: Int
    let indexType : MTLIndexType
    let indexBuffer : MTLBuffer
    let indexBufferOffset : Int
    
    let material : Material
    var texture : MTLTexture?
    
    public init(mdlSubmesh: MDLSubmesh, mtkSubmesh : MTKSubmesh) {
        
        self.indexCount         = mtkSubmesh.indexCount
        self.indexType          = mtkSubmesh.indexType
        self.indexBuffer        = mtkSubmesh.indexBuffer.buffer
        self.indexBufferOffset  = mtkSubmesh.indexBuffer.offset
        
        material = Material(material: mdlSubmesh.material!)
        
        let material = mdlSubmesh.material
        
        /// If the obj file has a map to a texture, this closure will load it
        func property(with semantic: MDLMaterialSemantic) -> MTLTexture? {
            guard let property = material?.property(with: semantic),
                  property.type == .string,
                  let filename = property.stringValue,
                  let texture = try? ModelTextureLoader.loadTexture(filename: filename, withExtension: ".obj")
            else {
                return nil
            }
            return texture
        }
        
        /// Base color here means the same as diffuse
        let baseColor = property(with: .baseColor)
        // we store just one texture
        texture = baseColor
        
    }
}



public extension Material {
    
    init(material : MDLMaterial) {
        self.init()
        
        if let baseColor = material.property(with: .baseColor),
           baseColor.type == .float3 {
            self.baseColor = baseColor.float3Value
        }
        if let specular = material.property(with: .specular),
           specular.type == .float3 {
            self.specularColor = specular.float3Value
        }
        if let shininess = material.property(with: .specularExponent),
           shininess.type == .float {
            self.shininess = shininess.floatValue
        }
        if let roughness = material.property(with: .roughness),
           roughness.type == .float3 {
            self.roghtness = roughness.floatValue
        }
        self.ambientOcclusion = 1
        
    }
    
}
