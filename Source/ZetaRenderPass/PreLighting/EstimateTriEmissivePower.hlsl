#include "PreLighting_Common.h"
#include "../Common/GBuffers.hlsli"
#include "../Common/LightSource.hlsli"

#define NUM_SAMPLES_PER_LANE (ESTIMATE_TRI_POWER_NUM_SAMPLES_PER_TRI / ESTIMATE_TRI_POWER_WAVE_LEN)

//--------------------------------------------------------------------------------------
// Root Signature
//--------------------------------------------------------------------------------------

ConstantBuffer<cbFrameConstants> g_frame : register(b1);
StructuredBuffer<RT::EmissiveTriangle> g_emissvies : register(t0);
StructuredBuffer<float2> g_halton : register(t2);
RWStructuredBuffer<float> g_power : register(u0);

//--------------------------------------------------------------------------------------
// Helper functions
//--------------------------------------------------------------------------------------

float TriangleArea(float3 vtx0, float3 vtx1, float3 vtx2)
{
    return 0.5f * length(cross(vtx1 - vtx0, vtx2 - vtx0));
}

//--------------------------------------------------------------------------------------
// Main
//--------------------------------------------------------------------------------------

[WaveSize(ESTIMATE_TRI_POWER_WAVE_LEN)]
[numthreads(ESTIMATE_TRI_POWER_GROUP_DIM_X, 1, 1)]
void main(uint3 DTid : SV_DispatchThreadID, uint3 Gid : SV_GroupID, uint Gidx : SV_GroupIndex)
{
    const uint wave = Gidx / ESTIMATE_TRI_POWER_WAVE_LEN;
    const uint triIdx = Gid.x * ESTIMATE_TRI_POWER_NUM_TRIS_PER_GROUP + wave;

    if (triIdx >= g_frame.NumEmissiveTriangles)
        return;

    const uint laneIdx = WaveGetLaneIndex();
    const RT::EmissiveTriangle tri = g_emissvies[triIdx];
    uint emissiveTex = tri.GetTex();

    float3 power = 0.0f;
    const bool hasTexture = emissiveTex != Material::INVALID_ID;

    if(hasTexture)
    {
        // no need for NonUniformResourceIndex, constant across the wave
        EMISSIVE_MAP g_emissiveMap = ResourceDescriptorHeap[g_frame.EmissiveMapsDescHeapOffset + emissiveTex];
        const uint base = laneIdx * NUM_SAMPLES_PER_LANE;
        float2 triUV10 = tri.UV1 - tri.UV0;
        float2 triUV20 = tri.UV2 - tri.UV0;
        int iNUM_SAMPLES_PER_LANE = (int)NUM_SAMPLES_PER_LANE;

        [unroll]
        for(int i = 0; i < iNUM_SAMPLES_PER_LANE; i++)
        {
            float2 u = g_halton[base + i];
            float2 bary = Sampling::UniformSampleTriangle(u);

            float2 texUV = tri.UV0 + bary.x * triUV10 + bary.y * triUV20;
            float3 le = g_emissiveMap.SampleLevel(g_samLinearWrap, texUV, 0).rgb;
            
            power += le;
        }
    }

    power = hasTexture ? WaveActiveSum(power) : ESTIMATE_TRI_POWER_NUM_SAMPLES_PER_TRI;

    const float3 emissiveFactor = tri.GetFactor();
    const float emissiveStrength = (float)tri.GetStrength();
    power *= emissiveFactor * emissiveStrength;

    if (laneIdx == 0)
    {
        const float3 vtx1 = Light::DecodeEmissiveTriV1(tri);
        const float3 vtx2 = Light::DecodeEmissiveTriV2(tri);
        const float surfaceArea = TriangleArea(tri.Vtx0, vtx1, vtx2);
        float mcEstimate = surfaceArea > 0 ? Math::Luminance(power) * PI * surfaceArea / (ESTIMATE_TRI_POWER_NUM_SAMPLES_PER_TRI) : 0;
        g_power[triIdx] = mcEstimate;
    }
}