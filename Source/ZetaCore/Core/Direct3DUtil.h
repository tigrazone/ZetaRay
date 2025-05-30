// Ref: Some of the following functions are from DirectXTK12 (MIT License):
// https://github.com/microsoft/DirectXTK12

#pragma once

#include "Device.h"
#include "../App/App.h"

namespace ZetaRay::App
{
    struct PoolAllocator;
}

namespace ZetaRay::Util
{
    template<typename T, Support::AllocatorType Allocator>
    class Vector;
}

namespace ZetaRay::Core::GpuMemory
{
    struct Texture;
    struct Buffer;
}

namespace ZetaRay::Support
{
    struct ArenaAllocator;
}

namespace ZetaRay::Core::Direct3DUtil
{
    enum class LOAD_DDS_RESULT
    {
        SUCCESS,
        FILE_NOT_FOUND,
        INVALID_DDS,
        INVALID_DDS_HEADER,
        MEM_ALLOC_FAILED,
        FILE_TOO_BIG,
        UNKNOWN,
        COUNT
    };

    struct DDS_HEADER;

    inline D3D12_HEAP_PROPERTIES UploadHeapProp()
    {
        D3D12_HEAP_PROPERTIES uploadHeap{
            .Type = D3D12_HEAP_TYPE_UPLOAD,
            .CPUPageProperty = D3D12_CPU_PAGE_PROPERTY_UNKNOWN,
            .MemoryPoolPreference = D3D12_MEMORY_POOL_UNKNOWN,
            .CreationNodeMask = 1,
            .VisibleNodeMask = 1 };

        return uploadHeap;
    }

    inline D3D12_HEAP_PROPERTIES DefaultHeapProp()
    {
        D3D12_HEAP_PROPERTIES defaultHeap{
            .Type = D3D12_HEAP_TYPE_DEFAULT,
            .CPUPageProperty = D3D12_CPU_PAGE_PROPERTY_UNKNOWN,
            .MemoryPoolPreference = D3D12_MEMORY_POOL_UNKNOWN,
            .CreationNodeMask = 1,
            .VisibleNodeMask = 1 };

        return defaultHeap;
    }

    inline D3D12_HEAP_PROPERTIES ReadbackHeapProp()
    {
        D3D12_HEAP_PROPERTIES defaultHeap{
            .Type = D3D12_HEAP_TYPE_READBACK,
            .CPUPageProperty = D3D12_CPU_PAGE_PROPERTY_UNKNOWN,
            .MemoryPoolPreference = D3D12_MEMORY_POOL_UNKNOWN,
            .CreationNodeMask = 1,
            .VisibleNodeMask = 1 };

        return defaultHeap;
    }

    inline D3D12_RESOURCE_DESC BufferResourceDesc(UINT64 w,
        D3D12_RESOURCE_FLAGS f = D3D12_RESOURCE_FLAG_NONE)
    {
        D3D12_RESOURCE_DESC bufferDesc;

        bufferDesc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
        bufferDesc.Alignment = 0;
        bufferDesc.Width = w;
        bufferDesc.Height = 1;
        bufferDesc.DepthOrArraySize = 1;
        bufferDesc.MipLevels = 1;
        bufferDesc.Format = DXGI_FORMAT_UNKNOWN;
        bufferDesc.SampleDesc.Count = 1;
        bufferDesc.SampleDesc.Quality = 0;
        bufferDesc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
        bufferDesc.Flags = f;

        return bufferDesc;
    }

    inline D3D12_RESOURCE_DESC1 BufferResourceDesc1(UINT64 w,
        D3D12_RESOURCE_FLAGS f = D3D12_RESOURCE_FLAG_NONE)
    {
        D3D12_RESOURCE_DESC1 bufferDesc;

        bufferDesc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
        bufferDesc.Alignment = 0;
        bufferDesc.Width = w;
        bufferDesc.Height = 1;
        bufferDesc.DepthOrArraySize = 1;
        bufferDesc.MipLevels = 1;
        bufferDesc.Format = DXGI_FORMAT_UNKNOWN;
        bufferDesc.SampleDesc.Count = 1;
        bufferDesc.SampleDesc.Quality = 0;
        bufferDesc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
        bufferDesc.Flags = f;

        return bufferDesc;
    }

