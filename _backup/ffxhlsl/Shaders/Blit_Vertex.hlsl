//PRECOMPILE vs_4_0 main
//PRECOMPILE vs_gnm main
//PRECOMPILE vs_vkn main


struct VOut
{
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
};

VOut main(float4 position : POSITION, float2 texcoord : TEXCOORD0)
{
	VOut output;
	output.pos = position;
	output.uv = texcoord;
	return output;
}
