//PRECOMPILE ps_4_0 ApplyBlur
//PRECOMPILE ps_4_0 ApplyBlur SQUARE_BLUR 1
//PRECOMPILE ps_4_0 ApplyBlur LINEAR_BLUR 1
//PRECOMPILE ps_gnm ApplyBlur
//PRECOMPILE ps_gnm ApplyBlur SQUARE_BLUR 1
//PRECOMPILE ps_gnm ApplyBlur LINEAR_BLUR 1
//PRECOMPILE ps_vkn ApplyBlur
//PRECOMPILE ps_vkn ApplyBlur SQUARE_BLUR 1
//PRECOMPILE ps_vkn ApplyBlur LINEAR_BLUR 1

CBUFFER_BEGIN(cdepth_aware_blur) 
	int viewport_width;
	int viewport_height;
	float4x4 proj_matrix;
	float4x4 inv_proj_matrix;
	float4 frame_to_dynamic_scale;
	float4 radii;
	int mip_level;
	int downscale;
	float gamma;
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

float4 ApplyBlur( PInput input ) : PIXEL_RETURN_SEMANTIC
{
	float2 zero_pixel_tex_size = GetPixelTexSize(0, 1);
	float2 zero_pixel_screen_size = GetPixelScreenSize(0, 1);
	float zero_pixel_mult = float(pow(2, mip_level) * downscale);
	float tolerance_mult = 1.0f / float(zero_pixel_mult);

	float2 pixel_tex_size = GetPixelTexSize(mip_level, downscale);
	float2 pixel_screen_size = GetPixelScreenSize(mip_level, downscale);

	float2 center_pixel = (input.screen_coord.xy - 0.5f);
	//float2 screen_coord = PixelToScreenCoord(center_pixel, pixel_tex_size);
	float2 zero_screen_coord = PixelToScreenCoord(center_pixel * zero_pixel_mult, zero_pixel_screen_size);
	float2 zero_tex_coord = PixelToTexCoord(center_pixel * zero_pixel_mult, zero_pixel_tex_size);
	float2 tex_coord = PixelToTexCoord(center_pixel, pixel_tex_size);

	float4 center_data_sample = SAMPLE_TEX2DLOD(data_sampler, SamplerPointClamp, float4(tex_coord, 0.0f, -0.5f));
	float4 center_depth_sample = SAMPLE_TEX2DLOD(depth_sampler, SamplerPointClamp, float4(zero_tex_coord, 0.0f, -0.5f));
	float4 center_normal_sample = SAMPLE_TEX2DLOD(normal_sampler, SamplerPointClamp, float4(zero_tex_coord, 0.0f, -0.5f));

	float3 center_normal = center_normal_sample.rgb * 2.0f - float3(1.0f, 1.0f, 1.0f);
	float3 center_view_point = GetViewPoint(zero_screen_coord, center_depth_sample.r);
	float center_depth = (center_view_point.z);

	//int2 center_pixel = ScreenToPixel(screen_coord);

	//return center_data_sample;
	float4 max_data = 0.0f;
	float4 sum_data = 0.0f;
	float sum_weight = 1e-5f;
	int2 radii_int = int2(radii.xy + 0.5);
	#ifdef SQUARE_BLUR
	[loop]
	for(int offset = 0; offset < radii_int.x * radii_int.y * 4; offset++)
	#else
	float2 dir = radii_int.x > radii_int.y ? float2(1, 0) : float2(0, 1);
	int radius = max(radii_int.x, radii_int.y);
	[loop]
	for(int offset = -radius; offset <= radius; offset++)
	#endif
	{
		#ifdef SQUARE_BLUR
			float2 offset2 = float2(offset % (radii_int.x * 2) - radii_int.x, offset / (radii_int.y * 2) - radii_int.y);
		#else
			float2 offset2 = dir * offset;
		#endif
		float2 offset_pixel = center_pixel + offset2;

		float2 offset_tex_coord = PixelToTexCoord(offset_pixel, pixel_tex_size);
		float2 zero_offset_tex_coord = PixelToTexCoord(offset_pixel * zero_pixel_mult, zero_pixel_tex_size);
		float2 zero_offset_screen_coord = PixelToScreenCoord(offset_pixel * zero_pixel_mult, zero_pixel_screen_size);

		float4 data_sample = pow(SAMPLE_TEX2DLOD(data_sampler, SamplerPointClamp, float4(offset_tex_coord, 0.0f, -0.5f)), gamma);

		float weight = 1.0f;
		//weight *= saturate(1.0f - length(x, y) / radius);
		#ifdef SQUARE_BLUR
			float4 normal_sample = SAMPLE_TEX2DLOD(normal_sampler, SamplerPointClamp, float4(zero_offset_tex_coord, 0.0f, -0.5f));
			float3 normal = normal_sample.rgb * 2.0f - float3(1.0f, 1.0f, 1.0f);
			weight *= exp(-length(normal - center_normal) * 10.0f * tolerance_mult); 

			float4 depth_sample = SAMPLE_TEX2DLOD(depth_sampler, SamplerPointClamp, float4(zero_offset_tex_coord, 0.0f, -0.5f));
			//weight *= exp(-abs(depth_sample.r - center_depth_sample.r) * 100.0f * tolerance_mult);
			float3 view_point = GetViewPoint(zero_offset_screen_coord, depth_sample.r);
			float depth = (view_point.z);
			//weight *= exp(-abs(depth - center_depth) * 1.0f * tolerance_mult * 0.1f);
		#else
			float4 depth_sample = SAMPLE_TEX2DLOD(depth_sampler, SamplerPointClamp, float4(zero_offset_tex_coord, 0.0f, -0.5f));
			float3 view_point = GetViewPoint(zero_offset_screen_coord, depth_sample.r);
			float depth = (view_point.z);
			weight *= exp(-abs(depth - center_depth) * 1.0f * tolerance_mult * 1.0f);
			//weight *= 1.0f / (1.0f - abs(depth - center_depth) * 10.0f * tolerance_mult * 1.0f);
		#endif
		//weight *= exp(-abs(dot(view_point - center_view_point, center_normal)) * 0.2f);
		sum_data += data_sample * weight;
		max_data = max(max_data, data_sample * weight);
		sum_weight += weight;
	}

	//return pow(sum_data / sum_weight, 1.0f / gamma) * 1e-3f + center_data_sample;
	return pow(sum_data / sum_weight, 1.0f / gamma);

	//return center_data_sample;
}
