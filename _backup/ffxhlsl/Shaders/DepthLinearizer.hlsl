//PRECOMPILE ps_4_0 LinearizeDepth DOWNSCALE 1
//PRECOMPILE ps_4_0 LinearizeDepth DOWNSCALE 2
//PRECOMPILE ps_4_0 LinearizeDepth DOWNSCALE 3
//PRECOMPILE ps_4_0 LinearizeDepth DOWNSCALE 4
//PRECOMPILE ps_gnm LinearizeDepth DOWNSCALE 1
//PRECOMPILE ps_gnm LinearizeDepth DOWNSCALE 2
//PRECOMPILE ps_gnm LinearizeDepth DOWNSCALE 3
//PRECOMPILE ps_gnm LinearizeDepth DOWNSCALE 4
//PRECOMPILE ps_vkn LinearizeDepth DOWNSCALE 1
//PRECOMPILE ps_vkn LinearizeDepth DOWNSCALE 2
//PRECOMPILE ps_vkn LinearizeDepth DOWNSCALE 3
//PRECOMPILE ps_vkn LinearizeDepth DOWNSCALE 4

#pragma PSSL_target_output_format (target 0 FMT_32_GR) 

CBUFFER_BEGIN(cdepth_linearizer) 
	int viewport_width;
	int viewport_height;
	float4x4 proj_matrix;
	float4x4 inv_proj_matrix;
	float4 frame_to_dynamic_scale;
CBUFFER_END

TEXTURE2D_DECL( depth_sampler );

float3 Project(float3 world_point, float4x4 proj_matrix)
{
	float4 world_point4;
	world_point4.xyz = world_point;
	world_point4.w = 1.0f;
	float4 normalized_pos = mul(world_point4, proj_matrix);
	normalized_pos /= normalized_pos.w;
	float2 screen_point = normalized_pos.xy * 0.5f + float2(0.5f, 0.5f);
	screen_point.y = 1.0f - screen_point.y;
	return float3(screen_point.xy, normalized_pos.z);
}

float3 Unproject(float2 screen_coord, float nonlinear_depth, float4x4 inv_proj_matrix)
{
	float4 projected_pos;
	projected_pos.x = screen_coord.x * 2.f - 1.f;
	projected_pos.y = ( 1.f - screen_coord.y ) * 2.f - 1.f;
	projected_pos.z = nonlinear_depth;
	projected_pos.w = 1.f;
	float4 world_pos = mul( projected_pos, inv_proj_matrix );
	world_pos /= world_pos.w;
	return world_pos.xyz;
}

float2 GetPixelTexSize(in int mip_level, in int downscale)
{
	int mip_mult = pow(2, mip_level);
	return float2(1.0f, 1.0f) / float2(viewport_width / (mip_mult * downscale), viewport_height / (mip_mult * downscale));
}


float2 GetPixelScreenSize(in int mip_level, in int downscale)
{
	return GetPixelTexSize(mip_level, downscale) / frame_to_dynamic_scale.xy;
}

float2 TexToScreenCoord(in float2 tex_coord, in float2 pixel_tex_size, in float2 pixel_screen_size)
{
	return (tex_coord / pixel_tex_size) * pixel_screen_size;
}

float2 ScreenToTexCoord(in float2 screen_coord, in float2 pixel_tex_size, in float2 pixel_screen_size)
{
	return (screen_coord / pixel_screen_size) * pixel_tex_size;
}

float2 ScreenToPixelCoord(in float2 screen_coord, in float2 pixel_screen_size)
{
	return (screen_coord / pixel_screen_size - 0.5f);
}

float2 TexToPixelCoord(in float2 tex_coord, in float2 pixel_tex_size)
{
	return ((tex_coord.xy) / pixel_tex_size - 0.5f);
}

float2 PixelToTexCoord(in float2 pixel_coord, in float2 pixel_tex_size)
{
	return (pixel_coord + 0.5f) * pixel_tex_size;
}

float2 PixelToScreenCoord(in float2 pixel_coord, in float2 pixel_screen_size)
{
	return (pixel_coord + 0.5f) * pixel_screen_size;
}

struct PInput
{
	float4 screen_coord : SV_POSITION;
	float2 tex_coord : TEXCOORD0;
};

float4 LinearizeDepth( PInput input ) : PIXEL_RETURN_SEMANTIC
{
	int mip_level = 0;
	float2 zero_pixel_tex_size = GetPixelTexSize(0, 1);
	float2 zero_pixel_screen_size = GetPixelScreenSize(0, 1);
	int zero_pixel_mult = DOWNSCALE;

	int2 base_zero_pixel = int2(input.screen_coord.xy) * zero_pixel_mult;

	float2 avg_moments = 0.0f;
	float sum_weight = 0.0f;
	[unroll]
	for(int offset = 0; offset < DOWNSCALE * DOWNSCALE; offset++)
	{
		int x = offset % DOWNSCALE;
		int y = offset / DOWNSCALE;
		int2 offset_zero_pixel = base_zero_pixel + int2(x, y);
		float2 zero_screen_coord = PixelToScreenCoord(offset_zero_pixel, zero_pixel_screen_size);
		float2 zero_tex_coord = PixelToTexCoord(offset_zero_pixel, zero_pixel_tex_size);
		float4 depth_sample = SAMPLE_TEX2DLOD(depth_sampler, SamplerPointClamp, float4(zero_tex_coord, 0.0f, 0.0f));
		float3 view_coord = Unproject(zero_screen_coord, depth_sample.r, inv_proj_matrix);
		float dist = length(view_coord);
		avg_moments.x += dist;
		avg_moments.y += dist * dist;
		sum_weight += 1.0f;
	}
	avg_moments /= sum_weight;
	return float4(avg_moments.x, avg_moments.y, 0.0f, 1.0f);
}
