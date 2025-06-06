#ifndef MATH_H
#define MATH_H

#define PI                   3.141592654f
#define TWO_PI               6.283185307f
#define PI_OVER_2            1.570796327f
#define PI_OVER_4            0.7853981635f
#define THREE_PI_OVER_2      4.7123889804f
#define ONE_OVER_PI          0.318309886f
#define ONE_OVER_2_PI        0.159154943f
#define ONE_OVER_4_PI        0.079577472f
#define TWO_OVER_PI          0.636619772f
#define FLT_MIN              1.175494351e-38 
#define FLT_MAX              3.402823466e+38 
#define FLT16_MAX            65504 
#define UINT8_MAX            0xffu
#define UINT16_MAX           0xffffu
#define UINT32_MAX           0xffffffffu

#define NEARzero 1e-25f
#define isZERO(x) ((x)>-NEARzero && (x)<NEARzero)
#define isNotZERO(x) ((x)>NEARzero || (x)<-NEARzero)

#define float_1_16      65535.0f
#define float_1_16_     1.5259021896696421759365224689097e-5f

namespace Math
{
    // Returns whether pos is in [0, dim).
    template<typename T>
    bool IsWithinBounds(T pos, T dim)
    {
        return all(pos >= 0) && all(pos < dim);
    }

    // Returns smallest float value f' such that f' > f.
    float NextFloat32(float f)
    {
        if(f == -0.0f)
            f = 0.0f;

        uint u = asuint(f);
        u = f >= 0 ? u + 1 : u - 1;
    
        return asfloat(u);
    }

    // Returns largest float value f' such that f' < f.
    float PrevFloat32(float f)
    {
        if(isZERO(f))
            f = -0.0f;

        uint u = asuint(f);
        u = f > 0 ? u - 1 : u + 1;
    
        return asfloat(u);
    }

    uint RoundUpToPowerOf2(uint x)
    {
        x--;
        x |= x >> 1;
        x |= x >> 2;
        x |= x >> 4;
        x |= x >> 8;
        x |= x >> 16;
        x++;

        return x;
    }

    template<typename T>
    T Lerp(T v0, T v1, float t) 
    {
        return mad(t, v1, mad(-t, v0, v0));
    }

    template<typename T>
    T Sanitize(T x)
    {
        return any(isnan(x)) || any(isinf(x)) ? 0 : x;
    }

    float3x3 Inverse(float3x3 M)
    {
        // Given 3x3 matrix M = [u, v, w] where u,v,w are column vectors, M^(-1) is given by
        //        M^(-1) = [a b c]^T
        //
        // where 
        //        a = (v * w) / u.(v * w)
        //        b = (w * u) / u.(v * w)
        //        c = (u * v) / u.(v * w)        
        const float3 u = float3(M._11, M._21, M._31);
        const float3 v = float3(M._12, M._22, M._32);
        const float3 w = float3(M._13, M._23, M._33);

        const float3 vCrossW = cross(v, w);
        const float det = dot(u, vCrossW);

        const float3 a = vCrossW / det;
        const float3 b = cross(w, u) / det;
        const float3 c = cross(u, v) / det;

        return float3x3(a, b, c);
    }

    // Input in [-1, 1] and output in [0, PI]
    // Ref: https://seblagarde.wordpress.com/2014/12/01/inverse-trigonometric-functions-gpu-optimization-for-amd-gcn-architecture/
    template<typename T>
    T ArcCos(T x)
    {
        T xAbs = abs(x);
        T res = mad(-0.0206453f, xAbs, 0.0764532f);
        res = mad(res, xAbs, -0.21271f);
        res = mad(res, xAbs, 1.57075f);
        res *= sqrt(1.0f - xAbs);

        return select((x >= 0), res, PI - res);
    }

    float3 SphericalToCartesian(float r, float theta, float phi)
    {
        float r_sinTheta = r * sin(theta);
        return float3(r_sinTheta * cos(phi), r * cos(theta), -r_sinTheta * sin(phi));
    }

    float2 SphericalFromCartesian(float3 w)
    {
        float2 thetaPhi;

        // x = sin(theta) * cos(phi)
        // y = cos(theta)
        // z = -sin(theta) * sin(phi)
        thetaPhi.x = ArcCos(w.y);
        // phi is measured clockwise from the x-axis and atan2 uses the sign to figure out the quadrant
        thetaPhi.y = atan2(-w.z, w.x);                                    // [-PI, +PI]
        thetaPhi.y = thetaPhi.y < 0 ? thetaPhi.y + TWO_PI : thetaPhi.y;   // [0, 2 * PI]

        return thetaPhi;
    }

