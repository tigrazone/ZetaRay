#include "GBufferRT_Common.h"
#include "../Common/FrameConstants.h"
#include "../Common/StaticTextureSamplers.hlsli"
#include "../Common/GBuffers.hlsli"
#include "../Common/RT.hlsli"

namespace GBufferRT
{
    // Rate of change of texture uv coordinates w.r.t. screen space
    // Ref: M. Pharr, W. Jakob, and G. Humphreys, Physically Based Rendering, Morgan Kaufmann, 2016.
    float4 UVDifferentials(int2 DTid, float3 origin, float3 dir, float2 jitter, 
        bool thinLens, float2 lensSample, float focusDepth, float t, float3 dpdu, 
        float3 dpdv, ConstantBuffer<cbFrameConstants> g_frame)
    {
        // 1. Form auxiliary rays offset one pixel to right and above of camera ray (r_x and r_y).
        // 2. Form tangent plane at hit point (P).
        // 3. Approximae surface around hit point using a first-order approximation at P. Hit 
        //    points for auxiliary rays can be solved for using the ray-plane intersection 
        //    algorithm (denote by p_x and p_y).
        // 4. Each triangle can be described as a parametric surface p = f(u, v). Since triangle 
        //    is planar, the first-order approximation is exact:
        //          p' - p0 = [dpdu dpdv] duv
        // 5. Since dpdu and dpdv for the hit triangle are known, by replacing p_x and p_y for p' 
        //    in above, ddx(uv) and ddy(uv) can be approximated by solving the linear system.

        // determinant of square matrix A^T A
        float dpduDotdpdu = dot(dpdu, dpdu);
        float dpdvDotdpdv = dot(dpdv, dpdv);
        float dpduDotdpdv = dot(dpdu, dpdv);
        float det = dpduDotdpdu * dpdvDotdpdv - dpduDotdpdv * dpduDotdpdv;
        // A^T A is not invertible
        if (abs(det) < 1e-7f)
            return 0;

        // form ray differentials
        float2 renderDim = float2(g_frame.RenderWidth, g_frame.RenderHeight);

        float3 dir_cs_x = RT::GeneratePinholeCameraRay_CS(int2(DTid.x + 1, DTid.y), 
            renderDim, g_frame.AspectRatio, g_frame.TanHalfFOV, 
            g_frame.CurrCameraJitter);
        float3 dir_cs_y = RT::GeneratePinholeCameraRay_CS(int2(DTid.x, DTid.y - 1), 
            renderDim, g_frame.AspectRatio, g_frame.TanHalfFOV, 
            g_frame.CurrCameraJitter);

        // change ray directions given the lens sample
        if(thinLens)
        {
            float3 focalPoint_x = focusDepth * dir_cs_x;
            dir_cs_x = focalPoint_x - float3(lensSample, 0);

            float3 focalPoint_y = focusDepth * dir_cs_y;
            dir_cs_y = focalPoint_y - float3(lensSample, 0);
        }

        // camera space to world space
        float3 dir_x = mad(dir_cs_x.x, g_frame.CurrView[0].xyz, 
            mad(dir_cs_x.y, g_frame.CurrView[1].xyz, dir_cs_x.z * g_frame.CurrView[2].xyz));
        dir_x = normalize(dir_x);

        float3 dir_y = mad(dir_cs_y.x, g_frame.CurrView[0].xyz, 
            mad(dir_cs_y.y, g_frame.CurrView[1].xyz, dir_cs_y.z * g_frame.CurrView[2].xyz));
        dir_y = normalize(dir_y);

        // compute intersection with tangent plane at hit point for camera ray
        float3 faceNormal = normalize(cross(dpdu, dpdv));
        float3 p = origin + t * dir;
        float d = -dot(faceNormal, p);
        float numerator = -dot(faceNormal, origin) - d;
        
        // compute intersection with tangent plane for ray differentials
        float denom_x = dot(faceNormal, dir_x);
        denom_x = (denom_x < 0 ? -1 : 1) * max(abs(denom_x), 1e-8);
        float t_x = numerator / denom_x;
        float3 p_x = origin + t_x * dir_x;

        float denom_y = dot(faceNormal, dir_y);
        denom_y = (denom_y < 0 ? -1 : 1) * max(abs(denom_y), 1e-8);
        float t_y = numerator / denom_y;
        float3 p_y = origin + t_y * dir_y;

        // since the linear system described above is overdetermined, calculate
        // the least-squares solution (denote by x_hat), which minimizes the L2-norm 
        // of A x_hat - b when there's no solution:
        //      x_hat = (A^TA)^-1 A^T b
        // where A = [dpdu dpdv] and b = delta_p

        // division by determinant happens below
        float2x2 A_T_A_Inv = float2x2(dpdvDotdpdv, -dpduDotdpdv,
                                     -dpduDotdpdv, dpduDotdpdu);
        float3 dpdx = p_x - p;
        float2 A_Txb_x = float2(dot(dpdu, dpdx), dot(dpdv, dpdx));
        float2 grads_x = mul(A_T_A_Inv, A_Txb_x) / det;

        float3 dpdy = p_y - p;
        float2 A_Txb_y = float2(dot(dpdu, dpdy), dot(dpdv, dpdy));
        float2 grads_y = mul(A_T_A_Inv, A_Txb_y) / det;

        // return clamp(float4(grads_x, grads_y), 1e-7, 1e7);
        return float4(grads_x, grads_y);
    }

