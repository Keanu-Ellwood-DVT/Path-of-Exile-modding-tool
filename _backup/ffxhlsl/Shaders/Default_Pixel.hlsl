//PRECOMPILE ps_4_0 main
//PRECOMPILE ps_gnm main
//PRECOMPILE ps_vkn main


struct VS_OUTPUT
{
	float4 Position : SV_POSITION;
};


float4 main(VS_OUTPUT input) : PIXEL_RETURN_SEMANTIC
{
	return float4(0.0, 0.0, 0.0, 0.1); // Half transparent for particles to not look too bad. 
}