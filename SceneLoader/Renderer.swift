//
//  Renderer.swift
//  IntroBlender
//
//  Created by Javier Cuesta on 05.06.22.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd
import ModelIO

// The 256 byte aligned size of our uniform structure
let alignedUniformsSize = (MemoryLayout<Uniforms>.size + 0xFF) & -0x100

let maxBuffersInFlight = 3


class Renderer: NSObject, MTKViewDelegate {

    static var device: MTLDevice!
    let commandQueue: MTLCommandQueue
    var dynamicUniformBuffer: MTLBuffer
    var pipelineState: MTLRenderPipelineState
    var depthState: MTLDepthStencilState

    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)

    var uniformBufferOffset = 0

    var uniformBufferIndex = 0

    var uniforms: UnsafeMutablePointer<Uniforms>

    var projectionMatrix: matrix_float4x4 = matrix_float4x4()

    var rotation: Float = 0
    
    let scene : Scene

    init?(metalKitView: MTKView) {
        Renderer.device = metalKitView.device!
        self.commandQueue = Renderer.device.makeCommandQueue()!

        let uniformBufferSize = alignedUniformsSize * maxBuffersInFlight

        self.dynamicUniformBuffer = Renderer.device.makeBuffer(length:uniformBufferSize,
                                                               options:[MTLResourceOptions.storageModeShared])!

        self.dynamicUniformBuffer.label = "UniformBuffer"

        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents()).bindMemory(to:Uniforms.self, capacity:1)

        metalKitView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        metalKitView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        metalKitView.sampleCount = 1
        
        self.scene = Scene()
        
        let mtlVertexDescriptor = Renderer.buildMetalVertexDescriptorFromModelIO()

        do {
            pipelineState = try Renderer.buildRenderPipelineWithDevice(device: Renderer.device,
                                                                       metalKitView: metalKitView,
                                                                       mtlVertexDescriptor: mtlVertexDescriptor)
        } catch {
            print("Unable to compile render pipeline state.  Error info: \(error)")
            return nil
        }

        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = MTLCompareFunction.less
        depthStateDescriptor.isDepthWriteEnabled = true
        self.depthState = Renderer.device.makeDepthStencilState(descriptor:depthStateDescriptor)!


        super.init()

    }

    
    /// Builds Metal Vertex Descriptor from a MDLVertexDescriptor of ModelIO module
    /// The vertexDescriptor just uses one buffer
    class func buildMetalVertexDescriptorFromModelIO() -> MTLVertexDescriptor {
        
        let vertexDescriptor = buildMDLVertexDescriptor()

        // Change the format of the vertex description to metal's format
        let mtlVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)!
        
        return mtlVertexDescriptor
    }
    
    class func buildMDLVertexDescriptor() -> MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        
        // set the memory layout of the Vertex's properties. We use here interleaved format
        
        // position
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        // normal
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size * 3, bufferIndex: 0)
        // texture coordinates
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.size * 6, bufferIndex: 0)
        // total stride layout
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
        
        return vertexDescriptor
    }

    class func buildRenderPipelineWithDevice(device: MTLDevice,
                                             metalKitView: MTKView,
                                             mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object
        
        let library = device.makeDefaultLibrary()

        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.sampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor

        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat

        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    private func saveMeshToDisk(mdlMesh : MDLMesh) {
        let asset = MDLAsset()
        asset.add(mdlMesh)

        let fileExtension = "obj"
        guard MDLAsset.canExportFileExtension(fileExtension) else {
            fatalError("Can't export a .\(fileExtension) files")
        }

        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        // just send back the first one, which ought to be the only one
        let documentsURL = paths[0]
        do {
            let url = documentsURL.appendingPathComponent("GamePrimitive.\(fileExtension)")
            try asset.export(to: url)
            print("exporting model to ", url)
        } catch {
            fatalError("Error \(error.localizedDescription)")
        }
    }
    



    private func updateDynamicBufferState() {
        /// Update the state of our uniform buffers before rendering

        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight

        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex

        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents() + uniformBufferOffset).bindMemory(to:Uniforms.self, capacity:1)
    }

    private func updateGameState() {
        /// Update any game state before rendering

        uniforms[0].projectionMatrix = projectionMatrix

        let rotationAxis = SIMD3<Float>(0, 1, 0)
//        let modelMatrix = matrix4x4_rotation(radians: rotation, axis: rotationAxis)
        let viewMatrix = matrix4x4_translation(0.0, 0.0, -8.0) * matrix4x4_rotation(radians: rotation, axis: rotationAxis)
//        uniforms[0].modelViewMatrix = simd_mul(viewMatrix, modelMatrix)
        uniforms[0].modelViewMatrix = viewMatrix
        rotation += 0.01
    }

    func draw(in view: MTKView) {
        /// Per frame updates hare

        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            let semaphore = inFlightSemaphore
            commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
                semaphore.signal()
            }
            
            self.updateDynamicBufferState()
            
            self.updateGameState()
            
            /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
            ///   holding onto the drawable and blocking the display pipeline any longer than necessary
            let renderPassDescriptor = view.currentRenderPassDescriptor
            
            if let renderPassDescriptor = renderPassDescriptor {
                
                /// Final pass rendering code here
                if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                    renderEncoder.label = "Primary Render Encoder"
                    
                    renderEncoder.pushDebugGroup("Draw Model")
                    
                    renderEncoder.setCullMode(.back)
                    
                    renderEncoder.setFrontFacing(.counterClockwise)
                    
                    renderEncoder.setRenderPipelineState(pipelineState)
                    
                    renderEncoder.setDepthStencilState(depthState)
                    
                    renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset:uniformBufferOffset, index: BufferIndex.uniforms.rawValue)
                    renderEncoder.setFragmentBuffer(dynamicUniformBuffer, offset:uniformBufferOffset, index: BufferIndex.uniforms.rawValue)
                    
                    
                    for model in scene.models {
                        
                        var currentUniforms = uniforms[0]
                        currentUniforms.modelMatrix = model.pose
                        
                        renderEncoder.setVertexBytes(&currentUniforms, length: MemoryLayout<Uniforms>.stride, index: BufferIndex.uniforms.rawValue)
                        
                        for mesh in model.meshes {
                            for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
                                renderEncoder.setVertexBuffer(vertexBuffer, offset:0, index: index)
                            }
                            
                            for submesh in mesh.submeshes {
                                
                                // set texture
                                renderEncoder.setFragmentTexture(submesh.texture, index: TextureIndex.color.rawValue)
                                
                                // set material
                                var material = submesh.material
                                renderEncoder.setFragmentBytes(&material, length: MemoryLayout<Material>.stride, index: MaterialIndex.color.rawValue)
                                
                                renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                                    indexCount: submesh.indexCount,
                                                                    indexType: submesh.indexType,
                                                                    indexBuffer: submesh.indexBuffer,
                                                                    indexBufferOffset: submesh.indexBufferOffset)
                            }
                        }
                    }
                    renderEncoder.popDebugGroup()

                    renderEncoder.endEncoding()

                    if let drawable = view.currentDrawable {
                        commandBuffer.present(drawable)
                    }
                }
            }
            
            commandBuffer.commit()
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here

        let aspect = Float(size.width) / Float(size.height)
        projectionMatrix = matrix_perspective_right_hand(fovyRadians: radians_from_degrees(65), aspectRatio:aspect, nearZ: 0.1, farZ: 100.0)
    }
}

// Generic matrix math utility functions
func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    return matrix_float4x4.init(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                         vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                         vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                         vector_float4(                  0,                   0,                   0, 1)))
}

func matrix4x4_translation(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> matrix_float4x4 {
    return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(translationX, translationY, translationZ, 1)))
}

func matrix_perspective_right_hand(fovyRadians fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovy * 0.5)
    let xs = ys / aspectRatio
    let zs = farZ / (nearZ - farZ)
    return matrix_float4x4.init(columns:(vector_float4(xs,  0, 0,   0),
                                         vector_float4( 0, ys, 0,   0),
                                         vector_float4( 0,  0, zs, -1),
                                         vector_float4( 0,  0, zs * nearZ, 0)))
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}
