//
//  ModelTextureLoader.swift
//  IntroBlender
//

import MetalKit

/// Helper class that gathers functionality for loading textures from the Resource/Models folder
public class ModelTextureLoader {
    
    var device : MTLDevice
    static var textures = [String: MTLTexture]()
    
    public init(device: MTLDevice) {
        self.device = device
    }
    
    static func texture(filename: String, withExtension: String, subdirectory: String) -> MTLTexture? {
        if let texture = textures[filename] {
            return texture
        }
        let texture = try? loadTexture(filename: filename, withExtension: withExtension, subdirectory: subdirectory)
        if texture != nil {
            textures[filename] = texture
        }
        return texture
    }
    
    /// Searchs in all the subdirectories of the Models folder for the texture and loads it
    static func loadTexture(filename: String, withExtension: String) throws -> MTLTexture? {
        
        let textureLoader = MTKTextureLoader(device: Renderer.device)

        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue),
            MTKTextureLoader.Option.origin: NSNumber(pointer: MTKTextureLoader.Origin.bottomLeft.rawValue),
            MTKTextureLoader.Option.SRGB : false,
            MTKTextureLoader.Option.generateMipmaps : NSNumber(booleanLiteral: true)
        ]
        
        let fileExtension = URL(fileURLWithPath: filename).pathExtension.isEmpty ? withExtension : nil
        
        // Iterate to all subfolders to find the mapped texture
        let root = "/Resources/Models"
        let path = Bundle.main.resourcePath!.appending(root)
        let enumerator = FileManager.default.enumerator(atPath: path)
        while let element = enumerator?.nextObject() as? String {

            if let fType = enumerator?.fileAttributes?[FileAttributeKey.type] as? FileAttributeType{
                if fType == .typeDirectory {
                    print(element)
                    let url = Bundle.main.url(forResource: filename, withExtension: fileExtension, subdirectory: root.appending("/").appending(element))
                    if url != nil {
                        let texture = try textureLoader.newTexture(URL: url!,
                                                                   options: textureLoaderOptions)
                        print("Loaded texture: \(url!.lastPathComponent)")
                        return texture
                    }
                }
            }
        }
        
        return nil
    }
    
    static func loadTexture(filename: String, withExtension: String, subdirectory: String) throws -> MTLTexture? {
        
        let textureLoader = MTKTextureLoader(device: Renderer.device)

        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue),
            MTKTextureLoader.Option.origin: NSNumber(pointer: MTKTextureLoader.Origin.bottomLeft.rawValue),
            MTKTextureLoader.Option.SRGB : false,
            MTKTextureLoader.Option.generateMipmaps : NSNumber(booleanLiteral: true)
        ]
        
        let fileExtension = URL(fileURLWithPath: filename).pathExtension.isEmpty ? withExtension : nil
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension, subdirectory: subdirectory)
        else {
            print("Failed to load the texture \(filename). Check extension.")
            return nil
        }

        let texture = try textureLoader.newTexture(URL: url,
                                                   options: textureLoaderOptions)
        print("Loaded texture: \(url.lastPathComponent)")
        return texture
    }
    
}
