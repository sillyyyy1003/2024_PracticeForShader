static const float PI = 3.1415926f; // ƒÎ

// Constant buffer for light
cbuffer LightCb : register(b0)
{
    float4 lightDiffuse; // Diffuse light of the light source
    float4 lightAmbient; // Ambient light of the light source
    float4 lightDir; // Direction of the light source
};

// Constant buffer for camera
cbuffer CameraCb : register(b1)
{
    float4 eyePos; // Camera position
};

// Constant buffer for specular properties
cbuffer SpecCb : register(b2)
{
    float specPow; // Specular exponent
    float metallic; // Metallic property
    float smooth; // Smoothness
};

// Define the data to be received from the vertex shader
struct PS_IN
{
    float4 pos : SV_POSITION0;
    float3 normal : NORMAL0;
    float3 tangent : TANGENT; // Added
    float3 biNormal : BINORMAL; // Added
    float2 uv : TEXCOORD0;
    float4 worldPos : POSITION0;
};

// Receive textures
Texture2D tex : register(t0);
SamplerState samp : register(s0); // Texture sampling settings

// Normal map
Texture2D<float4> normalMap : register(t1);

// Metallic and smoothness map. R channel for metallic, A channel for smoothness
 Texture2D<float4> metallicSmoothMap : register(t2);

///////////////////////////////////////////////////
// Functions
///////////////////////////////////////////////////

// Get the normal
float3 GetNormal (float3 normal, float3 tangent, float3 biNormal, float2 uv)
{
    float3 binSpaceNormal = normalMap.SampleLevel(samp, uv, 0.0f).xyz;
    binSpaceNormal = (binSpaceNormal * 2.0f) - 1.0f;

    float3 newNormal = normalize(tangent * binSpaceNormal.x + biNormal * binSpaceNormal.y + normal * binSpaceNormal.z);

    return newNormal;
}

// Calculate Beckmann distribution
float Beckmann (float m, float t)
{
    float t2 = t * t;
    float t4 = t * t * t * t;
    float m2 = m * m;
    float D = 1.0f / (4.0f * m2 * t4);
    D *= exp((-1.0f / m2) * (1.0f - t2) / t2);
    return D;
}

// Calculate Fresnel using Schlick approximation
float SpcFresnel (float f0, float u)
{
    // From Schlick
    return f0 + (1 - f0) * pow(1 - u, 5);
}

/// <summary>
/// Calculate specular reflection using the Cook-Torrance model
/// </summary>
/// <param name="L">Vector towards the light source</param>
/// <param name="V">Vector towards the viewer</param>
/// <param name="N">Normal vector</param>
/// <param name="metallic">Metallic property</param>
float CookTorranceSpecular (float3 L, float3 V, float3 N, float metallic)
{
    float microfacet = 0.76f;

    // Treat metallic as the Fresnel reflectance at normal incidence
    // Higher metallic increases Fresnel reflectance
    float f0 = metallic;

    // Calculate the half vector between the light and view vectors
    float3 H = normalize(L + V);

    // Use dot products to determine similarity of vectors
    float NdotH = saturate(dot(N, H));
    float VdotH = saturate(dot(V, H));
    float NdotL = saturate(dot(N, L));
    float NdotV = saturate(dot(N, V));

    // Calculate D term using Beckmann distribution
    float D = Beckmann(microfacet, NdotH);

    // Calculate F term using Schlick approximation
    float F = SpcFresnel(f0, VdotH);

    // Calculate G term
    float G = min(1.0f, min(2 * NdotH * NdotV / VdotH, 2 * NdotH * NdotL / VdotH));

    // Calculate m term
    float m = PI * NdotV * NdotH;

    // Calculate the Cook-Torrance specular reflection using the obtained values
    return max(F * D * G / m, 0.0);
}

