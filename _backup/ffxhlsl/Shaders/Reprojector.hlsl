//PRECOMPILE ps_4_0 Reproject USE_WORLD_SPACE 0 USE_VIEW_SPACE 1
//PRECOMPILE ps_4_0 Reproject USE_WORLD_SPACE 1 USE_VIEW_SPACE 0
//PRECOMPILE ps_4_0 Reproject USE_WORLD_SPACE 1 USE_VIEW_SPACE 1
//PRECOMPILE ps_gnm Reproject USE_WORLD_SPACE 0 USE_VIEW_SPACE 1
//PRECOMPILE ps_gnm Reproject USE_WORLD_SPACE 1 USE_VIEW_SPACE 0
//PRECOMPILE ps_gnm Reproject USE_WORLD_SPACE 1 USE_VIEW_SPACE 1
//PRECOMPILE ps_vkn Reproject USE_WORLD_SPACE 0 USE_VIEW_SPACE 1
//PRECOMPILE ps_vkn Reproject USE_WORLD_SPACE 1 USE_VIEW_SPACE 0
//PRECOMPILE ps_vkn Reproject USE_WORLD_SPACE 1 USE_VIEW_SPACE 1


CBUFFER_BEGIN(creprojector) 
	int viewport_width;
	int viewport_height;

	float4x4 proj_matrix;
	float4x4 inv_proj_matrix;

	float4x4 curr_viewproj_matrix;
	float4x4 prev_viewproj_matrix;

	float4x4 curr_inv_viewproj_matrix;
	float4x4 prev_inv_viewproj_matrix;

	float4 prev_frame_to_dynamic_scale;
	float4 curr_frame_to_dynamic_scale;

	int downscale;
	int mip_level;
CBUFFER_END

TEXTURE2D_DECL( curr_depth_sampler );
TEXTURE2D_DECL( prev_depth_sampler );
TEXTURE2D_DECL( prev_data_sampler );

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


float2 GetPixelScreenSize(in int mip_level, in int downscale, float2 frame_to_dynamic_scale)
{
	return GetPixelTexSize(mip_level, downscale) / frame_to_dynamic_scale.xy;
}

float2 TexToScreenCoord(float2 tex_coord, float2 pixel_tex_size, float2 pixel_screen_size)
{
	return (tex_coord / pixel_tex_size) * pixel_screen_size;
}

float2 ScreenToTexCoord(float2 screen_coord, float2 pixel_tex_size, float2 pixel_screen_size)
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

float4 Reproject( PInput input ) : PIXEL_RETURN_SEMANTIC
{
	float2 zero_pixel_tex_size = GetPixelTexSize(0, 1);
	float2 zero_pixel_screen_size = GetPixelScreenSize(0, 1, curr_frame_to_dynamic_scale.xy);

	float zero_pixel_mult = float(pow(2, mip_level) * downscale);

	float2 pixel_tex_size = GetPixelTexSize(mip_level, downscale);
	float2 prev_pixel_screen_size = GetPixelScreenSize(mip_level, downscale, prev_frame_to_dynamic_scale);
	float2 curr_pixel_screen_size = GetPixelScreenSize(mip_level, downscale, curr_frame_to_dynamic_scale);

	float2 curr_pixel = (input.screen_coord.xy - 0.5f);

	float2 zero_screen_coord = PixelToScreenCoord(curr_pixel * zero_pixel_mult, zero_pixel_screen_size);
	//float2 zero_tex_coord = PixelToTexCoord(curr_pixel * zero_pixel_mult, zero_pixel_tex_size);
	float2 curr_tex_coord = PixelToTexCoord(curr_pixel, pixel_tex_size);
	//return SAMPLE_TEX2DLOD(prev_data_sampler, SamplerLinearClamp, float4(curr_tex_coord, 0.0f, -0.5f));

	float4 curr_depth_sample = SAMPLE_TEX2DLOD(curr_depth_sampler, SamplerLinearClamp, float4(curr_tex_coord, 0.0f, -0.5f));
	float3 curr_world_point = Unproject(zero_screen_coord.xy, curr_depth_sample.r, curr_inv_viewproj_matrix);
	float3 curr_view_point = Unproject(zero_screen_coord.xy, curr_depth_sample.r, inv_proj_matrix);

	float3 prev_screen_coord_view = Project(curr_view_point, proj_matrix);
	//float3 prev_screen_coord_view = float3(zero_screen_coord.xy, curr_depth_sample.r);
	float3 prev_screen_coord_world = Project(curr_world_point, prev_viewproj_matrix);

	float2 prev_tex_coord_view = ScreenToTexCoord(prev_screen_coord_view.xy, pixel_tex_size, prev_pixel_screen_size);
	float2 prev_tex_coord_world = ScreenToTexCoord(prev_screen_coord_world.xy, pixel_tex_size, prev_pixel_screen_size);

	float4 prev_depth_world_sample = SAMPLE_TEX2DLOD(prev_depth_sampler, SamplerLinearClamp, float4(prev_tex_coord_world, 0.0f, -0.5f));
	float4 prev_depth_view_sample = SAMPLE_TEX2DLOD(prev_depth_sampler, SamplerLinearClamp, float4(prev_tex_coord_view, 0.0f, -0.5f));

	float4 prev_data_world_sample = SAMPLE_TEX2DLOD(prev_data_sampler, SamplerLinearClamp, float4(prev_tex_coord_world, 0.0f, -0.5f));
	float4 prev_data_view_sample = SAMPLE_TEX2DLOD(prev_data_sampler, SamplerLinearClamp, float4(prev_tex_coord_view, 0.0f, -0.5f));

	//return prev_data_world_sample;
	//return prev_data_view_sample;
	#if USE_WORLD_SPACE == 1 && USE_VIEW_SPACE == 1
		return (abs(prev_depth_view_sample.r - curr_depth_sample.r) + 1e-2f) < abs(prev_depth_world_sample.r - curr_depth_sample.r) ? prev_data_view_sample : prev_data_world_sample;
	#else
		return prev_data_world_sample;
	#endif
}
