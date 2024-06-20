struct VS_IN
{
    float3 pos : POSITION0;
    float3 normal : NORMAL0;
    float2 uv : TEXCOORD0;
    // Tangent vector (direction in 3D space when the texture is applied)
    float3 tangent : TANGENT0;
};

struct VS_OUT
{
    float4 pos : SV_POSITION0;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL0;
    // Light information moved to tangent space
    float3 lightT : NORMAL1;
    // Camera vector information moved to tangent space
    float3 camVecT : NORMAL2;
};

cbuffer WVP : register(b0)
{
    float4x4 world;
    float4x4 view;
    float4x4 proj;
};

cbuffer Light : register(b1)
{
    float4 lightColor;
    float4 lightAmbient;
    float4 lightDir;
};

cbuffer Camera : register(b2)
{
    float4 camPos;
};

VS_OUT main (VS_IN vin)
{
    VS_OUT vout;
    vout.pos = float4(vin.pos, 1.0f);
    vout.pos = mul(vout.pos, world);
    float4 worldPos = vout.pos; // Copy the world coordinate information to a variable during computation
    vout.pos = mul(vout.pos, view);
    vout.pos = mul(vout.pos, proj);
    vout.uv = vin.uv;
    vout.normal = mul(vin.normal, (float3x3) world);

    // Calculate the bitangent (Bynormal) from the tangent and normal
    float3 T = mul(vin.tangent, (float3x3) world);
    T = normalize(T);
    float3 N = normalize(vout.normal);
    float3 B = normalize(cross(T, N));
    // Calculate the matrix to transform the texture normal to world space from the three vectors
    float3x3 tangentMat = float3x3(T, B, N);

    // Move the light vector, used for calculations with the normal, from world space to texture space
    // *This can be done by computing the inverse of the tangent transformation matrix
    tangentMat = transpose(tangentMat);
    float3 invLightDir = normalize(lightDir.xyz);
    invLightDir = mul(invLightDir, tangentMat);
    vout.lightT = invLightDir;

    // Move the camera vector from world space to texture space as well
    float4 camVec = worldPos - camPos;
    vout.camVecT = mul(camVec.xyz, tangentMat);

    return vout;
}
