//PRECOMPILE vs_4_0 main
//PRECOMPILE vs_gnm main
//PRECOMPILE vs_vkn main


struct VOut
{
	float4 pos : SV_POSITION;
};

VOut main(float4 position : POSITION)
{
	VOut output;
	output.pos = position;
	return output;
}
