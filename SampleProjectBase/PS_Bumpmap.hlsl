struct PS_IN
{
    float4 pos : SV_POSITION0; // Position in screen space
    float2 uv : TEXCOORD0; // Texture coordinates
    float3 normal : NORMAL0; // Normal vector
    float3 lightT : NORMAL1; // Light vector in tangent space
};

SamplerState samp : register(s0); // Sampler state
Texture2D tex : register(t0); // Diffuse texture
Texture2D normalMap : register(t1); // Normal map

float4 main (PS_IN pin) : SV_TARGET
{
    float4 color = float4(0.0f, 0.0f, 0.0f, 1.0f); // Initialize the color to black with full alpha

	// Get the normal data from the normal map
    float3 N = normalMap.Sample(samp, pin.uv);
    N = normalize(N * 2.0f - 1.0f); // Transform the normal from [0, 1] range to [-1, 1] range

	// Light vector in tangent space precomputed
    float3 L = normalize(pin.lightT);

    // Calculate the brightness from the normal and light vector (as usual)
    float diffuse = saturate(dot(-L, N)); // Compute the diffuse lighting term
    color = tex.Sample(samp, pin.uv); // Sample the color from the diffuse texture
    color.rgb = color.rgb * diffuse; // Modulate the color by the diffuse term

    return color; // Return the final color
}