    void WriteToGBuffers(uint2 DTid, float t, float3 normal, float3 baseColor, float flags, 
        float roughness,float3 emissive, float2 motionVec, bool transmissive, float ior, 
        float subsurface, float coat_weight, float3 coat_color, float coat_roughness,
        float coat_ior, float3 dpdu, float3 dpdv, float3 dndu, float3 dndv, 
        ConstantBuffer<cbGBufferRt> g_local)
    {
        RWTexture2D<float> g_outDepth = 
            ResourceDescriptorHeap[g_local.UavTableDescHeapIdx + (int)UAV_DESC_TABLE::DEPTH];
        g_outDepth[DTid] = t;

        RWTexture2D<float2> g_outNormal = 
            ResourceDescriptorHeap[g_local.UavTableDescHeapIdx + (int)UAV_DESC_TABLE::NORMAL];
        g_outNormal[DTid] = Math::EncodeUnitVector(normal);

        RWTexture2D<float4> g_outBaseColor = ResourceDescriptorHeap[g_local.UavTableDescHeapIdx];
        if(subsurface > 0)
            g_outBaseColor[DTid] = float4(baseColor, subsurface);
        else
            g_outBaseColor[DTid].rgb = baseColor;

        RWTexture2D<float2> g_outMetallicRoughness = 
            ResourceDescriptorHeap[g_local.UavTableDescHeapIdx + (int)UAV_DESC_TABLE::METALLIC_ROUGHNESS];
        g_outMetallicRoughness[DTid] = float2(flags, roughness);

        if(dot(emissive, emissive) > 0)
        {
            RWTexture2D<float3> g_outEmissive = 
                ResourceDescriptorHeap[g_local.UavTableDescHeapIdx + (int)UAV_DESC_TABLE::EMISSIVE];
            // R11G11B10 doesn't have a sign bit, make sure passed value is non-negative
            g_outEmissive[DTid] = max(0, emissive);
        }

        if(transmissive)
        {
            RWTexture2D<float> g_outIOR = 
                ResourceDescriptorHeap[g_local.UavTableDescHeapIdx + (int)UAV_DESC_TABLE::IOR];
            float ior_unorm = GBuffer::EncodeIOR(ior);
            g_outIOR[DTid] = ior_unorm;
        }

        if(coat_weight > 0)
        {
            RWTexture2D<uint4> g_outCoat = 
                ResourceDescriptorHeap[g_local.UavTableDescHeapIdx + (int)UAV_DESC_TABLE::COAT];

            uint3 packed;
            uint c = Math::Float3ToRGB8(coat_color);
            packed.x = (c & 0xffff);
            packed.y = (c >> 16) | (Math::FloatToUNorm8(coat_weight) << 8);

            float normalized = GBuffer::EncodeIOR(coat_ior);
            packed.z = Math::FloatToUNorm8(coat_roughness) | (Math::FloatToUNorm8(normalized) << 8);

            g_outCoat[DTid].xyz = packed;
        }

        RWTexture2D<float2> g_outMotion = 
            ResourceDescriptorHeap[g_local.UavTableDescHeapIdx + (int)UAV_DESC_TABLE::MOTION_VECTOR];
        g_outMotion[DTid] = motionVec;

        RWTexture2D<uint4> g_outTriGeo_A = 
            ResourceDescriptorHeap[g_local.UavTableDescHeapIdx + (int)UAV_DESC_TABLE::TRI_DIFF_GEO_A];
        RWTexture2D<uint2> g_outTriGeo_B = 
            ResourceDescriptorHeap[g_local.UavTableDescHeapIdx + (int)UAV_DESC_TABLE::TRI_DIFF_GEO_B];
        uint3 dpdu_h = asuint16(half3(dpdu));
        uint3 dpdv_h = asuint16(half3(dpdv));
        uint3 dndu_h = asuint16(half3(dndu));
        uint3 dndv_h = asuint16(half3(dndv));

        g_outTriGeo_A[DTid] = uint4(dpdu_h.x | (dpdu_h.y << 16),
            dpdu_h.z | (dpdv_h.x << 16),
            dpdv_h.y | (dpdv_h.z << 16),
            dndu_h.x | (dndu_h.y << 16));
        g_outTriGeo_B[DTid] = uint2(dndu_h.z | (dndv_h.x << 16), dndv_h.y | (dndv_h.z << 16));
    }