    inline D3D12_RESOURCE_DESC Tex1D(DXGI_FORMAT format, UINT64 width,
        uint16_t arraySize = 1, uint16_t mipLevels = 1,
        D3D12_RESOURCE_FLAGS flags = D3D12_RESOURCE_FLAG_NONE,
        D3D12_TEXTURE_LAYOUT layout = D3D12_TEXTURE_LAYOUT_UNKNOWN,
        UINT64 alignment = 0)
    {
        D3D12_RESOURCE_DESC tex1DDesc;

        tex1DDesc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE1D;
        tex1DDesc.Format = format;
        tex1DDesc.Alignment = alignment;
        tex1DDesc.Width = width;
        tex1DDesc.Height = 1;
        tex1DDesc.MipLevels = mipLevels;
        tex1DDesc.DepthOrArraySize = arraySize;
        tex1DDesc.Flags = flags;
        tex1DDesc.Layout = layout;
        tex1DDesc.SampleDesc.Count = 1;
        tex1DDesc.SampleDesc.Quality = 0;

        return tex1DDesc;
    }

    inline D3D12_RESOURCE_DESC Tex2D(DXGI_FORMAT format, UINT64 width, UINT height,
        uint16_t arraySize = 1, uint16_t mipLevels = 1,
        D3D12_RESOURCE_FLAGS flags = D3D12_RESOURCE_FLAG_NONE,
        D3D12_TEXTURE_LAYOUT layout = D3D12_TEXTURE_LAYOUT_UNKNOWN,
        UINT64 alignment = 0)
    {
        D3D12_RESOURCE_DESC tex2DDesc;

        tex2DDesc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
        tex2DDesc.Format = format;
        tex2DDesc.Alignment = alignment;
        tex2DDesc.Width = width;
        tex2DDesc.Height = height;
        tex2DDesc.MipLevels = mipLevels;
        tex2DDesc.DepthOrArraySize = arraySize;
        tex2DDesc.Flags = flags;
        tex2DDesc.Layout = layout;
        tex2DDesc.SampleDesc.Count = 1;
        tex2DDesc.SampleDesc.Quality = 0;

        return tex2DDesc;
    }

    inline D3D12_RESOURCE_DESC1 Tex2D1(DXGI_FORMAT format, UINT64 width, UINT height,
        uint16_t arraySize = 1, uint16_t mipLevels = 1,
        D3D12_RESOURCE_FLAGS flags = D3D12_RESOURCE_FLAG_NONE,
        D3D12_TEXTURE_LAYOUT layout = D3D12_TEXTURE_LAYOUT_UNKNOWN,
        UINT64 alignment = 0)
    {
        D3D12_RESOURCE_DESC1 tex2DDesc;

        tex2DDesc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
        tex2DDesc.Format = format;
        tex2DDesc.Alignment = alignment;
        tex2DDesc.Width = width;
        tex2DDesc.Height = height;
        tex2DDesc.MipLevels = mipLevels;
        tex2DDesc.DepthOrArraySize = arraySize;
        tex2DDesc.Flags = flags;
        tex2DDesc.Layout = layout;
        tex2DDesc.SampleDesc.Count = 1;
        tex2DDesc.SampleDesc.Quality = 0;
        tex2DDesc.SamplerFeedbackMipRegion.Width = 0;
        tex2DDesc.SamplerFeedbackMipRegion.Height = 0;
        tex2DDesc.SamplerFeedbackMipRegion.Depth = 0;

        return tex2DDesc;
    }

    inline D3D12_RESOURCE_DESC Tex3D(DXGI_FORMAT format, UINT64 width, UINT height,
        uint16_t depth = 1, uint16_t mipLevels = 1,
        D3D12_RESOURCE_FLAGS flags = D3D12_RESOURCE_FLAG_NONE,
        D3D12_TEXTURE_LAYOUT layout = D3D12_TEXTURE_LAYOUT_UNKNOWN,
        UINT64 alignment = 0)
    {
        D3D12_RESOURCE_DESC tex2DDesc;

        tex2DDesc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE3D;
        tex2DDesc.Format = format;
        tex2DDesc.Alignment = alignment;
        tex2DDesc.Width = width;
        tex2DDesc.Height = height;
        tex2DDesc.MipLevels = mipLevels;
        tex2DDesc.DepthOrArraySize = depth;
        tex2DDesc.Flags = flags;
        tex2DDesc.Layout = layout;
        tex2DDesc.SampleDesc.Count = 1;
        tex2DDesc.SampleDesc.Quality = 0;

        return tex2DDesc;
    }

