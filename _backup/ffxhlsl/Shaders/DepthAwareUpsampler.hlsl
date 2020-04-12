//PRECOMPILE ps_4_0 Upsample USE_DEPTH 0 USE_NORMAL 0
//PRECOMPILE ps_4_0 Upsample USE_DEPTH 0 USE_NORMAL 1
//PRECOMPILE ps_4_0 Upsample USE_DEPTH 1 USE_NORMAL 0
//PRECOMPILE ps_4_0 Upsample USE_DEPTH 1 USE_NORMAL 1
//PRECOMPILE ps_gnm Upsample USE_DEPTH 0 USE_NORMAL 0
//PRECOMPILE ps_gnm Upsample USE_DEPTH 0 USE_NORMAL 1
//PRECOMPILE ps_gnm Upsample USE_DEPTH 1 USE_NORMAL 0
//PRECOMPILE ps_gnm Upsample USE_DEPTH 1 USE_NORMAL 1
//PRECOMPILE ps_vkn Upsample USE_DEPTH 0 USE_NORMAL 0
//PRECOMPILE ps_vkn Upsample USE_DEPTH 0 USE_NORMAL 1
//PRECOMPILE ps_vkn Upsample USE_DEPTH 1 USE_NORMAL 0
//PRECOMPILE ps_vkn Upsample USE_DEPTH 1 USE_NORMAL 1

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
TEXTURE2D_DECL( normal_sampler );

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
	float2 tex_coord : TEXCOORD0;
};

float4 Upsample( PInput input ) : PIXEL_RETURN_SEMANTIC
{
	float2 upscaled_pixel = (input.screen_coord.xy - 0.5f);

	float2 downscaling_offset = 0.0f; //when pixel centers match (nearest filtration)
	//float2 downscaling_offset = downscale / 2 - 0.5f; //for avg filtration

	#define offsets_count 4
	float2 offsets[offsets_count];
	offsets[0] = float2( 0, 0);
	offsets[1] = float2( 1, 0);
	offsets[2] = float2( 1, 1);
	offsets[3] = float2( 0, 1);

	float2 zero_pixel_tex_size = GetPixelTexSize(0, 1);
	float2 zero_pixel_screen_size = GetPixelScreenSize(0, 1);


	float2 downscaled_pixel_tex_size = GetPixelTexSize(mip_level, downscale);
	float2 downscaled_pixel_screen_size = GetPixelScreenSize(mip_level, downscale);

	float2 upscaled_pixel_tex_size = (mip_level > 0) ? GetPixelTexSize(mip_level - 1, downscale) : zero_pixel_tex_size;
	float2 upscaled_pixel_screen_size = (mip_level > 0) ? GetPixelScreenSize(mip_level - 1, downscale) : zero_pixel_screen_size;
	float upscaled_zero_pixel_mult = (mip_level > 0) ? float(pow(2, mip_level - 1) * downscale) : 1.0f;

	int pixel_scale = (mip_level > 0) ? 2 : downscale;
	float2 downscaled_pixel = float2(int2(upscaled_pixel + 0.5f) / pixel_scale);

	float2 zero_pixel_coord = upscaled_pixel * upscaled_zero_pixel_mult;
	float2 zero_tex_pos = PixelToTexCoord(zero_pixel_coord, zero_pixel_tex_size);
	float2 zero_screen_pos = PixelToScreenCoord(zero_pixel_coord, zero_pixel_screen_size);

	float4 zero_depth_sample = SAMPLE_TEX2DLOD(depth_sampler, SamplerPointClamp, float4(zero_tex_pos, 0.0f, -0.5f));
	float3 zero_view_pos = Unproject(zero_screen_pos, zero_depth_sample.r, inv_proj_matrix).xyz;

	float4 zero_normal_sample = SAMPLE_TEX2DLOD(normal_sampler, SamplerPointClamp, float4(zero_tex_pos, 0.0f, -0.5f));
	float3 zero_normal = zero_normal_sample.rgb * 2.0f - 1.0f;

	float4 sum = 0.0f;
	float sum_weight = 1e-7f;
	for(int i = 0; i < 4; i++) 
	{
		float2 offset_downscaled_pixel = downscaled_pixel + offsets[i];

		float2 zero_offset_pixel = offset_downscaled_pixel * pixel_scale * upscaled_zero_pixel_mult;

		float2 offset_zero_screen_coord = PixelToScreenCoord(zero_offset_pixel, zero_pixel_screen_size);
		float2 offset_zero_tex_coord = PixelToTexCoord(zero_offset_pixel, zero_pixel_tex_size);

		float2 offset_downscaled_screen_coord = PixelToScreenCoord(offset_downscaled_pixel, downscaled_pixel_screen_size);
		float2 offset_downscaled_tex_coord = PixelToTexCoord(offset_downscaled_pixel, downscaled_pixel_tex_size);

		float2 ratio;
		ratio = abs(offset_downscaled_pixel * pixel_scale + downscaling_offset - upscaled_pixel) / float(pixel_scale);
		float bilinear_weight = (1.0f - ratio.x) * (1.0f - ratio.y);

		float weight = bilinear_weight;

		/*#if (USE_DEPTH == 1)
		{
			float4 depth_sample = SAMPLE_TEX2DLOD(depth_sampler, SamplerPointClamp, float4(offset_zero_tex_coord, 0.0f, -0.5f));
			float3 sample_view_pos = Unproject(offset_zero_screen_coord, depth_sample.r, inv_proj_matrix).xyz;
			weight /= (1.0 + length(sample_view_pos - upscaled_view_pos) * 100.1f);
		}
		#endif*/

		#if (USE_DEPTH == 1)
		{
			float4 depth_sample = SAMPLE_TEX2DLOD(depth_sampler, SamplerPointClamp, float4(offset_zero_tex_coord, 0.0f, -0.5f));
			weight /= (1.0 + abs(zero_depth_sample.r - depth_sample.r) * 1e4f);
		}
		#endif

		#if (USE_NORMAL == 1)
		{
			float4 normal_sample = SAMPLE_TEX2DLOD(normal_sampler, SamplerPointClamp, float4(offset_zero_tex_coord, 0.0f, -0.5f));
			float3 normal = normal_sample.rgb * 2.0f - float3(1.0f, 1.0f, 1.0f);
			//weight *= exp(-length(normal - zero_normal) * 100.0f);
			weight /= (1.0f + length(normal - zero_normal) * 100.0f);
		}
		#endif

		sum += SAMPLE_TEX2DLOD( data_sampler, SamplerPointClamp, float4(offset_downscaled_tex_coord, 0.0f, -0.5f) ) * weight;
		//sum += sample_world_pos.z * weight;
		sum_weight += weight;
	}
	return sum / sum_weight;
}
