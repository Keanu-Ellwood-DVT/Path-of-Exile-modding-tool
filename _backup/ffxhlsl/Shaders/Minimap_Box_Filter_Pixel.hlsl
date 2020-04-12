//PRECOMPILE ps_4_0 ApplyFilter
//PRECOMPILE ps_gnm ApplyFilter
//PRECOMPILE ps_vkn ApplyFilter

CBUFFER_BEGIN( cminimap_box_filter )
	float4 tile_size;
	int supersampling_scale;
CBUFFER_END

TEXTURE2D_DECL( supersampled_tile_sampler );

struct PInput
{
	float4 tilemap_coord : SV_POSITION;
	float2 tex_coord : TEXCOORD0;
};


float4 ApplyFilter( PInput input ) : PIXEL_RETURN_SEMANTIC
{
	float2 pixel_coord = input.tilemap_coord.xy - float2(0.5f, 0.5f);

	float4 sum_color = float4(0.0f, 0.0f, 0.0f, 0.0f);
	float pixels_count = 0.0f;

#if !defined( GNMX )
	[fastopt]
#endif
	for(int y = 0; y < supersampling_scale; y++)
	{
	#if !defined( GNMX )
		[fastopt]
	#endif
		for(int x = 0; x < supersampling_scale; x++)
		{
			float2 supersampled_pixel_coord = pixel_coord * supersampling_scale + float2(x, y);
			//float4 color_sample = SAMPLE_TEX2D(supersampled_tile_sampler, SamplerLinearClamp, (float2(supersampled_pixel_coord) + float2(0.5f, 0.5f)) / (tile_size.xy * supersampling_scale)); 
			float4 color_sample = SAMPLE_TEX2DLOD(supersampled_tile_sampler, SamplerLinearClamp, float4((float2(supersampled_pixel_coord) + float2(0.5f, 0.5f)) / (tile_size.xy * supersampling_scale), 0.0f, -0.5f)); 
			sum_color.rgb += color_sample.rgb * color_sample.a;
			sum_color.a += color_sample.a;
			pixels_count += 1.0f;
		}
	}
	float4 res_color = float4(sum_color.rgb / (sum_color.a + 1e-5f), sum_color.a / (pixels_count + 1e-5f));
	if(length(res_color.rgb) < 1e-3f && res_color.a > 1e-3f) //no AA on color key
	{
		res_color.a = 1.0f;
		res_color.rgb = float3(0.0f, 0.0f, 0.0f);
	}
	res_color.rgb *= res_color.a; //alpha premultiply

	//int2 int_coord = int2(pixel_coord + float2(1e-2f, 1e-2f));
	//return lerp(res_color, float4(1.0f, 0.0f, 0.0f, 1.0f), length(pixel_coord - float2(int_coord)));
	return res_color;
}