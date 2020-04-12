//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 0
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 1
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 2
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 3
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 4
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 0
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 1
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 2
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 3
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 4
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 0
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 1
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 2
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 3
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 4
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 0
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 1
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 2
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 3
//PRECOMPILE ps_4_0 ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 4
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 0
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 1
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 2
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 3
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 4
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 0
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 1
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 2
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 3
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 4
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 0
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 1
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 2
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 3
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 4
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 0
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 1
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 2
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 3
//PRECOMPILE ps_gnm ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 4
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 0
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 1
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 2
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 3
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 1 MIP_LEVEL 4
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 0
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 1
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 2
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 3
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 2 MIP_LEVEL 4
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 0
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 1
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 2
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 3
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 3 MIP_LEVEL 4
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 0
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 1
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 2
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 3
//PRECOMPILE ps_vkn ComputeScreenspaceShadows DOWNSCALE 4 MIP_LEVEL 4

#define max_lights_count 64

CBUFFER_BEGIN(cscreenspace_gi) 
	int viewport_width;
	int viewport_height;

	float4 frame_to_dynamic_scale;
	float4x4 proj_matrix;
	float4x4 inv_proj_matrix;
	float4x4 view_matrix;
	float4x4 inv_view_matrix;

	float mip_offset;

	float4 position_data[max_lights_count];
	float4 color_data[max_lights_count];
	int lights_count;
	bool use_prev_level;

	float target_channel;
CBUFFER_END

TEXTURE2D_DECL( depth_sampler );
TEXTURE2D_DECL( linear_depth_sampler );
TEXTURE2D_DECL( prev_opacity_sampler );

struct PInput
{
	float4 screen_coord : SV_POSITION;
	float2 tex_coord : TEXCOORD0;
};

float3 Project(in float3 world_point, in float4x4 proj_matrix)
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

float3 Unproject(in float2 screen_coord, in float nonlinear_depth, in float4x4 inv_proj_matrix)
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