    void ApplyTextureMaps(uint2 DTid, float z_view, float3 wo, float2 uv, uint matIdx, 
        float3 geoNormal, float3 tangent, float2 motionVec, float4 grads, float3 dpdu, 
        float3 dpdv, float3 dndu, float3 dndv, ConstantBuffer<cbFrameConstants> g_frame, 
        ConstantBuffer<cbGBufferRt> g_local, StructuredBuffer<Material> g_materials)
    {
        const Material mat = g_materials[NonUniformResourceIndex(matIdx)];
        // Apply negative mip bias when upscaling
        grads *= g_frame.CameraRayUVGradsScale;

        float3 baseColor = mat.GetBaseColorFactor();
        float3 emissiveColor = mat.GetEmissiveFactor();
        float normalScale = mat.GetNormalScale();
        float metallic = mat.Metallic() ? 1.0f : 0.0f;
        float alphaCutoff = mat.GetAlphaCutoff();
        float roughness = mat.GetSpecularRoughness();
        float3 shadingNormal = geoNormal;

        const uint32_t baseColorTex = mat.GetBaseColorTex();
        const uint32_t normalTex = mat.GetNormalTex();
        const uint32_t metallicRoughnessTex = mat.GetMetallicRoughnessTex();

        if (baseColorTex != Material::INVALID_ID)
        {
            uint offset = NonUniformResourceIndex(g_frame.BaseColorMapsDescHeapOffset + 
                baseColorTex);
            BASE_COLOR_MAP g_baseCol = ResourceDescriptorHeap[offset];
            baseColor *= g_baseCol.SampleGrad(g_samAnisotropicWrap, uv, grads.xy, grads.zw).rgb;
        }

        // avoid normal mapping if tangent = (0, 0, 0), which results in NaN
        if (normalTex != Material::INVALID_ID && abs(dot(tangent, tangent)) > 1e-6)
        {
            uint offset = NonUniformResourceIndex(g_frame.NormalMapsDescHeapOffset + normalTex);
            NORMAL_MAP g_normalMap = ResourceDescriptorHeap[offset];
            float2 bump2 = g_normalMap.SampleGrad(g_samAnisotropicWrap, uv, grads.xy, grads.zw);

            shadingNormal = Math::TangentSpaceToWorldSpace(bump2, tangent, geoNormal, 
                normalScale);
        }

        // reverse normal for double-sided meshes if facing away from camera
        if (mat.DoubleSided() && dot(wo, geoNormal) < 0)
        {
            shadingNormal = -shadingNormal;
            dndu = -dndu;
            dndv = -dndv;
        }

        // Neighborhood around surface point (approximated by tangent plane from geometry normal) is visible, 
        // yet camera would be behind the tangent plane formed by bumped normal -- this can cause black spots 
        // as brdf evaluates to 0 in these regions. To mitigate the issue, rotate the bumped normal towards
        // wo until their dot product becomes greater than zero:
        //
        // 1. Project bumped normal onto plane formed by normal vector wo
        // 2. Slightly rotate the projection towards wo so that their dot product becomes greater than zero
#if 1
        if(dot(wo, geoNormal) > 0 && dot(wo, shadingNormal) < 0)
        {
            wo = normalize(wo);
            shadingNormal = shadingNormal - dot(shadingNormal, wo) * wo;
            shadingNormal = 1e-4f * wo + shadingNormal;
            shadingNormal = normalize(shadingNormal);
        }
#endif

        if (metallicRoughnessTex != Material::INVALID_ID)
        {
            uint offset = NonUniformResourceIndex(g_frame.MetallicRoughnessMapsDescHeapOffset + 
                metallicRoughnessTex);
            METALLIC_ROUGHNESS_MAP g_metallicRoughnessMap = ResourceDescriptorHeap[offset];
            float2 mr = g_metallicRoughnessMap.SampleGrad(g_samAnisotropicWrap, uv, grads.xy, grads.zw);

            metallic *= mr.x;
            roughness *= mr.y;
        }

        uint32_t emissiveTex = mat.GetEmissiveTex();
        float emissiveStrength = (float)mat.GetEmissiveStrength();

        if (emissiveTex != Material::INVALID_ID)
        {
            uint offset = NonUniformResourceIndex(g_frame.EmissiveMapsDescHeapOffset + emissiveTex);
            EMISSIVE_MAP g_emissiveMap = ResourceDescriptorHeap[offset];
            emissiveColor *= g_emissiveMap.SampleLevel(g_samLinearWrap, uv, 0).xyz;
        }

        emissiveColor *= emissiveStrength;

        // encode metalness along with some other stuff
        bool transmissive = mat.Transmissive();
        float ior = mat.GetSpecularIOR();
        float trDepth = transmissive ? (float)mat.GetTransmissionDepth() : 0;
        float subsurface = mat.ThinWalled() ? (float)mat.GetSubsurface() : 0;
        float coat_weight = mat.GetCoatWeight();
        float3 coat_color = mat.GetCoatColor();
        float coat_roughness = mat.GetCoatRoughness();
        float coat_ior = mat.GetCoatIOR();
        float encoded = GBuffer::EncodeMetallic(metallic, transmissive, emissiveColor, 
            trDepth, subsurface, coat_weight);

        WriteToGBuffers(DTid, z_view, shadingNormal, baseColor.rgb, encoded, 
            roughness, emissiveColor, motionVec, transmissive, ior, subsurface, 
            coat_weight, coat_color, coat_roughness, coat_ior,
            dpdu, dpdv, dndu, dndv, g_local);
    }
}