    D3D12_RESOURCE_ALLOCATION_INFO AllocationInfo(D3D12_RESOURCE_DESC& desc);
    D3D12_RESOURCE_ALLOCATION_INFO AllocationInfo(Util::Span<D3D12_RESOURCE_DESC1> descs, 
        Util::MutableSpan<D3D12_RESOURCE_ALLOCATION_INFO1> infos);

    inline D3D12_RESOURCE_BARRIER TransitionBarrier(ID3D12Resource* res,
        D3D12_RESOURCE_STATES before,
        D3D12_RESOURCE_STATES after,
        UINT subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES,
        D3D12_RESOURCE_BARRIER_FLAGS flags = D3D12_RESOURCE_BARRIER_FLAG_NONE)
    {
        D3D12_RESOURCE_BARRIER barrier{};

        barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
        barrier.Transition.pResource = res;
        barrier.Transition.StateBefore = before;
        barrier.Transition.StateAfter = after;
        barrier.Transition.Subresource = subresource;
        barrier.Flags = flags;

        return barrier;
    }

    inline D3D12_BUFFER_BARRIER BufferBarrier(ID3D12Resource* res,
        D3D12_BARRIER_SYNC syncBefore,
        D3D12_BARRIER_SYNC syncAfter,
        D3D12_BARRIER_ACCESS accessBefore,
        D3D12_BARRIER_ACCESS accessAfter)
    {
        return D3D12_BUFFER_BARRIER{ .SyncBefore = syncBefore,
            .SyncAfter = syncAfter,
            .AccessBefore = accessBefore,
            .AccessAfter = accessAfter,
            .pResource = res,
            .Offset = 0,
            .Size = UINT64_MAX };
    }

    inline D3D12_TEXTURE_BARRIER TextureBarrier(ID3D12Resource* res,
        D3D12_BARRIER_SYNC syncBefore,
        D3D12_BARRIER_SYNC syncAfter,
        D3D12_BARRIER_LAYOUT layoutBefore,
        D3D12_BARRIER_LAYOUT layoutAfter,
        D3D12_BARRIER_ACCESS accessBefore,
        D3D12_BARRIER_ACCESS accessAfter,
        UINT subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES)
    {
        D3D12_BARRIER_SUBRESOURCE_RANGE range;
        range.NumMipLevels = 0;
        range.IndexOrFirstMipLevel = subresource;

        D3D12_TEXTURE_BARRIER barrier;
        barrier.pResource = res;
        barrier.SyncBefore = syncBefore;
        barrier.SyncAfter = syncAfter;
        barrier.AccessBefore = accessBefore;
        barrier.AccessAfter = accessAfter;
        barrier.LayoutBefore = layoutBefore;
        barrier.LayoutAfter = layoutAfter;
        barrier.Subresources.NumMipLevels = 0;
        barrier.Subresources.IndexOrFirstMipLevel = subresource;
        barrier.Flags = D3D12_TEXTURE_BARRIER_FLAG_NONE;
        
        return barrier;
    }

    inline D3D12_BARRIER_GROUP BarrierGroup(D3D12_BUFFER_BARRIER& barrier)
    {
        D3D12_BARRIER_GROUP group;
        group.Type = D3D12_BARRIER_TYPE_BUFFER;
        group.NumBarriers = 1;
        group.pBufferBarriers = &barrier;

        return group;
    }

    inline D3D12_BARRIER_GROUP BarrierGroup(D3D12_BUFFER_BARRIER* barriers, uint32_t numBarriers)
    {
        D3D12_BARRIER_GROUP group;
        group.Type = D3D12_BARRIER_TYPE_BUFFER;
        group.NumBarriers = numBarriers;
        group.pBufferBarriers = barriers;

        return group;
    }    

    inline D3D12_BARRIER_GROUP BarrierGroup(D3D12_TEXTURE_BARRIER& barrier)
    {
        D3D12_BARRIER_GROUP group;
        group.Type = D3D12_BARRIER_TYPE_TEXTURE;
        group.NumBarriers = 1;
        group.pTextureBarriers = &barrier;

        return group;
    }

