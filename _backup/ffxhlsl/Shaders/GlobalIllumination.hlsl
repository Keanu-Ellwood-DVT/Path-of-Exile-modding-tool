//PRECOMPILE ps_4_0 ApplyGlobalIllumination
//PRECOMPILE ps_gnm ApplyGlobalIllumination
//PRECOMPILE ps_vkn ApplyGlobalIllumination

CBUFFER_BEGIN(cscreenspace_gi) 
	int viewport_width;
	int viewport_height;
	int downscale;
	float4x4 proj_matrix;
	float4x4 inv_proj_matrix;
	float4x4 view_matrix;
	float4 frame_to_dynamic_scale;
	float curr_time;
	float indirect_light_rampup;
	float indirect_light_area;
	float ambient_occlusion_power;
	int detail_level;
CBUFFER_END

TEXTURE2D_DECL( color_sampler );
TEXTURE2D_DECL( depth_sampler );
TEXTURE2D_DECL( linear_depth_sampler );
TEXTURE2D_DECL( normal_sampler );

struct PInput
{
	float4 screen_coord : SV_POSITION;
	float2 tex_coord : TEXCOORD0;
};

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

float3 UnprojectLinear(float2 screen_coord, float linear_depth, float4x4 inv_proj_matrix)
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

float ComputeHorizonContribution(float3 eye_dir, float3 eye_tangent, float3 view_norm, float min_angle, float max_angle)
{
	return
		+0.25 * clamp(dot(eye_dir, view_norm), 0.1f, 1.0f)     * (                                  - cos(2.0 * max_angle) + cos(2.0 * min_angle))
		+0.25 * dot(eye_tangent, view_norm)                    * (2.0 * max_angle - 2.0 * min_angle - sin(2.0 * max_angle) + sin(2.0 * min_angle));
}

float rand(float2 v){
	return frac(sin(dot(v.xy, float2(12.9898, 78.233))) * 43758.5453);
}

