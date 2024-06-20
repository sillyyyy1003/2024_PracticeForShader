struct PS_IN
{
	float4 pos : SV_POSITION0;
	float4 color : COLOR0;
	float2 uv : TEXCOORD0;
};

Texture2D tex : register(t0);
SamplerState samp : register(s0);

float4 main (PS_IN pin) : SV_TARGET
{
	//Get uv from Sampler
	float4 color = tex.Sample(samp, pin.uv);

	//Set Color with input Color
	color.rgb *= pin.color.rgb;

	return color;
}