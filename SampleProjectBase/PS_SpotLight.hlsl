struct PS_IN
{
    float4 pos : SV_POSITION0;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL0;
    float4 worldPos : POSITION0;
};

cbuffer Light : register(b0)
{
    float4 lightColor;
    float3 lightPos;
    float lightRange;
    float3 lightDir;
    float lightAngle;
};


Texture2D tex : register(t0);
SamplerState samp : register(s0);

float4 main(PS_IN pin) : SV_TARGET
{
    float4 color = float4(0.0f, 0.0f, 0.0f, 1.0f);
    float3 toLightVec = lightPos - pin.worldPos.xyz;
    float3 V = normalize(toLightVec); 
    float toLightLen = length(toLightVec); 


    float3 N = normalize(pin.normal);
    float dotNV = saturate(dot(N, V));


    float attenuation = saturate(1.0f - toLightLen / lightRange);

    attenuation = pow(attenuation, 2.0f);
    float3 L = normalize(-lightDir);


    float dotVL = dot(V, L);
    float angle = acos(dotVL);
    float diffAngle = (lightAngle * 0.5f) * 0.1f;
    float spotAngle = ((lightAngle * 0.5f) + diffAngle);
    float spotRate = (spotAngle - angle) / diffAngle;
    spotRate = pow(saturate(spotRate), 2.0f);

    color.rgb = dotNV * attenuation * spotRate;
    
    return color;
}