    float TriangleArea(float3 v0, float3 v1, float3 v2)
    {
        return 0.5f * length(cross(v1 - v0, v2 - v0));
    }

    // Returns -1.0 when v < 0 and +1.0 otherwise
    template<typename T>
    T SignNotZero(T v) 
    {
        return select(v >= 0, +1.0f, -1.0f);
    }

    template<>
    float SignNotZero(float x)
    {
        // asfloat(0x3f800000) = +1.0 
        // asfloat(0x80000000) = -0.0 
        uint s = 0x3f800000 | (0x80000000 & asuint(x));
        return asfloat(s);
    }

    template<typename T>
    T LinearDepthFromNDC(T z_NDC, float near)
    {
        return select(isZERO(z_NDC), FLT_MAX, near / z_NDC);
    }

    float2 NDCFromUV(float2 uv)
    {
        uv += uv - 1.0f;
        uv.y = -uv.y;

        return uv;
    }

    float2 UVFromNDC(float2 ndc)
    {
        return ndc * float2(0.5, -0.5) + 0.5f;
    }

    float2 ScreenSpaceFromNDC(float2 ndc, float2 renderDim)
    {
        // [-1, 1] * [-1, 1] -> [0, 1] * [0, 1]
        float2 posSS = ndc * float2(0.5f, -0.5f) + 0.5f;
        posSS *= renderDim;

        return posSS;
    }

    float2 UVFromScreenSpace(uint2 posSS, float2 renderDim)
    {
        float2 uv = float2(posSS) + 0.5f;
        uv /= renderDim;

        return uv;
    }

    float3 WorldPosFromUV(float2 uv, float2 renderDim, float z_view, float tanHalfFOV, 
        float aspectRatio, float3x4 viewInv, float2 jitter)
    {
        float2 ndc = NDCFromUV(uv) + jitter / renderDim;
        float3 dir_v = float3(ndc.x * aspectRatio * tanHalfFOV * z_view, 
            ndc.y * tanHalfFOV * z_view, 
            z_view);
        float3 pos_w = mul(viewInv, float4(dir_v, 1.0f));

        return pos_w;
    }

    float3 WorldPosFromScreenSpace(float2 pos_ss, float2 renderDim, float z_view, float tanHalfFOV,
        float aspectRatio, float3x4 viewInv, float2 jitter)
    {
        float2 uv = (pos_ss + 0.5f + jitter) / renderDim;
        float2 ndc = NDCFromUV(uv);
        float3 dir_v = float3(ndc.x * aspectRatio * tanHalfFOV * z_view, 
            ndc.y * tanHalfFOV * z_view, 
            z_view);
        float3 pos_w = mul(viewInv, float4(dir_v, 1.0f));

        return pos_w;
    }

    float3 WorldPosFromScreenSpace2(float2 pos_ss, float2 renderDim, float z_view, float tanHalfFOV,
        float aspectRatio, float2 jitter, float3 viewBasisX, float3 viewBasisY, float3 viewBasisZ, 
        bool thinLens, float2 lensSample, float focusDepth, inout float3 origin)
    {
        float2 uv = (pos_ss + 0.5f + jitter) / renderDim;
        float2 ndc = NDCFromUV(uv);
        float3 dir_w;

        if(!thinLens)
        {
            float3 dir_v = float3(ndc.x * aspectRatio * tanHalfFOV * z_view, 
                ndc.y * tanHalfFOV * z_view, 
                z_view);
            dir_w = mad(dir_v.x, viewBasisX, mad(dir_v.y, viewBasisY, dir_v.z * viewBasisZ));
        }
        else
        {
            float3 dir_v = float3(ndc.x * aspectRatio * tanHalfFOV, ndc.y * tanHalfFOV, 1);
            float3 focalPoint = focusDepth * dir_v;
            dir_v = focalPoint - float3(lensSample, 0);

            dir_w = mad(dir_v.x, viewBasisX, mad(dir_v.y, viewBasisY, dir_v.z * viewBasisZ));
            dir_w = normalize(dir_w);
            // For thin lens, z_view = t_hit
            dir_w *= z_view;

            origin += mad(lensSample.x, viewBasisX, lensSample.y * viewBasisY);
        }

        return origin + dir_w;
    }

