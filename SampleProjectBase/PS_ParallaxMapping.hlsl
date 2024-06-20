struct PS_IN
{
    float4 pos : SV_POSITION0;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL0;
    float3 lightT : NORMAL1;
    float3 camVecT : NORMAL2;
};
SamplerState samp : register(s0);
Texture2D tex : register(t0);
Texture2D normalMap : register(t1);
// Height map texture (contains height information)
Texture2D heightMap : register(t2);

float4 main (PS_IN pin) : SV_TARGET
{
    float4 color = float4(0.0f, 0.0f, 0.0f, 1.0f);

    // Fetch height map
    float hScale = heightMap.Sample(samp, pin.uv).r;
    float height = 0.05f * hScale;
    // How much to move along the view direction in tangent space
    float2 offset = pin.camVecT.xy / pin.camVecT.z;
    offset *= height;

    // Fetch normal data from normal map
    float3 N = normalMap.Sample(samp, pin.uv + offset).rgb;
    N = normalize(N * 2.0f - 1.0f);

    // Precomputed light in texture space
    float3 L = normalize(pin.lightT);

    // Calculate brightness from normal and light (as before)
    float diffuse = saturate(dot(-L, N));
    color = tex.Sample(samp, pin.uv);
    color.rgb = color.rgb * diffuse;

    return color;
}