    inline D3D12_BARRIER_GROUP BarrierGroup(D3D12_TEXTURE_BARRIER* barriers, uint32_t numBarriers)
    {
        D3D12_BARRIER_GROUP group;
        group.Type = D3D12_BARRIER_TYPE_TEXTURE;
        group.NumBarriers = numBarriers;
        group.pTextureBarriers = barriers;

        return group;
    }

    inline D3D12_RESOURCE_BARRIER UAVBarrier(ID3D12Resource* res)
    {
        D3D12_RESOURCE_BARRIER barrier{};

        barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_UAV;
        barrier.Flags = D3D12_RESOURCE_BARRIER_FLAG_NONE;
        barrier.UAV.pResource = res;

        return barrier;
    }

    // Convenience methods for common texture barriers
    inline D3D12_TEXTURE_BARRIER TextureBarrier_SrvToUavNoSync(ID3D12Resource* res,
        bool directQueue = true,
        UINT subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES)
    {
        D3D12_BARRIER_SUBRESOURCE_RANGE range;
        range.NumMipLevels = 0;
        range.IndexOrFirstMipLevel = subresource;

        D3D12_TEXTURE_BARRIER barrier;
        barrier.pResource = res;
        barrier.SyncBefore = D3D12_BARRIER_SYNC_NONE;
        barrier.SyncAfter = D3D12_BARRIER_SYNC_COMPUTE_SHADING;
        // D3D12_BARRIER_SYNC_NONE is always paired with D3D12_BARRIER_ACCESS_NO_ACCESS
        barrier.AccessBefore = D3D12_BARRIER_ACCESS_NO_ACCESS;
        barrier.AccessAfter = D3D12_BARRIER_ACCESS_UNORDERED_ACCESS;
        barrier.LayoutBefore = directQueue ?
            D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_SHADER_RESOURCE :
            D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_SHADER_RESOURCE;
        // UAV access must be paired with D3D12_BARRIER_LAYOUT_QUEUE_UNORDERED_ACCESS
        barrier.LayoutAfter = directQueue ?
            D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_UNORDERED_ACCESS :
            D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_UNORDERED_ACCESS;
        barrier.Subresources.NumMipLevels = 0;
        barrier.Subresources.IndexOrFirstMipLevel = subresource;
        barrier.Flags = D3D12_TEXTURE_BARRIER_FLAG_NONE;

        return barrier;
    }

    inline D3D12_TEXTURE_BARRIER TextureBarrier_SrvToUavWithSync(ID3D12Resource* res,
        bool directQueue = true,
        UINT subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES)
    {
        D3D12_BARRIER_SUBRESOURCE_RANGE range;
        range.NumMipLevels = 0;
        range.IndexOrFirstMipLevel = subresource;

        D3D12_TEXTURE_BARRIER barrier;
        barrier.pResource = res;
        barrier.SyncBefore = D3D12_BARRIER_SYNC_COMPUTE_SHADING;
        barrier.SyncAfter = D3D12_BARRIER_SYNC_COMPUTE_SHADING;
        barrier.AccessBefore = D3D12_BARRIER_ACCESS_SHADER_RESOURCE;
        barrier.AccessAfter = D3D12_BARRIER_ACCESS_UNORDERED_ACCESS;
        barrier.LayoutBefore = directQueue ? 
            D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_SHADER_RESOURCE:
            D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_SHADER_RESOURCE;
        // UAV access must be paired with D3D12_BARRIER_LAYOUT_QUEUE_UNORDERED_ACCESS
        barrier.LayoutAfter = directQueue ? 
            D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_UNORDERED_ACCESS:
            D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_UNORDERED_ACCESS;
        barrier.Subresources.NumMipLevels = 0;
        barrier.Subresources.IndexOrFirstMipLevel = subresource;
        barrier.Flags = D3D12_TEXTURE_BARRIER_FLAG_NONE;

        return barrier;
    }

