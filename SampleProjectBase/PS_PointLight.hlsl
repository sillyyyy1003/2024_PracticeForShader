struct PS_IN {
	float4 pos : SV_POSITION0;
	float2 uv : TEXCOORD0;
	float3 normal : NORMAL0;
	float4 worldPos : POSITION0;
};

struct Light
{
	float4 color;
	float3 pos;
	float range;
};

cbuffer LightBuf : register(b0)
{
	Light lights[30];
};

Texture2D tex : register(t0);
SamplerState samp : register(s0);

float4 main(PS_IN pin) : SV_TARGET
{
	float4 color = float4(0.0f, 0.0f, 0.0f, 1.0f);
    for (int i = 0; i < 30;i++)
    {
        float3 toLightVec = lights[i].pos - pin.worldPos.xyz;
        float3 V = normalize(toLightVec);
        float toLightLen = length(toLightVec);
        float3 N = normalize(pin.normal);
        float dotNV = saturate(dot(N, V));
        float attenuation = saturate(1.0f - toLightLen / lights[i].range);
        attenuation = pow(attenuation, 2.0f);
        color.rgb += lights[i].color.rgb * dotNV * attenuation;
    }

	return color;
}