//
//  ShaderTypes.h
//  IntroBlender
//
//  Created by Javier Cuesta on 05.06.22.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef NS_ENUM(NSInteger, BufferIndex)
{
    BufferIndexMeshPositions = 0,
    BufferIndexMeshGenerics  = 1,
    BufferIndexUniforms      = 2
};

typedef NS_ENUM(NSInteger, VertexAttribute)
{
    VertexAttributePosition  = 0,
    VertexAttributeNormal    = 1,
    VertexAttributeTexcoord  = 2,
};

typedef NS_ENUM(NSInteger, TextureIndex)
{
    TextureIndexColor    = 0,
};

typedef NS_ENUM(NSInteger, MaterialIndex)
{
    MaterialIndexColor    = 0,
};

typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
    matrix_float4x4 modelMatrix;
} Uniforms;

typedef struct {
    vector_float3 baseColor;
    vector_float3 specularColor;
    float roghtness;
    float metallic;
    float ambientOcclusion;
    float shininess;
} Material;

#endif /* ShaderTypes_h */