    float2 UVFromWorldPos(float3 posW, float2 renderDim, float tanHalfFOV, float aspectRatio, 
        float3x4 view, float2 jitter = 0.0)
    {
        float3 posV = mul(view, float4(posW, 1.0f));
        float2 ndc = posV.xy / (tanHalfFOV * posV.z);
        ndc.x /= aspectRatio;

        float2 uv = Math::UVFromNDC(ndc);
        uv += jitter / renderDim;

        return uv;
    }

    float3 TangentSpaceToWorldSpace(float2 bumpNormal2, float3 tangent, float3 normal, float scale)
    {
        float3 scaledBumpNormal = float3((bumpNormal2 + bumpNormal2 - 1.0f) * scale, 0.0f);
        scaledBumpNormal.z = sqrt(saturate(1.0f - dot(scaledBumpNormal, scaledBumpNormal)));

        // Invalid scale or bump, normalize() leads to NaN
        if (dot(scaledBumpNormal, scaledBumpNormal) < 1e-6f)
            return normal;

        scaledBumpNormal = normalize(scaledBumpNormal);

        // Graham-Schmidt orthogonalization
        normal = normalize(normal);
        tangent = normalize(tangent - dot(tangent, normal) * normal);

        // Change-of-coordinate transformation from TBN to world space
        float3 bitangent = cross(normal, tangent);
        float3x3 TangentSpaceToWorld = float3x3(tangent, bitangent, normal);

        return mul(scaledBumpNormal, TangentSpaceToWorld);
    }

    /*
    This uses the technique from "Improved accuracy when building an orthonormal
    basis" by Nelson Max, https://jcgt.org/published/0006/01/02.

    Any tangent-generating algorithm must produce at least one discontinuity
    when operating on a sphere (due to the hairy ball theorem); this has a
    small ring-shaped discontinuity at `normal.z == -0.99998796`.
    */
    struct CoordinateSystem
    {
        static CoordinateSystem Build(float3 normal)
        {
            CoordinateSystem ret;

            if(normal.z < -0.99998796)  // Handle the singularity
            {
              ret.b1 = float3(0.0, -1.0, 0.0);
              ret.b2 = float3(-1.0, 0.0, 0.0);
              return ret;
            }
            
            float inv_1plus_nz = 1.0 / (1.0 + normal.z);
            float nxa = -normal.x * inv_1plus_nz;
            ret.b1 = float3(mad(normal.x, nxa, 1.0f), nxa * normal.y, -normal.x);
            ret.b2 = float3(ret.b1.y, 1.0 - normal.y * normal.y * inv_1plus_nz, -normal.y);

            return ret;
        }

        float3 b1;
        float3 b2;
    };

    float3 WorldToTangentFrame(float3 normal, float3 w)
    {
        CoordinateSystem onb = CoordinateSystem::Build(normal);
        float3x3 worldToLocal = float3x3(onb.b1, onb.b2, normal);

        return mul(worldToLocal, w);
    }

    float3 FromTangentFrameToWorld(float3 normal, float3 w_local)
    {
        CoordinateSystem onb = CoordinateSystem::Build(normal);
        float3x3 localToWorld_T = float3x3(onb.b1, onb.b2, normal);

        return mul(w_local, localToWorld_T);
    }

    // Ref: M. Pharr, W. Jakob, and G. Humphreys, Physically Based Rendering, Morgan Kaufmann, 2016.
    struct TriDifferentials
    {
        static TriDifferentials Unpack(uint4 packed_a, uint2 packed_b)
        {
            TriDifferentials ret;

            ret.dpdu = asfloat16(uint16_t3(packed_a.x & 0xffff, packed_a.x >> 16, packed_a.y & 0xffff));
            ret.dpdv = asfloat16(uint16_t3(packed_a.y >> 16, packed_a.z & 0xffff, packed_a.z >> 16));
            ret.dndu = asfloat16(uint16_t3(packed_a.w & 0xffff, packed_a.w >> 16, packed_b.x & 0xffff));
            ret.dndv = asfloat16(uint16_t3(packed_b.x >> 16, packed_b.y & 0xffff, packed_b.y >> 16));

            return ret;
        }

