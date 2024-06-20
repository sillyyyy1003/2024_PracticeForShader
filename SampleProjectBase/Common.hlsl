cbuffer WorldBuffer : register(b0)
{
    matrix World;
}
cbuffer ViewBuffer : register(b1)
{
    matrix View;
}
cbuffer ProjectionBuffer : register(b2)
{
    matrix Projection;
}

struct MATERIAL
{
    float4 Ambient;
    float4 Diffuse;
    float4 Specular;
    float4 Emission;
    float Shininess;
    bool TextureEnable;
    float2 Dummy;
};

cbuffer MaterialBuffer : register(b3)
{
    MATERIAL Material;
}

struct LIGHT
{
    bool Enable; // 使用するか否か
    bool3 Dummy; // PADDING
    float4 Direction; // 方向
    float4 Diffuse; // 拡散反射用の光の強さ
    float4 Ambient; // 環境光用の光の強さ
};

cbuffer LightBuffer : register(b4)
{
    LIGHT Light;
}

cbuffer BoneMatrixBuffer : register(b5)
{
    matrix BoneMatrix[400];
}

struct VS_IN
{
    float4 Position : POSITION0;
    float4 Normal : NORMAL0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

struct VSONESKIN_IN
{
    float4 Position : POSITION0;
    float4 Normal : NORMAL0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    int4 BoneIndex : BONEINDEX;
    float4 BoneWeight : BONEWEIGHT;
};

struct PS_IN
{
    float4 Position : SV_POSITION;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
};
