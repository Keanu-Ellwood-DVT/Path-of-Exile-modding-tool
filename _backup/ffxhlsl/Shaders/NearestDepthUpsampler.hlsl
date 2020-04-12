//PRECOMPILE ps_4_0 NearestDepthUpsampler
//PRECOMPILE ps_gnm NearestDepthUpsampler
//PRECOMPILE ps_vkn NearestDepthUpsampler
//PRECOMPILE ps_4_0 NearestDepthUpsampler USE_DEPTH 1
//PRECOMPILE ps_gnm NearestDepthUpsampler USE_DEPTH 1
//PRECOMPILE ps_vkn NearestDepthUpsampler USE_DEPTH 1

CBUFFER_BEGIN(cdepth_upsampler) 
	int viewport_width;
	int viewport_height;
	float4x4 proj_matrix;
	float4x4 inv_proj_matrix;
	float4 frame_to_dynamic_scale;
	int downscale;
	int mip_level; //src mip level
CBUFFER_END

TEXTURE2D_DECL( data_sampler );
TEXTURE2D_DECL( depth_sampler );
TEXTURE2D_DECL( depth_downsampled_sampler );

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

float3 GetViewPoint(float2 screenspace_point, float nonlinear_depth)
{
	float4 projected_pos;
	projected_pos.x = screenspace_point.x * 2.f - 1.f;
	projected_pos.y = ( 1.f - screenspace_point.y ) * 2.f - 1.f;
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
};

const float pi = 3.141592f;

float GetDepthSimilarity(float center_depth, float4 sample_depths)
{
	float threshold = 0.001;
	float min_depth = min(min(sample_depths.x, sample_depths.y), min(sample_depths.z, sample_depths.w));
	float max_depth = max(max(sample_depths.x, sample_depths.y), max(sample_depths.z, sample_depths.w));
	return step(threshold, max_depth - min_depth);
}

float4 GetDepthDifferences(float center_depth, float4 sample_depths)
{
	return abs(sample_depths - center_depth);
}

uint GetNearestIndex(float4 depth_differences)
{
	uint best_index = 0;
	float best_diff = depth_differences[0];
	float2 best_sample = float2(0, depth_differences[0]);
	[unroll]
	for(int i = 1; i < 4; i++)
	{
		if(best_diff > depth_differences[i])
		{
			best_index = i;
			best_diff = depth_differences[i];
		}
	}
	return best_index;
/*
	float min_difference = min(min(depth_differences[0], depth_differences[1]), min(depth_differences[2], depth_differences[3]));

	if (min_difference == depth_differences[0])
		return 0;
	if (min_difference == depth_differences[1])
		return 1;
	if (min_difference == depth_differences[2])
		return 2;

	return 3; */
}

float4 NearestDepthUpsampler( PInput input ) : PIXEL_RETURN_SEMANTIC
{
	//if (input.screen_coord.x < 10.1) return 0;

	//float2 downscaling_offset = downscale / 2 - 0.5f; //for avg filtration
	float2 downscaling_offset = 0.5f;

	#define offsets_count 4
	float2 offsets[offsets_count];
	offsets[0] = float2( 0, 0);
	offsets[1] = float2( 1, 0);
	offsets[2] = float2( 1, 1);
	offsets[3] = float2( 0, 1);

	float4 sample_depths;
	float4 depth_weights;
	float4 normal_weights = float4(1.0, 1.0, 1.0, 1.0);

	//float2 downscaled_pixel = float2(int2(upscaled_pixel + 0.5f) / pixel_scale); // (e.g. 0, 0) matching pixel in downscaled texture
	
	#define SAMPLER SamplerPointClampNoBias

	int pixel_scale = 2;//max((mip_level > 0) ? 2 : downscale, 2);
	float2 upscaled_pixel = (input.screen_coord.xy - 0.5f); // (e.g. 3.0, 3.0)
	float2 downscaled_pixel = float2((int2(upscaled_pixel + 0.5f) - 1) / pixel_scale);

	//float upscaled_zero_pixel_mult = (mip_level > 0) ? float(pow(2, mip_level - 1) * downscale) : 1.0f;
	float upscaled_zero_pixel_mult = 1;
	float2 zero_pixel_coord = upscaled_pixel * upscaled_zero_pixel_mult;
	float2 zero_pixel_tex_size = GetPixelTexSize(0, downscale);
	float2 zero_tex_pos = PixelToTexCoord(zero_pixel_coord, zero_pixel_tex_size); // zero pixel center texcoord

	float4 zero_depth_sample = SAMPLE_TEX2DLOD(depth_sampler, SAMPLER, float4(zero_tex_pos, 0.0f, -0.5f));
	float2 downscaled_pixel_tex_size = GetPixelTexSize(1, downscale);

	float4 sum = 0.0f;
	float sum_weight = 1e-7f;

	float display_multiplier = 0.0;

	// Weights
	[unroll]
	for (int i = 0; i < offsets_count; i++)
	{
		float2 offset_downscaled_pixel = downscaled_pixel + offsets[i];
		float2 offset_downscaled_tex_coord = PixelToTexCoord(offset_downscaled_pixel, downscaled_pixel_tex_size);
		sample_depths[i] = SAMPLE_TEX2DLOD(depth_downsampled_sampler, SAMPLER, float4(offset_downscaled_tex_coord, 0.0f, 0));
		depth_weights[i] = 1.0 / (1e-7 + abs(zero_depth_sample - sample_depths[i]));
	}

	float depth_similarity = GetDepthSimilarity(zero_depth_sample, sample_depths);
	//return float4(depth_similarity, depth_similarity, depth_similarity, 1);

	float4 depth_differences = GetDepthDifferences(zero_depth_sample, sample_depths);
	uint nearest_index = GetNearestIndex(depth_differences);

	float2 offset_downscaled_pixel = downscaled_pixel + offsets[nearest_index];
	float2 offset_downscaled_tex_coord = PixelToTexCoord(offset_downscaled_pixel, downscaled_pixel_tex_size);
	float2 bilinear_tex_coord = PixelToTexCoord(downscaled_pixel, downscaled_pixel_tex_size) + downscaled_pixel_tex_size.xy * 0.5f;

	float4 bilinear_sample = SAMPLE_TEX2DLOD( data_sampler, SamplerLinearClampNoBias, float4(zero_tex_pos, 0.0f, 0.0f) );
	float4 nearest_depth_sample = SAMPLE_TEX2DLOD( data_sampler, SAMPLER, float4(offset_downscaled_tex_coord, 0.0f, 0.0f) );
	//return nearest_depth_sample;
	//return bilinear_sample;
	return lerp(bilinear_sample, nearest_depth_sample, depth_similarity);
}