        static TriDifferentials Compute(float3 p0, float3 p1, float3 p2, 
            float3 n0, float3 n1, float3 n2,
            float2 uv0, float2 uv1, float2 uv2)
        {
            TriDifferentials ret;

            // For triangle with vertices (p0, p1, p2) and UV coords
            // (uv0, uv1, uv2) (CW), we have the following first-order
            // representation:
            //          A             =       X                     B
            // |                 |      |           |    |                     |
            // | p1 - p0 p2 - p0 |    = | dpdu dpdv |    | uv1 - uv0 uv2 - uv0 |
            // |                 |3x3   |           |3x2 |                     |2x3
            // 
            // We know A and B and can solve for X.
            float2 duv10 = uv1 - uv0;
            float2 duv20 = uv2 - uv0;
            float det = duv10.x * duv20.y - duv10.y * duv20.x;
            float invdet = 1.0 / det;

            if (abs(det) < 1e-7f)
            {
                float3 normal = normalize(cross(p1 - p0, p2 - p0));
                CoordinateSystem onb = CoordinateSystem::Build(normal);
                ret.dpdu = onb.b1;
                ret.dpdv = onb.b2;
                ret.dndu = 0;
                ret.dndv = 0;

                return ret;
            }

            // dpdu
            float3 dp10 = p1 - p0;
            float3 dp20 = p2 - p0;
            ret.dpdu = (duv20.y * dp10 - duv10.y * dp20) * invdet;
            ret.dpdv = (-duv20.x * dp10 + duv10.x * dp20) * invdet;
            // dndu
            float3 dn10 = n1 - n0;
            float3 dn20 = n2 - n0;
            ret.dndu = (duv20.y * dn10 - duv10.y * dn20) * invdet;
            ret.dndv = (-duv20.x * dn10 + duv10.x * dn20) * invdet;

            return ret;
        }

        float3 dpdu;
        float3 dpdv;
        float3 dndu;
        float3 dndv;
    };

    float4 RotationQuaternion(float3 axis, float theta)
    {
        float s = sin(0.5f * theta);
        float c = cos(0.5f * theta);
        return float4(s * axis, c);
    }

    float4 RotationQuaternion_Acute(float3 axis, float theta)
    {
        float s = sin(0.5f * theta);
        float c = sqrt(1 - s * s);
        return float4(s * axis, c);
    }

    float4 InverseRotationQuaternion(float4 quat)
    {
        return float4(-quat.xyz, quat.w);
    }

    // Returns rotation quaternion that aligns u to v. u and v are assumed to be normalized.
    float4 QuaternionFromUtoV(float3 u, float3 v, float thresh = 1e-6)
    {
        float4 q;
        float udotv = dot(u, v);

        // u = -v is a singularity
        if (udotv < thresh - 1.0f)
        {
            float3 imaginary = cross(v, u);
            float real = udotv + 1.0f;
            q = normalize(float4(imaginary, real));
        }
        else
        {
            float3 p = cross(u, v);

            // rotate 180/2 = 90 degrees
            q = float4(p, 0.0f);

            // p is already normalized, so no need to normalize q
        }

        return q;
    }

    // Quaternion that rotates +Y to u. Assumes ||u|| = 1.
    float4 QuaternionFromY(float3 u)
    {
        float4 q;
        float real = 1.0f + u.y;

        // u = (0, -1, 0) is a singularity
        if (real > 1e-6)
        {
            float3 yCrossU = float3(u.z, 0.0f, -u.x);
            q = float4(yCrossU, real);
            q = normalize(q);
        }
        else
        {
            // Rotate 180 degrees around the X-axis (Z-axis works too since both are orthogonal to Y)
            //
            // Rotation quaternion = (n_x * s, n_y * s, n_z * s, c)
            // where
            //        n = (1, 0, 0)
            //        s = sin(theta/2) = sin(90) = 1 and c = cos(theta/2) = cos(90) = 0
            q = float4(1.0f, 0.0f, 0.0f, 0.0f);

            // No need to normalize q
        }

        return q;
    }
    
    // Quaternion that rotates u to +Y. Assumes ||u|| = 1.
    float4 QuaternionToY(float3 u)
    {
        float4 q;
        float real = 1.0f + u.y;

        // u = (0, 0, -1) is a singularity
        if (real > 1e-6)
        {
            float3 uCrossY = float3(-u.z, 0.0f, u.x);
            q = float4(uCrossY, real);
            q = normalize(q);
        }
        else
        {
            // Rotate 180 degrees around the X-axis (Y-axis works too since both are orthogonal to Z)
            //
            // Rotation quaternion = (n_x * s, n_y * s, n_z * s, c)
            // where
            //        n = (1, 0, 0)
            //        s = sin(theta/2) = sin(90) = 1 and c = cos(theta/2) = cos(90) = 0
            q = float4(1.0f, 0.0f, 0.0f, 0.0f);

            // No need to normalize q
        }

        return q;
    }

