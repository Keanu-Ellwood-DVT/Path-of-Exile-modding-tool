//PRECOMPILE ps_4_0 HorizontalBlur NUM_SAMPLES 9
//PRECOMPILE ps_4_0 VerticalBlur NUM_SAMPLES 9
//PRECOMPILE ps_gnm HorizontalBlur NUM_SAMPLES 9
//PRECOMPILE ps_gnm VerticalBlur NUM_SAMPLES 9
//PRECOMPILE ps_vkn HorizontalBlur NUM_SAMPLES 9
//PRECOMPILE ps_vkn VerticalBlur NUM_SAMPLES 9


CBUFFER_BEGIN( cgaussian_blur_desc )
	float4 bloom_weights[3];
	float4 bloom_offsets[3];
CBUFFER_END

TEXTURE2D_DECL( tex_sampler );

struct PInput
{
	float4 pos : SV_POSITION;
	float2 texture_uv : TEXCOORD0;
};

float4 HorizontalBlur( PInput input ) : PIXEL_RETURN_SEMANTIC
{
	float4 colour = { 0.0f, 0.0f, 0.0f, 0.0f };
	
	for(int i=0; i< NUM_SAMPLES; ++i)
	{
		int row = i / 4;
		int column = i % 4;
		
		colour += SAMPLE_TEX2D( tex_sampler, SamplerPointClamp, input.texture_uv + float2(bloom_offsets[row][column], 0.0f) ) * bloom_weights[row][column];	
	}
	
	return float4(colour.rgb, 1.0f);
}

float4 VerticalBlur( PInput input ) : PIXEL_RETURN_SEMANTIC
{
	float4 colour = { 0.0f, 0.0f, 0.0f, 0.0f };
	
	for(int i=0; i< NUM_SAMPLES; ++i)
	{
		int row = i / 4;
		int column = i % 4;
		
		colour += SAMPLE_TEX2D( tex_sampler, SamplerPointClamp, input.texture_uv + float2(0.0f, bloom_offsets[row][column]) ) * bloom_weights[row][column];	
	}
	
	return float4( colour.rgb, 1.0f );
}