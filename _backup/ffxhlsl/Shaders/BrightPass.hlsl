//PRECOMPILE ps_4_0 BrightPassPS
//PRECOMPILE ps_gnm BrightPassPS
//PRECOMPILE ps_vkn BrightPassPS

CBUFFER_BEGIN( cbright_pass_desc )
	// bright pass constants
	float4 dynamic_resolution_scale;
	float4 downsample_offsets[ 2 ];
	float bloom_intensity = 0.3f;
	float bloom_cutoff = 0.3f;
CBUFFER_END

TEXTURE2D_DECL( source_sampler );

struct PInput
{
	float4 pos : SV_POSITION;
	float2 texture_uv : TEXCOORD0;
};

//Performs 4x4 downsample
float4 GetDownsampledPixel(float2 texture_uv)
{
	float4 color = 0;
	for (int i = 0; i < 2; ++i)
	{
		color += SAMPLE_TEX2D( source_sampler, SamplerLinearClamp, texture_uv + downsample_offsets[ i ].xy );
		color += SAMPLE_TEX2D( source_sampler, SamplerLinearClamp, texture_uv + downsample_offsets[ i ].zw );
	}
	return color * 0.25f;
}

float4 BrightPassPS( PInput input ) : PIXEL_RETURN_SEMANTIC
{
	float4 colour = GetDownsampledPixel( input.texture_uv * dynamic_resolution_scale.xy );

	colour=saturate((colour-bloom_cutoff)*bloom_intensity);
	
	return colour;
}
