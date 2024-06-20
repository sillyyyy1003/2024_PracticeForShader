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
Texture2D heightMap : register(t2);

float4 main (PS_IN pin) : SV_TARGET
{
    float4 color = float4(0.0f, 0.0f, 0.0f, 1.0f);

    //--- Parallax occlusion mapping
    // Find the point where height from height map reverses while descending from polygon surface along view direction

    // Number of steps to find the point where height reverses
    int nStep = 100;
    // Amount of height to decrease in one step
    float maxHeight = 0.03f;
    float stepHeight = maxHeight / nStep;

    // Calculate offset in tangent vector space for UV coordinates (to match the change in height per step)
    float3 offset = pin.camVecT;
    offset.xy *= stepHeight / offset.z;
    offset.z = stepHeight;

    // Move towards the point where height from height map reverses
    float2 uv = pin.uv;
    float eyeHeight = maxHeight;
    // Unroll loop... Set the maximum number of loop iterations
    [unroll(100)]
    for (int i = 0; i < nStep; ++i)
    {
        // Fetch height
        float height = heightMap.Sample(samp, uv).r;
        height *= maxHeight;
        // Check if viewpoint is inside the terrain
        if (height >= eyeHeight)
        {
            break;
        }
        // Move viewpoint height and UV
        uv -= offset.xy;
        eyeHeight -= offset.z;
    }

    // Fetch normal data from normal map
    float3 N = normalMap.Sample(samp, uv).rgb;
    N = normalize(N * 2.0f - 1.0f);

    // Precomputed light in texture space
    float3 L = normalize(pin.lightT);

    // Calculate brightness from normal and light (as before)
    float diffuse = saturate(dot(-L, N));
    color = tex.Sample(samp, uv);
    color.rgb = color.rgb * diffuse;

    return color;
}