float3 UnprojectLinear(in float2 screen_coord, in float linear_depth, in float4x4 inv_proj_matrix)
{
	float4 projected_pos;
	projected_pos.x = screen_coord.x * 2.f - 1.f;
	projected_pos.y = ( 1.f - screen_coord.y ) * 2.f - 1.f;
	projected_pos.z = 1.0f;
	projected_pos.w = 1.f;
	float4 world_pos = mul( projected_pos, inv_proj_matrix );
	world_pos /= world_pos.w;
	return normalize(world_pos.xyz) * linear_depth;
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

float rand(float2 v){
	return frac(sin(dot(v.xy, float2(12.9898, 78.233))) * 43758.5453);
}

struct Intersection
{
	float opacity;
	float blocker_dist;
};


int GetLevelStartMult(int mip_level)
{
	/*int offsets[6] = {0, 1, 10, 10, 10, 10};
	return offsets[mip_level];*/
	int level_mult = 8;
	return (1 - pow(level_mult, mip_level)) / (1 - level_mult);
	
	/*int step_mult = pow(2, mip_level);
	return (step_mult / 2);*/
}

float4 GetChannelMask(float channel_index)
{
	/*return 
		(channel_index > 2.5f) ? float4(0.0f, 0.0f, 0.0f, 1.0f) : 
		(
			(channel_index > 1.5f) ? float4(0.0f, 0.0f, 1.0f, 0.0f) : 
			(
				(channel_index > 0.5f) ? float4(0.0f, 1.0f, 0.0f, 0.0f) : 
				(
					(channel_index > -0.5f) ? float4(1.0f, 0.0f, 0.0f, 0.0f) : float4(0.0f, 0.0f, 0.0f, 0.0f)
				)
			)
		);*/
	float4 channels[4] = {float4(1.0f, 0.0f, 0.0f, 0.0f), float4(0.0f, 1.0f, 0.0f, 0.0f), float4(0.0f, 0.0f, 1.0f, 0.0f), float4(0.0f, 0.0f, 0.0f, 1.0f)};
	if(channel_index > -0.5f)
		return channels[int(channel_index + 0.5f)];
	return 0.0f;
}

Intersection GetDepthIntersectionHierarchial(in float3 view_ray_start, float3 view_ray_end, float occlusion_dist_threshold)
{
	float border_width = 0.2f;

	float opacity = 1.0f;

	float4 prev_view_point = float4(view_ray_start, 0.0f);

	bool level_used = true;
	if(MIP_LEVEL > 3)
		level_used = false;

	float2 interpolated_pixel_tex_size = GetPixelTexSize(MIP_LEVEL, 1);
	float2 interpolated_pixel_screen_size = GetPixelScreenSize(MIP_LEVEL, 1);


	float3 start_screen_coord = Project(view_ray_start.xyz, proj_matrix);
	float3 end_screen_coord = Project(view_ray_end.xyz, proj_matrix);

	float4 view_ray_start4 = float4(view_ray_start.xyz, 1.0f);
	float4 view_ray_end4 = float4(view_ray_end.xyz, 1.0f);
	view_ray_start4 /= view_ray_start4.z;
	view_ray_end4 /= view_ray_end4.z;

	float2 prev_screen_coord = start_screen_coord.xy;
	float3 prev_view_coord = view_ray_start;

	float total_screen_path = length(end_screen_coord - start_screen_coord);
	float2 screen_dir = (end_screen_coord.xy - start_screen_coord.xy) / total_screen_path;
	float4 view_dir4 = (view_ray_end4 - view_ray_start4) / total_screen_path; 

	float zero_level_path = 0.01f;


	//float start_offset = 0.0f;
	//float end_offset = min(total_screen_path, 0.05f);
	float screen_step = 0.001f * pow(2, MIP_LEVEL);

	//float screen_step = 0.004f;

	float start_offset = max(0.0f, min(total_screen_path, zero_level_path * GetLevelStartMult(max(0, MIP_LEVEL))));
	float end_offset = min(total_screen_path, zero_level_path * GetLevelStartMult(max(0, MIP_LEVEL + 1)) + screen_step);

	float density_init_mult = 0.0f;
	float inv_path = 1.0f / (end_offset - start_offset);
	float inv_occlusion_dist_threshold = 1.0f / (occlusion_dist_threshold);

	for(float screen_offset = start_offset; screen_offset < end_offset && level_used; screen_offset += screen_step)
	{
		float ratio = (screen_offset - start_offset) * inv_path;
		//step += 0.0005f;


		float2 curr_screen_coord = start_screen_coord.xy + screen_dir * screen_offset;
		float4 curr_view_coord4 = view_ray_start4 + view_dir4 * screen_offset;

		curr_view_coord4 /= curr_view_coord4.w;

		float3 curr_view_coord = curr_view_coord4.xyz;
		//float3 curr_view_coord = lerp(view_ray_start, view_ray_end, ratio);

		float view_step = length(curr_view_coord - prev_view_coord);
		float3 view_start_delta = curr_view_coord - view_ray_start;
		float3 view_end_delta = curr_view_coord - view_ray_end;
		float view_start_offset = length(curr_view_coord - view_ray_start);

		float border_fade = 0.0f;
		border_fade = max(border_fade, saturate(1.0f - curr_screen_coord.x / border_width));
		border_fade = max(border_fade, saturate(1.0f - (1.0f - curr_screen_coord.x) / border_width));
		border_fade = max(border_fade, saturate(1.0f - curr_screen_coord.y / border_width));
		border_fade = max(border_fade, saturate(1.0f - (1.0f - curr_screen_coord.y) / border_width));
		border_fade = pow(border_fade, 2.0f);

		float lod = MIP_LEVEL + mip_offset + ratio;//log(2.0f * screen_step * inv_pixel_screen_size * downscale) / log(2.0f);//log(max(step_length, 0.0f) * 1.0f + 1.0f) / log(2.0f) - 1.0f;
		//lod = log(0.0f / (screen_step * inv_pixel_screen_size * downscale) + 1) / log(2.0f);//log(max(step_length, 0.0f) * 1.0f + 1.0f) / log(2.0f) - 1.0f;
		//lod = 0.0f;//min(lod, 4.0f);

		//float3 depth_view_point = ReadViewPoint2(curr_screen_coord.xy, lod, zero_pixel_tex_size); 
		float3 linear_depth_sample = SAMPLE_TEX2DLOD( linear_depth_sampler, SamplerLinearClamp, float4(ScreenToTexCoord(curr_screen_coord, interpolated_pixel_tex_size, interpolated_pixel_screen_size), 0.0f, lod) ).xyz;
		float mean = linear_depth_sample.x;
		float variance = max(linear_depth_sample.y - mean * mean, 1e-7f);

		float ray_depth = length(curr_view_coord.xyz);

		float delta = ray_depth - mean;
		float probability = 1 - ((delta < 0.0f) ? 1.0f : (variance / (variance + delta * delta)));
		float thick_delta = delta - 100.0f;
		probability -= ((thick_delta > 0.0f) ? 1.0f : (variance / (variance + thick_delta * thick_delta)));
		probability = max(0.0f, probability);

		float density = lerp(1.0f, 0.0f, border_fade) * 1.0f * probability * view_step * density_init_mult;
		//density *= ((length(curr_view_coord.xyz - view_ray_end) > 80.0f) ? 1.0f : 0.0f);
		density /= (1.0f + 0.05f * length(view_start_delta));
		//density = lerp(0.0f, density, saturate(delta / 10.0f));
		//density = lerp(density, 0.0f, saturate((delta - 100.0f) / 1.0f));
		//density *= saturate(dot(view_end_delta, view_end_delta) * inv_occlusion_dist_threshold * inv_occlusion_dist_threshold);
		density *= pow(saturate(length(view_end_delta) * inv_occlusion_dist_threshold - 0.5f), 2.0f);
		//density *= (dot(view_end_delta, view_end_delta) * inv_occlusion_dist_threshold * inv_occlusion_dist_threshold) > 1.0f ? 1.0f : 0.0f;
		//density *= saturate(dot(view_end_delta, view_end_delta) * inv_occlusion_dist_threshold * inv_occlusion_dist_threshold);
		//density = frac(ScreenToTexCoord(curr_screen_coord, interpolated_pixel_tex_size, interpolated_pixel_screen_size).x * 10.0f) * 0.1f;
		opacity *= exp(-density);
		prev_screen_coord = curr_screen_coord;
		prev_view_coord = curr_view_coord;
		density_init_mult = 1.0f;
	}
	//opacity = 1.0f - pow(saturate(1.0f - opacity), 2.0f);
	//opacity = opacity > 0.5f ? 1.0f : 0.0f;
	float border_fade = 0.0f;
	/*border_fade = max(border_fade, saturate(1.0f - screen_point.x / border_width));
	border_fade = max(border_fade, saturate(1.0f - (1.0f - screen_point.x) / border_width));
	border_fade = max(border_fade, saturate(1.0f - screen_point.y / border_width));
	border_fade = max(border_fade, saturate(1.0f - (1.0f - screen_point.y) / border_width));
	border_fade = pow(border_fade, 2.0f);*/
	Intersection res;
	res.opacity = opacity;
	//res.opacity = frac(SAMPLE_TEX2DLOD( linear_depth_sampler, SamplerLinearClamp, float4(start_screen_coord.xy, 0.0f, 0.0f) ).x / 10.0f);
	//res.blocker_dist = count > 0 ? saturate(1.0f - count / 2.0f) * 200.0f : 0.0f;//blocker_dist;
	res.blocker_dist = 0.0f;
	return res;
}


struct OutPixel
{
	float4 shadowmap_data : PIXEL_RETURN_SEMANTIC;
};

void SwapFloat(inout float a, inout float b)
{
	float t = a;
	a = b; 
	b = t;
}
void SwapInt(inout int a, inout int b)
{
	int t = a;
	a = b; 
	b = t;
}
OutPixel ComputeScreenspaceShadows( PInput input )
{
	float zero_pixel_mult = float(pow(2, MIP_LEVEL) * DOWNSCALE);
	float2 pixel_coord = (input.screen_coord.xy - 0.5f);
	float2 zero_pixel_coord = pixel_coord * zero_pixel_mult;

	float2 zero_pixel_tex_size = GetPixelTexSize(0, 1);
	float2 zero_pixel_screen_size = GetPixelScreenSize(0, 1);
	float2 screen_coord = PixelToScreenCoord(zero_pixel_coord, zero_pixel_screen_size);
	float2 tex_coord = PixelToTexCoord(zero_pixel_coord, zero_pixel_tex_size);

	float4 depth_sample = SAMPLE_TEX2DLOD( depth_sampler, SamplerLinearClamp, float4(tex_coord, 0.0f, -0.5f) );
	float3 view_ray_start = Unproject(screen_coord, depth_sample.r, inv_proj_matrix);

	#define max_shadows_count 2
	int light_indices[max_shadows_count + 1];
	float light_weights[max_shadows_count + 1];
	light_weights[0] = 0.0;
	light_weights[1] = 0.0;
	light_weights[2] = 0.0;

	light_indices[0] = 0;
	light_indices[1] = 0;
	light_indices[2] = 0;

	int active_lights_count = 0;
	[loop]
	for(int i = 0; i < lights_count; i++)
	{
		float3 view_pos = mul(float4(position_data[i].xyz, 1.0f), view_matrix).xyz;
		float dist = length(view_ray_start - view_pos);

		float light_radius = color_data[i].a;
		float light_radius_threshold = light_radius * 1.1f;
		float small_size_mult = saturate((light_radius - 50.0f) / 30.0f);
		float weight = small_size_mult * pow(saturate(1.0f - dist / light_radius_threshold), 2.0f);

		if(weight > light_weights[0])
		{
			light_indices[0] = i;
			light_weights[0] = weight;
			active_lights_count++;
		}
		if(light_weights[0] > light_weights[1])
		{
			SwapFloat(light_weights[0], light_weights[1]);
			SwapInt(light_indices[0], light_indices[1]);
		}
		if(light_weights[1] > light_weights[2])
		{
			SwapFloat(light_weights[1], light_weights[2]);
			SwapInt(light_indices[1], light_indices[2]);
		}
	}
	active_lights_count = min(active_lights_count, max_shadows_count + 1);

	float light_amount = 1e-4f;
	float sum_weight = 1e-4f;
	float blocker_dist = 0.0f;

	[loop]
	for(int light_number = 0; light_number < min(max_shadows_count, active_lights_count); light_number++)
	{
		int light_index = light_indices[max_shadows_count - light_number];
		float weight = light_weights[max_shadows_count - light_number];

		float3 view_ray_end = mul(float4(position_data[light_index].xyz, 1.0f), view_matrix).xyz;
		float threshold = position_data[light_index].w;
		Intersection intersection = GetDepthIntersectionHierarchial(view_ray_start, view_ray_end, threshold);
		// Intersection intersection = GetDepthIntersection(view_ray_start, view_ray_end); 
		//Intersection intersection = GetRaytraceIntersectionRef(view_ray_start, view_ray_end);
		//Intersection intersection = GetRaytraceIntersectionQuadTree(view_ray_start, view_ray_end);
		float this_light_amount = intersection.opacity;

		//
		/*float2 delta = (view_ray_start - view_ray_end).xy;
		float ang = atan2(delta.y, delta.x);
		this_light_amount = frac(ang * 10.0f) > 0.5f ? 1.0f : 0.0f;*/
		//
		light_amount += this_light_amount * weight;
		//light_amount.r = this_light_amount.r;
		sum_weight += weight;
	}
	// /cgeal SpawnPermanentEffect( Metadata/Effects/Environment/Lights/Inca/firepit.ao, idle );
	// /cgeal SpawnPermanentEffect( Metadata/Monsters/Spiders/BlackDeath/BlackDeathIncursionRobotSpider.ao, idle );
	// /monster DelveSpiderPacks
	// /delvetest Mine Breach 10
	// /cgeal SetDelveLightColour(255, 255, 255, 2); id=DelveRobot
	// /adddelveenergy 10000
	float mult = 1.0f;
	[branch]
	if(active_lights_count > max_shadows_count)
	{
		mult = 1.0f - pow(saturate((light_weights[0] ) / (light_weights[1])), 2.0f);
	}
	[branch]
	if(active_lights_count == 0)
	{
		light_amount = 1.0f;
		sum_weight = 1.0f;
	}

	OutPixel res;
	float4 channel_mask = GetChannelMask(target_channel);
	res.shadowmap_data = (1.0f - channel_mask) + channel_mask * lerp(1.0f, light_amount / (sum_weight + 1e-5f), mult);
	//res.shadowmap_data.x = frac(SAMPLE_TEX2DLOD( linear_depth_sampler, SamplerLinearClamp, float4(screen_coord.xy, 0.0f, 0.0f) ).x / 10.0f);
	//res.shadowmap_data = lerp(float4(1.0f, 0.0f, 0.0f, 1.0f), float4(0.0f, 1.0f, 0.0f, 1.0f), light_amount / sum_weight);
	return res;
}