    // Quaternion that rotates +Z to u. Assumes ||u|| = 1.
    float4 QuaternionFromZ(float3 u)
    {
        float4 q;
        float real = 1.0f + u.z;

        // u = (0, 0, -1) is a singularity
        if (real > 1e-6)
        {
            float3 zCrossU = float3(-u.y, u.x, 0);
            q = float4(zCrossU, real);
            q = normalize(q);
        }
        else
        {
            // Rotate 180 degrees around the X-axis (Y-axis works too since both are orthogonal to Z)
            //
            // Rotation quaternion = (n_x * s, n_y * s, n_z * s, c)
            // where
            //        n = (1, 0, 0)
            //        s = sin(theta/2) = sin(90) = 1 and c = cos(theta/2) = cos(90) = 0
            q = float4(1.0f, 0.0f, 0.0f, 0.0f);

            // No need to normalize q
        }

        return q;
    }

    // Quaternion that rotates u to +Z. Assumes ||u|| = 1.
    float4 QuaternionToZ(float3 u)
    {
        float4 q;
        float real = 1.0f + u.z;

        // u = (0, 0, -1) is a singularity
        if (real > 1e-6)
        {
            float3 uCrossZ = float3(u.y, -u.x, 0);
            q = float4(uCrossZ, real);
            q = normalize(q);
        }
        else
        {
            // Rotate 180 degrees around the X-axis (Y-axis works too since both are orthogonal to Z)
            //
            // Rotation quaternion = (n_x * s, n_y * s, n_z * s, c)
            // where
            //        n = (1, 0, 0)
            //        s = sin(theta/2) = sin(90) = 1 and c = cos(theta/2) = cos(90) = 0
            q = float4(1.0f, 0.0f, 0.0f, 0.0f);

            // No need to normalize q
        }

        return q;
    }

    // Rotates v using unit quaternion q by computing q * u * q* where
    //        * denotes quaternion multiplication
    //        q* is the conjugate of q.
    // Ref: https://fgiesen.wordpress.com/2019/02/09/rotating-a-single-vector-using-a-quaternion/
    float3 RotateVector(float3 v, float4 q)
    {
        float3 imaginary = q.xyz;
        float real = q.w;

        float3 t = cross(2 * imaginary, v);
        float3 rotated = v + real * t + cross(imaginary, t);
        
        return rotated;
    }

    float3 TransformTRS(float3 pos, float3 translation, float4 rotation, float3 scale)
    {
        float3 transformed = pos * scale;
        transformed = Math::RotateVector(transformed, rotation);
        transformed += translation;

        return transformed;
    }

    float3 InverseTransformTRS(float3 pos, float3 translation, float4 rotation, float3 scale)
    {
        float3 transformed = pos - translation;
        float4 q_conjugate = float4(-rotation.xyz, rotation.w);
        transformed = Math::RotateVector(transformed, q_conjugate);
        transformed *= 1.0f / scale;

        return transformed;
    }

    uint FloatToUNorm8(float f)
    {
        f = saturate(f);
        return (uint)mad(f, 255.0f, 0.5f);
    }

    float UNorm8ToFloat(uint u)
    {
        return u / 255.0f;
    }

    uint16_t FloatToUNorm16(float f)
    {
        f = saturate(f);
        return (uint16_t)mad(f, float_1_16, 0.5f);
    }

    float UNorm16ToFloat(uint16_t u)
    {
        return u * float_1_16_;
    }

    uint16_t2 UnpackUintToUint16(uint x)
    {
        return uint16_t2(x & 0xffff, x >> 16);
    }

    uint PackUint16_2ToUint(uint16_t2 e)
    {
        return e.x | (uint(e.y) << 16);
    }

    uint16_t2 EncodeAsUNorm2(float2 u)
    {
        u = saturate(u);
        return (uint16_t2)mad(u, float_1_16, 0.5f);
    }

    float2 DecodeUNorm2(uint16_t2 u)
    {
        return u * float_1_16_;
    }

