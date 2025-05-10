#ifndef GBUFFERS_H
#define GBUFFERS_H

#include "../../ZetaCore/Core/Material.h"

enum GBUFFER_OFFSET
{
    BASE_COLOR = 0,
    NORMAL,
    METALLIC_ROUGHNESS,
    MOTION_VECTOR,
    EMISSIVE_COLOR,
    IOR,
    COAT,
    DEPTH,
    TRI_DIFF_GEO_A,
    TRI_DIFF_GEO_B
};

#define GBUFFER_BASE_COLOR Texture2D<float4>
#define GBUFFER_NORMAL Texture2D<float2>
#define GBUFFER_METALLIC_ROUGHNESS Texture2D<float2>
#define GBUFFER_MOTION_VECTOR Texture2D<float2> 
#define GBUFFER_EMISSIVE_COLOR Texture2D<float3>
#define GBUFFER_IOR Texture2D<float>
#define GBUFFER_COAT Texture2D<uint4>
#define GBUFFER_DEPTH Texture2D<float> 
#define GBUFFER_TRI_DIFF_GEO_A Texture2D<uint4> 
#define GBUFFER_TRI_DIFF_GEO_B Texture2D<uint2> 

#define _1__1  2    //1 << 1
#define _1__2  4    //1 << 2
#define _1__3  8    //1 << 3
#define _1__4  16   //1 << 4
#define _1__5  32   //1 << 5
#define _1__6  64   //1 << 6
#define _1__7  128  //1 << 7

namespace GBuffer
{
    struct Flags
    {
        bool metallic;
        bool transmissive;
        bool emissive;
        bool invalid;
        bool trDepthGt0;
        bool subsurface;
        bool coated;
    };

    struct Coat
    {
        float weight;
        float3 color;
        float roughness;
        float ior;
    };

    float EncodeMetallic(float metalness, bool isTransmissive, float3 emissive, float trDepth,
        float subsurface, float coat_weight)
    {
        bool isMetal = metalness >= MIN_METALNESS_METAL;
        bool isEmissive = dot(emissive, emissive) > 0;

        uint ret = isTransmissive;
        ret |= (uint(isEmissive) << 1);
        ret |= (uint(trDepth > 0) << 3);
        ret |= (uint(subsurface > 0) << 4);
        ret |= (uint(coat_weight > 0) << 5);
        ret |= (uint(isMetal) << 7);

        return float(ret) / 255.0f;
    }

    GBuffer::Flags DecodeMetallic(float encoded)
    {
        uint v = (uint)mad(encoded, 255.0f, 0.5f);

        Flags ret;
        ret.transmissive = (v & 0x1) != 0;
        ret.emissive = (v & (_1__1)) != 0;
        ret.invalid = (v & (_1__2)) != 0;
        ret.trDepthGt0 = (v & (_1__3)) != 0;
        ret.subsurface = (v & (_1__4)) != 0;
        ret.coated = (v & (_1__5)) != 0;
        ret.metallic = (v & (_1__7)) != 0;

        return ret;
    }

    bool4 DecodeMetallic(float4 encoded)
    {
        uint4 v = (uint4) round(encoded * 255.0f);
        return (v & (_1__7)) != 0;
    }

    void DecodeMetallicEmissive(float4 encoded, out bool4 isMetallic, out bool4 isEmissive)
    {
        uint4 v = (uint4) round(encoded * 255.0f);
        isEmissive = (v & (_1__1)) != 0;
        isMetallic = (v & (_1__7)) != 0;
    }

    float EncodeIOR(float ior)
    {
        return (ior - MIN_IOR) / (MAX_IOR - MIN_IOR);
    }

    float DecodeIOR(float encoded)
    {
        return mad(encoded, MAX_IOR - MIN_IOR, MIN_IOR);
    }

    GBuffer::Coat UnpackCoat(uint3 packed)
    {
        GBuffer::Coat ret;
        ret.weight = Math::UNorm8ToFloat((packed.y >> 8) & 0xff);
        ret.roughness = Math::UNorm8ToFloat(packed.z & 0xff);

        uint c = packed.x | ((packed.y & 0xff) << 16);
        ret.color = Math::UnpackRGB8(c);

        float normalized = Math::UNorm8ToFloat(packed.z >> 8);
        ret.ior = DecodeIOR(normalized);

        return ret;
    }
}

#endif