    inline D3D12_TEXTURE_BARRIER TextureBarrier_UavToSrvNoSync(ID3D12Resource* res,
        bool directQueue = true,
        UINT subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES)
    {
        D3D12_BARRIER_SUBRESOURCE_RANGE range;
        range.NumMipLevels = 0;
        range.IndexOrFirstMipLevel = subresource;

        D3D12_TEXTURE_BARRIER barrier;
        barrier.pResource = res;
        barrier.SyncBefore = D3D12_BARRIER_SYNC_NONE;
        barrier.SyncAfter = D3D12_BARRIER_SYNC_COMPUTE_SHADING;
        // D3D12_BARRIER_SYNC_NONE is always paired with D3D12_BARRIER_ACCESS_NO_ACCESS
        barrier.AccessBefore = D3D12_BARRIER_ACCESS_NO_ACCESS;
        barrier.AccessAfter = D3D12_BARRIER_ACCESS_SHADER_RESOURCE;
        // UAV access must be paired with D3D12_BARRIER_LAYOUT_QUEUE_UNORDERED_ACCESS
        barrier.LayoutBefore = directQueue ?
            D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_UNORDERED_ACCESS :
            D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_UNORDERED_ACCESS;
        barrier.LayoutAfter = directQueue ?
            D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_SHADER_RESOURCE :
            D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_SHADER_RESOURCE;
        barrier.Subresources.NumMipLevels = 0;
        barrier.Subresources.IndexOrFirstMipLevel = subresource;
        barrier.Flags = D3D12_TEXTURE_BARRIER_FLAG_NONE;

        return barrier;
    }    
    
    inline D3D12_TEXTURE_BARRIER TextureBarrier_UavToSrvWithSync(ID3D12Resource* res,
        bool directQueue = true,
        UINT subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES)
    {
        D3D12_BARRIER_SUBRESOURCE_RANGE range;
        range.NumMipLevels = 0;
        range.IndexOrFirstMipLevel = subresource;

        D3D12_TEXTURE_BARRIER barrier;
        barrier.pResource = res;
        barrier.SyncBefore = D3D12_BARRIER_SYNC_COMPUTE_SHADING;
        barrier.SyncAfter = D3D12_BARRIER_SYNC_COMPUTE_SHADING;
        barrier.AccessBefore = D3D12_BARRIER_ACCESS_UNORDERED_ACCESS;
        barrier.AccessAfter = D3D12_BARRIER_ACCESS_SHADER_RESOURCE;
        // UAV access must be paired with D3D12_BARRIER_LAYOUT_QUEUE_UNORDERED_ACCESS
        barrier.LayoutBefore = directQueue ?
            D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_UNORDERED_ACCESS :
            D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_UNORDERED_ACCESS;
        barrier.LayoutAfter = directQueue ?
            D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_SHADER_RESOURCE :
            D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_SHADER_RESOURCE;
        barrier.Subresources.NumMipLevels = 0;
        barrier.Subresources.IndexOrFirstMipLevel = subresource;
        barrier.Flags = D3D12_TEXTURE_BARRIER_FLAG_NONE;

        return barrier;
    }

    inline D3D12_TEXTURE_BARRIER UAVBarrier1(ID3D12Resource* res,
        bool directQueue = true,
        UINT subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES)
    {
        D3D12_BARRIER_SUBRESOURCE_RANGE range;
        range.NumMipLevels = 0;
        range.IndexOrFirstMipLevel = subresource;

        D3D12_TEXTURE_BARRIER barrier;
        barrier.pResource = res;
        barrier.SyncBefore = D3D12_BARRIER_SYNC_COMPUTE_SHADING;
        barrier.SyncAfter = D3D12_BARRIER_SYNC_COMPUTE_SHADING;
        barrier.AccessBefore = D3D12_BARRIER_ACCESS_UNORDERED_ACCESS;
        barrier.AccessAfter = D3D12_BARRIER_ACCESS_UNORDERED_ACCESS;
        barrier.LayoutBefore = directQueue ?
            D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_UNORDERED_ACCESS :
            D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_UNORDERED_ACCESS;
        barrier.LayoutAfter = directQueue ?
            D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_UNORDERED_ACCESS :
            D3D12_BARRIER_LAYOUT_COMPUTE_QUEUE_UNORDERED_ACCESS;
        barrier.Subresources.NumMipLevels = 0;
        barrier.Subresources.IndexOrFirstMipLevel = subresource;
        barrier.Flags = D3D12_TEXTURE_BARRIER_FLAG_NONE;

        return barrier;
    }

    // Return the BPP for a particular format
    size_t BitsPerPixel(DXGI_FORMAT fmt);