/// <summary>
/// Calculate diffuse reflection considering Fresnel reflection
/// </summary>
/// <remarks>
/// This function calculates the diffuse reflection rate considering Fresnel reflection.
/// Fresnel reflection is the phenomenon of light reflecting off the surface of an object,
/// resulting in specular reflection. Diffuse reflection is the light that enters the object,
/// scatters internally, and reflects back out.
/// When Fresnel reflection is weak, diffuse reflection is strong, and when Fresnel reflection is strong, diffuse reflection is weak.
/// </remarks>
/// <param name="N">Normal vector</param>
/// <param name="L">Vector towards the light source. Opposite direction of the light.</param>
/// <param name="V">Vector towards the viewer.</param>
float CalcDiffuseFromFresnel (float3 N, float3 L, float3 V)
{
    // Step 4: Calculate diffuse reflection considering Fresnel reflection

    // Calculate how similar the normal and light vectors are using dot product
    float dotNL = saturate(dot(N, L));

    // Calculate how similar the normal and view vectors are using dot product
    float dotNV = saturate(dot(N, V));


    //Calculate half Vector
    float3 H = normalize(L + V);

    //
    float roughness =0.5f;

    float energyBias = lerp(0.0, 0.5f, roughness);
    float energyFactor = lerp(1.0f, 1.0f / 1.51, roughness);

    float dotLH = saturate(dot(L, H));

    float Fd90 = energyBias + 2.0f * dotLH * dotLH * roughness;
    float FL = saturate(1 + (Fd90 - 1) * pow(1 - dotNL, 5));
    float FV = saturate(1 + (Fd90 - 1) * pow(1 - dotNV, 5));


    // Multiply the diffuse reflection rates dependent on the normal and light direction,
    // and the normal and view vectors. Divide by PI for normalization.
    return (FL * FV * energyFactor);

}

float4 main (PS_IN pin) : SV_TARGET
{
    float4 color = float4(1.0f, 1.0f, 1.0f, 1.0f);

    //float3 toLightVec = lightDir.xyz - pin.worldPos.xyz;
    float3 toLightVec = -lightDir.xyz;

	// Calculate the vector extending towards the view
    float3 toEye = normalize(eyePos.xyz - pin.worldPos.xyz);
     // Calculate the normal
    //float3 normal = GetNormal(pin.normal, pin.tangent, pin.biNormal, pin.uv);
    float3 normal = pin.normal;
	// Step 2: Sample various maps
    // Albedo color (diffuse reflection)
    float4 albedoColor = tex.Sample(samp, pin.uv);

    // Set specular color the same as albedo color
    float3 specColor = albedoColor;

    // Metallic property
    float metallic = metallicSmoothMap.Sample(samp, pin.uv).r;

    // Smoothness property
    float smooth = metallicSmoothMap.Sample(samp, pin.uv).a;

    float3 lig = 0;

    // Step 3: Implement simple Disney-based diffuse reflection
    // Calculate diffuse reflection considering Fresnel reflection
    float diffuseFromFresnel = CalcDiffuseFromFresnel(normal, toLightVec, toEye);

    // Normalized Lambert diffuse reflection calculation ------------------------
    //float3 L = normalize(lightDir.xyz);
    float NdotL = saturate(dot(normal, toLightVec));
    float3 lambertDiffuse = (NdotL * lightDiffuse) / PI ;
    // float NdotL = dot product of normal and light vector, clamped to range 0-1.0
    // float3 lambertDiffuse = multiply the result with the light color and normalize by dividing by PI
    // -------------------------------------------------------------------------
    
    // Calculate final diffuse reflection
    float3 diffuse = albedoColor * diffuseFromFresnel * lambertDiffuse;

    // Step 5: Calculate specular reflection using the Cook-Torrance model
    // Calculate the Cook-Torrance specular reflection
    float3 spec = CookTorranceSpecular(toLightVec, toEye, normal, smooth) * lightDiffuse;

    // Higher metallic results in higher specular reflection, either white or specular color
    // Treat specular color strength as specular reflection
    spec *= lerp(float3(1.0f, 1.0f, 1.0f), specColor, metallic);

    // Step 6: Combine diffuse and specular reflections using smoothness
    // Higher smoothness results in weaker diffuse reflection
    lig += diffuse * (1.0f - smooth) + spec;

    // Add ambient light contribution
    lig += lightAmbient * albedoColor;

    color.xyz = lig;
    
    return color;
}
