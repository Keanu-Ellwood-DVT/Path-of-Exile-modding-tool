//PRECOMPILE ps_4_0 RenderVisibility
//PRECOMPILE ps_gnm RenderVisibility
//PRECOMPILE ps_vkn RenderVisibility

CBUFFER_BEGIN( cminimap_visibility_pixel )
	float4 explored_tile;
	float4 tile_map_size;
	float4 visibility_map_size;
	float visibility_radius;


	float visibility_revealed;
	float visibility_reset;
CBUFFER_END

TEXTURE2D_DECL( curr_visibility_sampler );

struct PS_INPUT
{
	float4 pixel_coord : SV_POSITION;
	float2 texture_uv : TEXCOORD0;
};

float4 RenderVisibility( const PS_INPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float2 planar_pos = input.pixel_coord.xy / visibility_map_size.xy * tile_map_size.xy;
	float dist = length(planar_pos - explored_tile.xy);
	float ratio = saturate((1.0f - dist / visibility_radius) * 2.0f);

	float2 viewport_size = visibility_map_size.xy;

	float2 normalized_pos = input.pixel_coord.xy / viewport_size.xy;

	float prev_ratio = SAMPLE_TEX2D( curr_visibility_sampler, SamplerLinearClamp, normalized_pos ).r;

	float4 res_color = float4(max(ratio, prev_ratio), 0.0f, 0.0f, 1.0f);
	if(visibility_reset > 0.5f)
		res_color = float4(0.0f, 0.0f, 0.0f, 1.0f);
	if(visibility_revealed > 0.5f)
		res_color = float4(1.0f, 0.0f, 0.0f, 1.0f);
	return res_color;
}