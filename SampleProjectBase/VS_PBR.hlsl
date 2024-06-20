struct VS_IN
{
    float3 pos : POSITION0;
    float3 normal : NORMAL0;
    float2 uv : TEXCOORD0;
    float3 tangent : TANGENT; // Added
};

struct VS_OUT
{
    float4 pos : SV_POSITION0;
    float3 normal : NORMAL0;
    float3 tangent : TANGENT; // Added
    float3 biNormal : BINORMAL; // Added
    float2 uv : TEXCOORD0;
    float4 worldPos : POSITION0;
};

cbuffer WVP : register(b0)
{
    float4x4 world;
    float4x4 view;
    float4x4 proj;
};

VS_OUT main (VS_IN vin)
{
    VS_OUT vout;
    vout.pos = float4(vin.pos, 1.0f);
    vout.pos = mul(vout.pos, world);
    // Copy to a variable for passing to the pixel shader
    vout.worldPos = vout.pos;

    vout.pos = mul(vout.pos, view);
    vout.pos = mul(vout.pos, proj);
    vout.normal = mul(vin.normal, (float3x3) world);
    vout.tangent = mul(vin.tangent, (float3x3) world);
    // Calculate the bitangent (Bynormal) from the tangent and normal
    float3 T = normalize(vout.tangent);
    float3 N = normalize(vout.normal);
    vout.biNormal = normalize(cross(T, N));
    vout.uv = vin.uv;
	
    return vout;
}