    // Get surface information for a particular format
    HRESULT GetSurfaceInfo(size_t width,
        size_t height,
        DXGI_FORMAT fmt,
        size_t* outNumBytes,
        size_t* outRowBytes,
        size_t* outNumRows);

    // Returns required size of a buffer to be used for data upload
    UINT64 GetRequiredIntermediateSize(ID3D12Resource* destinationResource, UINT firstSubresource,
        UINT numSubresources);

    inline D3D12_BLEND_DESC DefaultBlendDesc()
    {
        D3D12_BLEND_DESC desc{};
        desc.AlphaToCoverageEnable = false;
        desc.IndependentBlendEnable = false;

        D3D12_RENDER_TARGET_BLEND_DESC rtBlendDesc{};
        rtBlendDesc.BlendEnable = false;
        rtBlendDesc.LogicOpEnable = false;
        rtBlendDesc.SrcBlend = D3D12_BLEND_ONE;
        rtBlendDesc.DestBlend = D3D12_BLEND_ZERO;
        rtBlendDesc.BlendOp = D3D12_BLEND_OP_ADD;
        rtBlendDesc.SrcBlendAlpha = D3D12_BLEND_ONE;
        rtBlendDesc.DestBlendAlpha = D3D12_BLEND_ZERO;
        rtBlendDesc.BlendOpAlpha = D3D12_BLEND_OP_ADD;
        rtBlendDesc.LogicOp = D3D12_LOGIC_OP_NOOP;
        rtBlendDesc.RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;

        for (int i = 0; i < D3D12_SIMULTANEOUS_RENDER_TARGET_COUNT; i++)
            desc.RenderTarget[i] = rtBlendDesc;

        return desc;
    }

    inline D3D12_RASTERIZER_DESC DefaultRasterizerDesc()
    {
        D3D12_RASTERIZER_DESC desc{};

        desc.FillMode = D3D12_FILL_MODE_SOLID;
        desc.CullMode = D3D12_CULL_MODE_BACK;
        desc.FrontCounterClockwise = false;
        desc.DepthBias = D3D12_DEFAULT_DEPTH_BIAS;
        desc.DepthBiasClamp = D3D12_DEFAULT_DEPTH_BIAS_CLAMP;
        desc.SlopeScaledDepthBias = D3D12_DEFAULT_SLOPE_SCALED_DEPTH_BIAS;
        desc.DepthClipEnable = true;
        desc.MultisampleEnable = false;
        desc.AntialiasedLineEnable = false;
        desc.ForcedSampleCount = 0;
        desc.ConservativeRaster = D3D12_CONSERVATIVE_RASTERIZATION_MODE_OFF;

        return desc;
    }

    inline D3D12_DEPTH_STENCIL_DESC DefaultDepthStencilDesc()
    {
        D3D12_DEPTH_STENCIL_DESC desc{};
        desc.DepthEnable = true;
        desc.DepthWriteMask = D3D12_DEPTH_WRITE_MASK_ALL;
        desc.DepthFunc = D3D12_COMPARISON_FUNC_LESS;
        desc.StencilEnable = false;
        desc.StencilReadMask = D3D12_DEFAULT_STENCIL_READ_MASK;
        desc.StencilWriteMask = D3D12_DEFAULT_STENCIL_WRITE_MASK;

        D3D12_DEPTH_STENCILOP_DESC defaultStencilOp{};
        defaultStencilOp.StencilFailOp = D3D12_STENCIL_OP_KEEP;
        defaultStencilOp.StencilDepthFailOp = D3D12_STENCIL_OP_KEEP;
        defaultStencilOp.StencilPassOp = D3D12_STENCIL_OP_KEEP;
        defaultStencilOp.StencilFunc = D3D12_COMPARISON_FUNC_ALWAYS;

        desc.FrontFace = defaultStencilOp;
        desc.BackFace = defaultStencilOp;

        return desc;
    }

    inline constexpr DXGI_FORMAT NoSRGB(DXGI_FORMAT fmt)
    {
        switch (fmt)
        {
        case DXGI_FORMAT_R8G8B8A8_UNORM_SRGB:
            return DXGI_FORMAT_R8G8B8A8_UNORM;
        case DXGI_FORMAT_B8G8R8A8_UNORM_SRGB:
            return DXGI_FORMAT_B8G8R8A8_UNORM;
        case DXGI_FORMAT_B8G8R8X8_UNORM_SRGB:
            return DXGI_FORMAT_B8G8R8X8_UNORM;
        default:
            return fmt;
        }
    }

