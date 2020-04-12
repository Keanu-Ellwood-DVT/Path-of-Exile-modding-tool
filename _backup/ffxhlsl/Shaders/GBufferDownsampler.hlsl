//PRECOMPILE ps_4_0 DownsampleGBuffer
//PRECOMPILE ps_gnm DownsampleGBuffer
//PRECOMPILE ps_vkn DownsampleGBuffer

CBUFFER_BEGIN( cdynamic_resolution_scale )
	float4 dynamic_resolution_scale;
	float4 src_size;
	float4 dst_size;
	float4 gamma_vec;
	float src_mip_level;
CBUFFER_END

TEXTURE2D_DECL( depth_sampler );

struct VOut
{
	float4 pos : SV_POSITION;
};


struct DownsampleGBufferResult
{
	float out_depth : SV_DEPTH;

/*
#if defined(OUT_DEPTH)
	float out_depth_color : PIXEL_RETURN_SEMANTIC;
#endif

#if defined(OUT_COLOR)
	float out_color : PIXEL_RETURN_SEMANTIC1;
#endif

#if defined(OUT_NORMAL)
	float out_normal : PIXEL_RETURN_SEMANTIC2;
#endif */
};

float4 ReadSrcPixel(TEXTURE2D_DECL( src_sampler ), float2 src_pixel, float2 src_size)
{
	float2 unorm_uv = (src_pixel + float2(0.5f, 0.5f));
	float4 res = 0.0f;
	float2 norm_uv = unorm_uv / src_size;
	res = SAMPLE_TEX2DLOD( src_sampler, SamplerLinearClampNoBias, float4(norm_uv.xy, 0.0f, 0.0f) );
	return res;
}

float ReadDepth(float2 scale, float2 base_src_pixel, float2 base_dst_pixel)
{
	float4 max_value = -1e7f;
	float4 min_value = 1e7f;
	float4 first_value = ReadSrcPixel(depth_sampler, base_src_pixel, src_size.xy);

	//return first_value;

	for(float y = 0.0f; y < scale.x - 0.5f; y += 1.0f)
	{
		for(float x = 0.0f; x < scale.y - 0.5f; x += 1.0f)
		{
			float4 src_sample = ReadSrcPixel(depth_sampler, base_src_pixel + float2(x, y), src_size.xy);
			max_value = max(max_value, src_sample);
			min_value = min(min_value, src_sample);
		}
	}

	//float even = float(uint(base_dst_pixel.x + base_dst_pixel.y) % 2);
	float even = fmod(base_dst_pixel.x + fmod(base_dst_pixel.y, 2.0), 2.0);
	return even * min_value + (1.0f - even) * max_value;
}

DownsampleGBufferResult DownsampleGBuffer(VOut vertex_input)
{
	DownsampleGBufferResult res;

	float2 base_dst_pixel = (vertex_input.pos.xy - float2(0.5, 0.5));
	float2 scale = floor(src_size.xy * dynamic_resolution_scale.xy / dst_size.xy + float2(0.5f, 0.5f));
	float2 base_src_pixel = base_dst_pixel * scale;

	res.out_depth = ReadDepth(scale, base_src_pixel, base_dst_pixel);

	return res;
}