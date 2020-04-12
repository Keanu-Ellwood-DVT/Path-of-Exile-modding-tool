//PRECOMPILE ps_4_0 main
//PRECOMPILE ps_gnm main
//PRECOMPILE ps_vkn main


struct VS_OUTPUT
{
	float4 Position		: SV_POSITION;
	float4 Color		: TEXCOORD0;
};


float4 main(VS_OUTPUT Input) : PIXEL_RETURN_SEMANTIC
{
	return Input.Color;
}