    float4 DecodeNormalized4(uint16_t4 u)
    {
        float4 decoded = u * float_1_16_;
        // [0, 1] -> [-1, 1]
        return mad(decoded, 2.0f, -1.0f);
    }

    // Encodes 3D unit vector using octahedral mapping.
    // Ref: https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
    float2 EncodeUnitVector(float3 n)
    {
        float2 p = n.xy / (abs(n.x) + abs(n.y) + abs(n.z));
        float2 encoded = (n.z <= 0.0) ? ((1.0 - abs(p.yx)) * SignNotZero(p)) : p;
        // [-1, 1] -> [0, 1]
        return mad(encoded, 0.5f, 0.5f);
    }

    float3 DecodeUnitVector(float2 u)
    {
        // [0, 1] -> [-1, 1]
        u = mad(u, 2.0f, -1.0f);

        // https://twitter.com/Stubbesaurus/status/937994790553227264
        float3 n = float3(u.x, u.y, 1.0f - abs(u.x) - abs(u.y));
        float t = saturate(-n.z);
        //n.xy += n.xy >= 0.0f ? -t : t;
        n.xy += select(n.xy >= 0.0f, -t, t);

        return normalize(n);
    }

    uint16_t2 EncodeOct32(float3 n)
    {
        float2 u = EncodeUnitVector(n);
        return EncodeAsUNorm2(u);
    }

    uint32_t EncodeOct32u(float3 n)
    {
        float2 u = EncodeUnitVector(n);
        uint16_t2 un = EncodeAsUNorm2(u);

        return un.x | (uint(un.y) << 16);
    }

    float3 DecodeOct32(uint16_t2 e)
    {
        float2 u = DecodeUNorm2(e);
        return DecodeUnitVector(u);
    }

    // Octahedral encoding for unit vector in upper hemisphere (n.y >= 0)
    float2 EncodeUnitHemisphereVector(float3 n)
    {
        float2 p = n.xz / (abs(n.x) + abs(n.y) + abs(n.z));
        return p;
    }

    float3 DecodeUnitHemisphereVector(float2 u)
    {
        float3 n = float3(u.x, 1.0f - abs(u.x) - abs(u.y), u.y);
        return normalize(n);
    }

    float Luminance(float3 linearRGB)
    {
        return dot(float3(0.2126f, 0.7152f, 0.0722f), linearRGB);
    }

    float3 LinearTosRGB(float3 color)
    {
        float3 sRGBLo = color * 12.92;
        float3 sRGBHi = pow(saturate(color), 1.0f / 2.4f) * 1.055f - 0.055f;
        float3 sRGB = select((color <= 0.0031308f), sRGBLo, sRGBHi);

        return sRGB;
    }

    float3 sRGBToLinear(float3 color)
    {
        float3 linearRGBLo = color / 12.92f;
        float3 linearRGBHi = pow(max((color + 0.055f) / 1.055f, 0.0f), 2.4f);
        float3 linearRGB = select(color <= 0.0404499993f, linearRGBLo, linearRGBHi);

        return linearRGB;
    }

    float3 LinearToYCbCr(float3 x)
    {
        float3x3 M = float3x3(0.2126, 0.7152, 0.0722,
                             -0.1146, -0.3854, 0.5,
                              0.5, -0.4542, -0.0458);
        return mul(M, x);
    }

    float2 UnpackRG(uint rg)
    {
        float2 ret;
        ret.x = float(rg & 0xff) / 255.0f;
        ret.y = float((rg >> 8) & 0xff) / 255.0f;

        return ret;
    }

    float3 UnpackRGB8(uint rgb)
    {
        float3 ret;
        ret.x = float(rgb & 0xff) / 255.0f;
        ret.y = float((rgb >> 8) & 0xff) / 255.0f;
        ret.z = float((rgb >> 16) & 0xff) / 255.0f;

        return ret;
    }

    float4 UnpackRGBA8(uint rgba)
    {
        float4 ret;
        ret.x = float(rgba & 0xff) / 255.0f;
        ret.y = float((rgba >> 8) & 0xff) / 255.0f;
        ret.z = float((rgba >> 16) & 0xff) / 255.0f;
        ret.w = float((rgba >> 24) & 0xff) / 255.0f;

        return ret;
    }

    uint Float3ToRGB8(float3 v)
    {
        v = saturate(v);
        uint3 u = (uint3)mad(v, 255.0f, 0.5f);
        uint packed = u.x | (u.y << 8) | (u.z << 16);

        return packed;
    }
}

#endif