bool BoxRayCast(float2 rayStart, float2 rayDir, float2 boxMin, float2 boxMax, out float paramMin, out float paramMax)
{
	// r.dir is unit direction vector of ray
	float eps = 0.0f;
	float2 invDir = float2(abs(rayDir.x) > eps ? 1.0f / rayDir.x : 1e7f, abs(rayDir.y) > eps ? 1.0f / rayDir.y : 1e7f);

	// lb is the corner of AABB with minimal coordinates - left bottom, rt is maximal corner
	// r.org is origin of ray
	float t1 = (boxMin.x - rayStart.x) * invDir.x;
	float t2 = (boxMax.x - rayStart.x) * invDir.x;
	float t3 = (boxMin.y - rayStart.y) * invDir.y;
	float t4 = (boxMax.y - rayStart.y) * invDir.y;

	paramMin = max(min(t1, t2), min(t3, t4));
	paramMax = min(max(t1, t2), max(t3, t4));

	return paramMin < paramMax;
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

struct AmbientLight
{
	float env_light;
	float3 indirect_light;
};

AmbientLight ComputeAmbientLight(float2 pixel_coord)
{
	/*{
		int steps_count = 10;

		float3 sum_env_light = 0.0f;
		float sum_weight = 0.0f;
		for(int x = 0; x < steps_count; x++)
		{
			for(int y = 0; y < steps_count; y++)
			{
				float weight = 1.0f / (steps_count * steps_count);
				float lod = 6.0f;
				float2 offset_screenspace_point = screenspace_point + (float2(x, y) / float(steps_count) * 200.0f - 100.0f) / float2(viewport_width, viewport_height);
				sum_weight += weight;
				sum_env_light += SAMPLE_TEX2DLOD( color_sampler, SamplerLinearClamp, float4(offset_screenspace_point, 0.0f, lod) ) * weight;
			}
		}
		AmbientLight res;
		res.env_light = 0.0f;
		res.indirect_light = sum_env_light / sum_weight;

		return res;
	}*/


	float pi = 3.141592f;


	float2 zero_pixel_mult = downscale;
	float2 zero_pixel_coord = pixel_coord * zero_pixel_mult;

	float2 zero_pixel_tex_size = GetPixelTexSize(0, 1);
	float2 zero_pixel_screen_size = GetPixelScreenSize(0, 1);

	float2 center_screen_coord = PixelToScreenCoord(zero_pixel_coord, zero_pixel_screen_size);
	float2 center_tex_coord = PixelToTexCoord(zero_pixel_coord, zero_pixel_tex_size);

	float4 depth_sample = SAMPLE_TEX2DLOD( depth_sampler, SamplerLinearClamp, float4(center_tex_coord, 0.0f, 0.0f) ).x;
	float3 base_view_point = Unproject(center_screen_coord, depth_sample.r, inv_proj_matrix);

	//4x
	float near_step_size = float(viewport_width * frame_to_dynamic_scale.x) / 300.0f;// * downscale; //in dirs
	int dirs_count = 8;

	float4 normal_sample = SAMPLE_TEX2DLOD( normal_sampler, SamplerPointClamp, float4(center_tex_coord, 0.0f, 0.0f));
	float3 world_normal = normal_sample.rgb * 2.0f - float3(1.0f, 1.0f, 1.0f);
	float3 view_normal = mul(float4(world_normal, 0.0f), view_matrix).xyz;

	float3 view_dir = normalize(base_view_point);
	/*if(dot(view_normal, view_dir) > 0.0f)
		view_normal = -view_normal;*/
	float normal_sign = sign(-dot(view_normal, view_dir));


	float sum_env_light = 0.0f;
	float3 sum_indirect_light = float3(0.0f, 0.0f, 0.0f);
	float sum_weight = 1e-5f;

	float2 time_seed = float2(0.0f, curr_time * 0.01f);

	int2 pattern_index = pixel_coord % 4;
	//int offsets[16] = {14, 9, 5, 11, 4, 13, 6, 1, 8, 15, 10, 3, 12, 2, 0, 7};
	int offsets[16] = {
		14, 5,  9,   3,
		4,  1,  12,  7,
		10, 13, 8,  15,
		6,  2,  0,  11
	};

	int offsets_sqr[16] = {
		3, 8, 1, 7,
		6, 12, 11, 14,
		5, 2, 10, 0,
		4, 13, 9, 15
	};

	int offsets_diff[16] = {
		2, 15, 0, 12,
		6, 7, 8, 10,
		14, 4, 11, 1,
		3, 9, 5, 13
	};

	int offsets_vec[16] = {
		8, 13, 3, 12,
		10, 5, 2, 1,
		14, 7, 4, 6,
		11, 9, 0, 15
	};

	int offsets_potential[16] = {
		2, 13, 1, 9,
		6, 10, 4, 14,
		3, 0, 8, 12,
		7, 11, 5, 15
	};

	int offsets_potential2[16] = {
		10, 5, 9, 6,
		14, 1, 13, 2,
		11, 7, 4, 8,
		3, 5, 12, 0
	};

	int offsets_noise_optimized[16] = {
		11, 2, 4, 14, 
		5, 0, 7, 6, 
		8, 15, 1, 9, 
		3, 13, 10, 12
	};

	int offsets_noise_optimized2[16] = {
		6, 11, 0, 13, 
		14, 12, 5, 3, 
		8, 2, 10, 4, 
		15, 9, 1, 7
	};
	
	/*float ang_seed_offset = offsets[pattern_index.x * 4 + pattern_index.y] / 16.0f;//rand(pattern_index);
	float lin_seed_offset = offsets2[(3 + pattern_index.y) * 4 + pattern_index.x] / 16.0f;*/
	/*int2 pattern_index2 = center_pixel_point % 2;
	float ang_seed_offset = ((pattern_index2.y + 1) % 2 + pattern_index2.x * 2) / 4.0f;
	float lin_seed_offset = (pattern_index2.x + pattern_index2.y * 2) / 4.0f;*/

	int ang_offset_int = offsets_noise_optimized2[pattern_index.x + pattern_index.y * 4];
	int lin_offset_int = (ang_offset_int % 4) * 4 + ang_offset_int / 4;
	float ang_seed_offset = float(ang_offset_int) / 16.0f;
	float lin_seed_offset = float(lin_offset_int) / 16.0f;
	/*float ang_seed_offset = (pattern_index.x + pattern_index.y * 4) / 16.0f;
	float lin_seed_offset = ((pattern_index.y) + pattern_index.x * 4) / 16.0f;*/


	/*float ang_seed_offset = rand(pixel_coord % interleaved_pattern_size);
	float lin_seed_offset = rand(pixel_coord % interleaved_pattern_size + int2(interleaved_pattern_size, 0));*/

	float ang_offset = ang_seed_offset * 2.0f * pi / dirs_count;
	//float max_delta_ang = downscale == 2 ? 0.5f : 1.0f;
	for(int dir_index = 0; dir_index < dirs_count; dir_index++)
	{
		float dir_lin_offset = lin_seed_offset;//rand(float2(lin_seed_offset, dir_index));
		float ang = 2.0f * pi * (float(dir_index) / float(dirs_count)) + ang_offset;
		float2 pixel_dir = float2(cos(ang), sin(ang));
		float2 tex_dir = pixel_dir * zero_pixel_tex_size * zero_pixel_mult;
		float2 screen_dir = tex_dir;

		float eps = 1e-1;
		float3 offset_view_dir = normalize(Unproject(center_screen_coord + screen_dir * eps, depth_sample.r, inv_proj_matrix));

		float3 eye_tangent = normalize(offset_view_dir - view_dir);
		float3 eye_dir = -view_dir;
		//eye_tangent = normalize(cross(cross(eye_dir, eye_tangent), eye_dir));

		float max_horizon_angle = -1e5f;
		float3 dir_normal_point = cross(-cross(eye_tangent, eye_dir), view_normal);
		float2 projected_dir_normal = float2(dot(dir_normal_point, eye_dir), dot(dir_normal_point, eye_tangent) * normal_sign);
		//projected_dir_normal = float2(0.0f, 1.0f);
		/*if(projectedDirNormal.x < 0.0)
			projectedDirNormal = -projectedDirNormal;*/
		//projected_dir_normal = float2(0.0f, 1.0f);
		projected_dir_normal.y += 1e-1f; //removes pixelated noise in normal maps due to normal intersection with view plane being parallel to marching ray
		//projected_dir_normal = float2(1.0f, 0.0f);
		float max_horizon_ratio = projected_dir_normal.x / projected_dir_normal.y;
		max_horizon_angle = atan2(1.0f, max_horizon_ratio);
		//max_horizon_angle = 3.1f;

		float dir_tangent = -1e5f;

		float dir_env_light = ComputeHorizonContribution(eye_dir, eye_tangent, view_normal, 0.0, max_horizon_angle);
		float3 dir_indirect_light = 0.0f;

		float tmin, tmax;
		BoxRayCast(center_tex_coord, tex_dir, float2(0.0, 0.0), float2(1.0f, 1.0f), tmin, tmax);
		float total_dir_path = abs(tmax);

		//r(n) = minRad * pow(2.0f * pi / dirsCount + 1, n)
		//a^b = exp(log(a)*b)=c
		int iterations_count = int(log(total_dir_path / near_step_size) / log(2.0f * pi / dirs_count + 1));
		//near_step_size = total_pixel_path / (pow(2.0f * pi / dirs_count + 1.0f, iterations_count - 1 + dir_lin_offset) + 0.5f);
		float prev_depth = 0.0f;
		//float3 prev_view_point = base_view_point;
		for(int offset = 0; offset < iterations_count; offset++)
		{
			float dir_offset_mult = near_step_size * pow(2.0f * pi / dirs_count + 1.0f, offset + dir_lin_offset) + 1 - near_step_size * 1.0f;

			float2 offset_tex_coord = center_tex_coord + tex_dir * dir_offset_mult;
			float2 offset_screen_coord = center_screen_coord + screen_dir * dir_offset_mult;

			float depth_lod_mult = 0.6f;
			float color_lod_mult = 0.8f;
			float lod_offset = -2.0f; //from blur
			/*float depth_lod_mult = 0.2f;
			float color_lod_mult = 0.2f;
			float lod_offset = 0.0f; //from blur*/
			float depth_lod = log(2.0f * pi / dirs_count * dir_offset_mult * depth_lod_mult) / log(2.0) + lod_offset;
			float color_lod = log(2.0f * pi / dirs_count * dir_offset_mult * color_lod_mult) / log(2.0) + lod_offset;
			//lod = 0.0f;
			float4 offset_linear_depth_sample = SAMPLE_TEX2DLOD( linear_depth_sampler, SamplerLinearClamp, float4(offset_tex_coord, 0.0f, depth_lod) );
			float3 offset_view_point = UnprojectLinear(offset_screen_coord, offset_linear_depth_sample.r, inv_proj_matrix);


			float3 diff = offset_view_point - base_view_point;

			//float curr_depth = -offset_linear_depth_sample.x;
			float curr_depth = dot(eye_dir, diff);
			//float depth_threshold = 300.0f;
			//curr_depth = min(prev_depth + depth_threshold, curr_depth);
			//float radius_mult = saturate((-curr_depth + prev_depth + depth_threshold) / depth_threshold);
			prev_depth = curr_depth;
			float curr_tangent = dot(eye_tangent, diff);

			float inv_tangent = 1.0f / curr_tangent;
			float horizon_ratio = curr_depth * inv_tangent;
			//horizon_point.x = min(horizon_point.x, 10.0f);
			//float sample_horizon_angle = atan2(horizon_point.y, horizon_point.x);
			//sample_horizon_angle = max(max_horizon_angle - max_delta_ang, sample_horizon_angle);


			//float mean = -curr_depth;
			float variance = offset_linear_depth_sample.y - offset_linear_depth_sample.x * offset_linear_depth_sample.x;
			/*float predicted_depth = curr_tangent * max_horizon_ratio;
			float mean = predicted_depth;

			//float delta = -predicted_depth - mean;
			float delta = curr_depth - mean;
			float probability = 1 - ((delta < 0.0f) ? 1.0f : (variance / (variance + delta * delta)));
			float thick_delta = delta - 5.0f * (curr_tangent);
			//float thick_delta = delta - 500.0f;
			probability -= 1 - ((thick_delta > 0.0f) ? 0.0f : (1 - variance / (variance + thick_delta * thick_delta)));
			probability = clamp(probability, 0.0f, 1.0f);*/
			//probability = 1.0f;
			float prev_angle = max_horizon_ratio;
			float curr_angle = horizon_ratio;

			float angle_variance = variance * inv_tangent * inv_tangent;
			float delta_angle = curr_angle - prev_angle;
			float probability = 1 - ((delta_angle < 0.0f) ? 1.0f : (angle_variance / (angle_variance + delta_angle * delta_angle)));
			float thick_delta = delta_angle - 15.0f;
			//float thick_delta = delta - 500.0f;
			probability -= 1 - ((thick_delta > 0.0f) ? 0.0f : (1 - angle_variance / (angle_variance + thick_delta * thick_delta)));
			probability = clamp(probability, 0.0f, 1.0f);
			//probability = 1.0f;

			horizon_ratio = lerp(max_horizon_ratio, horizon_ratio, probability);
			//horizon_point /= horizon_point.y;
			//float sample_horizon_angle  = atan2(horizon_point.y, horizon_point.x);
			if(horizon_ratio > max_horizon_ratio)
			//if(max_horizon_angle > sample_horizon_angle)
			{
				max_horizon_ratio = horizon_ratio;
				//float sample_horizon_angle = atan2(horizon_point.y / horizon_point.x, 1.0f);
				//float sample_horizon_angle = atan2(1.0f, horizon_point.x / horizon_point.y);
				//float sample_horizon_angle = atan2(horizon_point.x, horizon_point.y);
				float sample_horizon_angle = atan2(1.0f, horizon_ratio);
				//max_horizon_point = lerp(max_horizon_point, horizon_point, probability);
				//max_horizon_point = horizon_point;
				/*float4 normal_sample = SAMPLE_TEX2DLOD( normal_sampler, SamplerPointClamp, float4(offset_screenspace_point * frame_to_dynamic_scale.xy, 0.0f, color_lod) );
				float3 normal = (normal_sample.xyz - 0.5f) * 2.0f;*/

				//float delta_angle = sample_horizon_angle - max_horizon_angle;
				float horizon_contribution = ComputeHorizonContribution(eye_dir, eye_tangent, view_normal, sample_horizon_angle, max_horizon_angle);
				/*if(offset != 5 || dir_index != 2)
					horizon_contribution = 0;*/
				//horizon_contribution = min(horizon_contribution, 0.4f);
				//horizon_contribution *= saturate(1.0f - (-delta_angle - 3.1f) * 100.0f);
				//horizon_contribution *= saturate(1.0f + (200.0f - (prev_view_point.z - offset_view_point.z)));
				//horizon_contribution *= saturate(dot(-normal, normalize(base_view_point - offset_view_point)) * 100.0f);
				float4 color_sample = SAMPLE_TEX2DLOD( color_sampler, SamplerLinearClamp, float4(offset_tex_coord, 0.0f, color_lod/* - 0.5f*/) );

				float max_color = max(max(color_sample.r, color_sample.g), color_sample.b);
				float rampup = indirect_light_rampup;//lerp(indirect_light_rampup, 1.0f, indirect_light_area / 100.0f);*/
				//color_sample.rgb *= pow(1.0f + indirect_light_rampup, lod);
				//color_sample.rgb = log(color_sample.rgb/* * rampup*/) / rampup; 
				//color_sample.rgb = log(max(1e-3f, color_sample.rgb * rampup)) / rampup; 
				//color_sample.rgb = pow(color_sample.rgb, 1.0f / rampup); 
				//color_sample.rgb = pow(color_sample.rgb, 1.0f / indirect_light_area);
				//color_sample.rgb = exp(color_sample.rgb * indirect_light_area) / indirect_light_area;
				//color_sample.rgb *= (exp(max_color * rampup) - 1.0f) / (rampup * max_color + 1e-5f) + 1.0f;
				//color_sample.rgb *= exp(max_color * rampup * 10.0f);
				color_sample.rgb *= (1.0f + rampup);

				/*float3 gi_color = -log(1.0f - color_sample.rgb) / exposure;
				color_sample.rgb = gi_color;*/

				//color_sample *= 10.0f;
				//if(abs(horizon_point.x) < 300.0f)
				{
					dir_indirect_light += color_sample.rgb * horizon_contribution;
					dir_env_light -= horizon_contribution;
					max_horizon_angle = sample_horizon_angle;
				}
			}
			//prev_view_point = offset_view_point;
		}

		sum_env_light += dir_env_light * 2.0f;
		sum_indirect_light += dir_indirect_light * 2.0f;
		sum_weight += 1.0f;
	}

	AmbientLight res;
	res.env_light = sum_env_light / sum_weight;
	res.indirect_light = sum_indirect_light / sum_weight;

	return res;
}

struct OutPixel
{
	float4 ambient_data : PIXEL_RETURN_SEMANTIC;
};

OutPixel ApplyGlobalIllumination( PInput input )
{
	float2 pixel_coord = (input.screen_coord.xy - 0.5f);
	AmbientLight light = ComputeAmbientLight(pixel_coord);//pow(saturate(ComputeAmbientLight(tex_coord)), 1.0f);

	float indirect_intensity = max(0.0f, max(light.indirect_light.r, max(light.indirect_light.g, light.indirect_light.b))) + 1e-5f;
	light.indirect_light = light.indirect_light * pow(indirect_intensity, 1.0f / indirect_light_area) / indirect_intensity;
	//light.indirect_light *= exp(indirect_intensity * indirect_light_rampup);
	light.env_light = pow(light.env_light, ambient_occlusion_power);

	OutPixel res;
	res.ambient_data = clamp(float4(light.indirect_light, light.env_light), 0.0f, 1e5f);

	return res;

	/*float dist = ReadLinearDepth( tex_coord );
	//float dist = SAMPLE_TEX2D( depth_sampler, SamplerLinearClamp, tex_coord ).x;//length(SAMPLE_TEX2D( depth_sampler, SamplerLinearClamp, tex_coord ).rgb);
	float3 debug_color = lerp(float3(1.0f, 0.0f, 0.0f), float3(0.0f, 1.0f, 0.0f), frac(dist * 0.01f));
	return lerp(float4(debug_color, 1.0f), albedo_color, 0.5f);*/
}