    LOAD_DDS_RESULT LoadDDSFromFile(const char* path,
        Util::MutableSpan<D3D12_SUBRESOURCE_DATA> subresources,
        DXGI_FORMAT& format,
        Support::ArenaAllocator allocator,
        uint32_t& width,
        uint32_t& height,
        uint32_t& depth,
        uint16_t& mipCount,
        uint32_t& numSubresources);

    D3D12_GRAPHICS_PIPELINE_STATE_DESC GetPSODesc(const D3D12_INPUT_LAYOUT_DESC* inputLayout,
        int numRenderTargets,
        DXGI_FORMAT* rtvFormats,
        DXGI_FORMAT dsvFormat = DXGI_FORMAT_UNKNOWN,
        D3D12_DEPTH_STENCIL_DESC* depthStencilDesc = nullptr,
        D3D12_RASTERIZER_DESC* rasterizerDesc = nullptr,
        D3D12_BLEND_DESC* blendDesc = nullptr,
        D3D12_PRIMITIVE_TOPOLOGY_TYPE primitiveTopology = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE);

    uint64_t GetPSODescHash(D3D12_GRAPHICS_PIPELINE_STATE_DESC& desc);

    void CreateGraphicsPSO(D3D12_GRAPHICS_PIPELINE_STATE_DESC& psDesc,
        ID3D12RootSignature* rootSignature,
        const D3D12_SHADER_BYTECODE* vertexShader,
        const D3D12_SHADER_BYTECODE* pixelShader,
        const D3D12_SHADER_BYTECODE* hullShader,
        const D3D12_SHADER_BYTECODE* domainShader,
        ID3D12PipelineState** pPipelineState);

    void CreateBufferSRV(const GpuMemory::Buffer& buff, D3D12_CPU_DESCRIPTOR_HANDLE cpuHandle,
        UINT stride, UINT numElements);
    void CreateBufferUAV(const GpuMemory::Buffer& buff, D3D12_CPU_DESCRIPTOR_HANDLE cpuHandle,
        UINT stride, UINT numElements);
    void CreateRawBufferUAV(const GpuMemory::Buffer& buff, D3D12_CPU_DESCRIPTOR_HANDLE cpuHandle,
        UINT stride, UINT numElements);
    void CreateTexture2DSRV(ID3D12Resource* t, D3D12_CPU_DESCRIPTOR_HANDLE cpuHandle, 
        DXGI_FORMAT f = DXGI_FORMAT_UNKNOWN, float minLODClamp = 0.0f, 
        UINT mostDetailedMip = 0, UINT planeSlice = 0);
    void CreateTexture2DSRV(const GpuMemory::Texture& t, D3D12_CPU_DESCRIPTOR_HANDLE cpuHandle, 
        DXGI_FORMAT f = DXGI_FORMAT_UNKNOWN, float minLODClamp = 0.0f, 
        UINT mostDetailedMip = 0, UINT planeSlice = 0);
    void CreateTexture3DSRV(const GpuMemory::Texture& t, D3D12_CPU_DESCRIPTOR_HANDLE cpuHandle, 
        DXGI_FORMAT f = DXGI_FORMAT_UNKNOWN, float minLODClamp = 0.0f, UINT mostDetailedMip = 0, 
        UINT planeSlice = 0);
    void CreateTexture2DUAV(const GpuMemory::Texture& t, D3D12_CPU_DESCRIPTOR_HANDLE cpuHandle, 
        DXGI_FORMAT f = DXGI_FORMAT_UNKNOWN, UINT mipSlice = 0, UINT planeSlice = 0);
    void CreateTexture3DUAV(const GpuMemory::Texture& t, D3D12_CPU_DESCRIPTOR_HANDLE cpuHandle, 
        DXGI_FORMAT f = DXGI_FORMAT_UNKNOWN, UINT mipSlice = 0, UINT numSlices = 0, 
        UINT firstSliceIdx = 0);
    void CreateRTV(const GpuMemory::Texture& t, D3D12_CPU_DESCRIPTOR_HANDLE cpuHandle, 
        DXGI_FORMAT f = DXGI_FORMAT_UNKNOWN, UINT mipSlice = 0, UINT planeSlice = 0);
}