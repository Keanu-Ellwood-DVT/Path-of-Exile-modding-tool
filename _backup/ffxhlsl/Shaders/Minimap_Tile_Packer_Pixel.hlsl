//PRECOMPILE ps_4_0 PackTile
//PRECOMPILE ps_gnm PackTile
//PRECOMPILE ps_vkn PackTile

CBUFFER_BEGIN( cminimap_tile_packer )
	float4 tilemap_size;
	float4 tile_tex_size;
	float4 tile_min_point;
	float4 tile_max_point;
CBUFFER_END

TEXTURE2D_DECL( tile_sampler );

struct PInput
{
	float4 tilemap_coord : SV_POSITION;
	float2 tex_coord : TEXCOORD0;
};


float4 PackTile( PInput input ) : PIXEL_RETURN_SEMANTIC
{
	float2 pixel_coord;
	pixel_coord.x = (input.tilemap_coord.x - 0.5f) - tile_min_point.x;
	pixel_coord.y = tile_max_point.y - (input.tilemap_coord.y - 0.5f);
	//pixel_coord.y = tile_max_point.y - input.tilemap_coord.y;

	float2 tile_pixel_size = float2(tile_max_point.xy - tile_min_point.xy);
	float2 tile_norm_coord = (float2(pixel_coord.x, tile_tex_size.y - pixel_coord.y) + float2(0.5f, 0.5f)) / tile_tex_size.xy;

	if(tile_norm_coord.x < 0.0f || tile_norm_coord.y < 0.0f ||tile_norm_coord.x > 1.0f ||tile_norm_coord.y > 1.0f)
		return float4(0.0f, 0.0f, 0.0f, 0.0f);
	else
		//return lerp(float4(frac(tile_norm_coord.xy * 10.0f), 0.0f, 1.0f), SAMPLE_TEX2D(tile_sampler, SamplerLinearClamp, tile_norm_coord), 0.5f);
		return SAMPLE_TEX2D(tile_sampler, SamplerLinearClamp, tile_norm_coord);
}