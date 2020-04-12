//PRECOMPILE ps_4_0 main
//PRECOMPILE ps_gnm main
//PRECOMPILE ps_vkn main


TEXTURE2D_DECL( tex_sampler );

struct VOut
{
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
};

float4 main(VOut In) : PIXEL_RETURN_SEMANTIC
{
	return SAMPLE_TEX2D(tex_sampler, SamplerPointWrap, In.uv );
}
