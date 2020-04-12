//PRECOMPILE vs_4_0 VShad
//PRECOMPILE vs_gnm VShad
//PRECOMPILE vs_vkn VShad


struct VOut
{
	float4 pos : SV_POSITION;
	float2 texture_uv : TEXCOORD0;
};

VOut VShad(float4 position : POSITION, float2 texture_uv : TEXCOORD0)
{
	VOut output;
	output.pos = position;
	output.texture_uv = texture_uv;
	return output;
}
